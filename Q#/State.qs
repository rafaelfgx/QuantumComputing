import Std.Diagnostics.*;

operation Main() : Result {
    use qubit = Qubit();
    DumpMachine();
    H(qubit);
    DumpMachine();
    let bit = M(qubit);
    DumpMachine();
    Reset(qubit);
    DumpMachine();
    return bit;
}