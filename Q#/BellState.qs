import Std.Diagnostics.*;

operation Main() : (Result, Result) {
    use (control, target) = (Qubit(), Qubit());
    H(control);
    CNOT(control, target);
    DumpMachine();
    return (MResetZ(control), MResetZ(target));
}