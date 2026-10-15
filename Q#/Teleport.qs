import Std.Diagnostics.*;
import Std.Intrinsic.*;
import Std.Measurement.*;


operation Main() : Result[] {
    let stateInitializerBasisTuples = [
        ("|0〉", I, PauliZ),
        ("|1〉", X, PauliZ),
        ("|+〉", SetToPlus, PauliX),
        ("|-〉", SetToMinus, PauliX)
    ];

    mutable results = [];
    for (state, initializer, basis) in stateInitializerBasisTuples {
        use (message, target) = (Qubit(), Qubit());

        initializer(message);
        Message($"Teleporting state {state}");
        DumpRegister([message]);
        Teleport(message, target);
        Message($"Received state {state}");
        DumpRegister([target]);
        let result = Measure([basis], [target]);
        results += [result];
        ResetAll([message, target]);
    }

    return results;
}

operation Teleport(message : Qubit, target : Qubit) : Unit {
    use auxiliary = Qubit();
    H(auxiliary);
    CNOT(auxiliary, target);
    CNOT(message, auxiliary);
    H(message);

    if M(auxiliary) == One {
        X(target);
    }

    if M(message) == One {
        Z(target);
    }

    Reset(auxiliary);
}

operation SetToPlus(qubit : Qubit) : Unit is Adj + Ctl {
    H(qubit);
}

operation SetToMinus(qubit : Qubit) : Unit is Adj + Ctl {
    X(qubit);
    H(qubit);
}