import Std.Convert.*;
import Std.Diagnostics.*;
import Std.Random.*;
import Std.Math.*;
import Std.Arithmetic.*;
import Std.Arrays.*;

operation Main() : (Int, Int) {
    let number = 15;
    let (factor1, factor2) = FactorSemiprimeInteger(number);
    Message($"Found factorization {number} = {factor1} * {factor2}");
    return (factor1, factor2);
}

operation FactorSemiprimeInteger(number : Int) : (Int, Int) {
    if number % 2 == 0 {
        Message("An even number has been given; 2 is a factor.");
        return (number / 2, 2);
    }

    mutable foundFactors = false;
    mutable factors = (1, 1);
    mutable attempt = 1;

    repeat {
        Message($"*** Factorizing {number}, attempt {attempt}.");
        let generator = DrawRandomInt(2, number - 1);

        if GreatestCommonDivisorI(generator, number) == 1 {
            Message($"Estimating period of {generator}.");
            let period = EstimatePeriod(generator, number);
            (foundFactors, factors) = MaybeFactorsFromPeriod(number, generator, period);
        } else {
            let gcd = GreatestCommonDivisorI(number, generator);
            Message($"We have guessed a divisor {gcd} by accident. " + "No quantum computation was done.");
            foundFactors = true;
            factors = (gcd, number / gcd);
        }
        attempt = attempt + 1;
        if (attempt > 100) {
            fail "Failed to find factors: too many attempts!";
        }
    } until foundFactors
    fixup {
        Message("The estimated period did not yield a valid factor. " + "Trying again.");
    }

    return factors;
}

function MaybeFactorsFromPeriod(modulus : Int, generator : Int, period : Int) : (Bool, (Int, Int)) {
    if (period > 1) and (period % 2 == 0) {
        let halfPower = ExpModI(generator, period / 2, modulus);

        if halfPower != modulus - 1 {
            let factor = MaxI(GreatestCommonDivisorI(halfPower - 1, modulus), GreatestCommonDivisorI(halfPower + 1, modulus));

            if (factor != 1) and (factor != modulus) {
                Message($"Found factor={factor}");
                return (true, (factor, modulus / factor));
            }
        }

        Message($"Found trivial factors.");
        return (false, (1, 1));
    } else {
        Message($"Estimated period {period} was odd, trying again.");
        return (false, (1, 1));
    }
}

function PeriodFromFrequency(modulus : Int, frequencyEstimate : Int, bitsPrecision : Int, currentPeriod : Int) : Int {
    let (_, candidatePeriod) = ContinuedFractionConvergentI((frequencyEstimate, 2^bitsPrecision), modulus);
    let candidatePeriodAbs = AbsI(candidatePeriod);
    let period = (currentPeriod * candidatePeriodAbs) / GreatestCommonDivisorI(currentPeriod, candidatePeriodAbs);
    Message($"Found period candidate={candidatePeriodAbs}, accumulated period={period}");
    return period;
}

operation EstimatePeriod(generator : Int, modulus : Int) : Int {
    Fact(GreatestCommonDivisorI(generator, modulus) == 1, "`generator` and `modulus` must be co-prime");
    let bitsize = BitSizeI(modulus);
    let bitsPrecision = 2 * bitsize + 1;
    mutable period = 1;

    for _ in 1..8 {
        if ExpModI(generator, period, modulus) == 1 {
            Message($"Confirmed period={period}");
            return period;
        }

        let frequencyEstimate = EstimateFrequency(generator, modulus, bitsize);

        if frequencyEstimate != 0 {
            set period = PeriodFromFrequency(modulus, frequencyEstimate, bitsPrecision, period);
        } else {
            Message("The estimated frequency was 0, trying again.");
        }
    }

    if ExpModI(generator, period, modulus) == 1 {
        Message($"Confirmed period={period}");
        return period;
    }

    Message("Failed to confirm the period after repeated estimates.");
    return 1;
}

operation EstimateFrequency(generator : Int, modulus : Int, bitsize : Int) : Int {
    mutable frequencyEstimate = 0;
    let bitsPrecision = 2 * bitsize + 1;
    Message($"Estimating frequency with bitsPrecision={bitsPrecision}.");
    use eigenstateRegister = Qubit[bitsize];
    ApplyXorInPlace(1, eigenstateRegister);
    use c = Qubit();

    for idx in bitsPrecision - 1..-1..0 {
        H(c);
        Controlled ApplyOrderFindingOracle([c], (generator, modulus, 1 <<< idx, eigenstateRegister));
        R1Frac(frequencyEstimate, bitsPrecision - 1 - idx, c);
        H(c);
        if M(c) == One {
            X(c);
            frequencyEstimate += 1 <<< (bitsPrecision - 1 - idx);
        }
    }

    ResetAll(eigenstateRegister);
    Message($"Estimated frequency={frequencyEstimate}");
    return frequencyEstimate;
}

internal operation ApplyOrderFindingOracle(generator : Int, modulus : Int, power : Int, target : Qubit[]) : Unit is Adj + Ctl {
    ModularMultiplyByConstant(modulus, ExpModI(generator, power, modulus), target);
}

internal operation ModularMultiplyByConstant(modulus : Int, c : Int, y : Qubit[]) : Unit is Adj + Ctl {
    use qs = Qubit[Length(y)];

    for idx in IndexRange(y) {
        let shiftedC = (c <<< idx) % modulus;
        Controlled ModularAddConstant([y[idx]], (modulus, shiftedC, qs));
    }

    for idx in IndexRange(y) {
        SWAP(y[idx], qs[idx]);
    }

    let invC = InverseModI(c, modulus);

    for idx in IndexRange(y) {
        let shiftedC = (invC <<< idx) % modulus;
        Controlled ModularAddConstant([y[idx]], (modulus, modulus - shiftedC, qs));
    }
}

internal operation ModularAddConstant(modulus : Int, c : Int, y : Qubit[]) : Unit is Adj + Ctl {
    body (...) {
        Controlled ModularAddConstant([], (modulus, c, y));
    }

    controlled (ctrls, ...) {
        if Length(ctrls) >= 2 {
            use control = Qubit();
            within {
                Controlled X(ctrls, control);
            } apply {
                Controlled ModularAddConstant([control], (modulus, c, y));
            }
        } else {
            use carry = Qubit();
            Controlled IncByI(ctrls, (c, y + [carry]));
            Controlled Adjoint IncByI(ctrls, (modulus, y + [carry]));
            Controlled IncByI([carry], (modulus, y));
            Controlled ApplyIfLessOrEqualL(ctrls, (X, IntAsBigInt(c), y, carry));
        }
    }
}