import Std.Arrays.*;
import Std.Convert.*;
import Std.Diagnostics.*;
import Std.Math.*;
import Std.Measurement.*;

operation Main() : Int {
    let number = 1000;
    let nQubits = 10;
    let nPossibilities = 2^nQubits;
    let results = Grover(nQubits, number);
    let numberResult = ResultArrayAsInt(results);
    Message($"Number: {number} Result: {numberResult} Iterations: {Iterations(nQubits)} Possibilities: {nPossibilities}");
    return numberResult;
}

operation Grover(nQubits : Int, number : Int) : Result[] {
    use qubits = Qubit[nQubits];
    Superposition(qubits);

    for _ in 1..Iterations(nQubits) {
        Oracle(qubits, number);
        DiffusionOperator(qubits);
    }

    return MResetEachZ(qubits);
}

function Iterations(nQubits : Int) : Int {
    return Round(0.25 * PI() / (ArcSin(1. / Sqrt(2.0^IntAsDouble(nQubits)))) - 0.5);
}

operation Oracle(qubits : Qubit[], number : Int) : Unit is Adj {
    let length = Length(qubits);
    let bits = IntAsBoolArray(number, length);

    within {
        for i in 0..length - 1 {
            if not bits[i] {
                X(qubits[i]);
            }
        }
    } apply {
        Controlled Z(Most(qubits), Tail(qubits));
    }
}

operation Superposition(qubits : Qubit[]) : Unit is Adj + Ctl {
    ApplyToEachCA(H, qubits);
}

operation DiffusionOperator(qubits : Qubit[]) : Unit is Adj {
    within {
        Adjoint Superposition(qubits);
        ApplyToEachCA(X, qubits);
    } apply {
        Controlled Z(Most(qubits), Tail(qubits));
    }
}