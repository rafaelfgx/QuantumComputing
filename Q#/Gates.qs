import Std.Canon.*;
import Std.Intrinsic.*;
import Std.Measurement.MResetEachZ;

operation Main() : Result[] {
    use qubits = Qubit[10];

    // Pauli and Clifford Gates
    X(qubits[0]); // Pauli-X: Inverts the bit (|0⟩ ↔ |1⟩)
    Y(qubits[1]); // Pauli-Y: Inverts the bit and adds a complex phase (|0⟩ ↔ i|1⟩, |1⟩ ↔ -i|0⟩)
    Z(qubits[2]); // Pauli-Z: Inverts the phase of state |1⟩ (|0⟩ → |0⟩, |1⟩ → -|1⟩)
    H(qubits[3]); // Hadamard: Creates superposition (|0⟩ → |+⟩, |1⟩ → |-⟩)
    S(qubits[4]); // S: Shifts phase by π/2 on the Z axis
    T(qubits[5]); // T: Shifts phase by π/4 on the Z axis

    // Rotation Gates
    Rx(1.57, qubits[6]); // Rotation around X axis
    Ry(0.5, qubits[7]);  // Rotation around Y axis
    Rz(3.14, qubits[8]); // Rotation around Z axis

    // Entangling Gates
    CNOT(qubits[0], qubits[1]); // Controlled-NOT: Applies the X gate to the target if the control is |1⟩
    CY(qubits[1], qubits[2]);   // Controlled-Y: Applies the Y gate to the target if the control is |1⟩
    CZ(qubits[2], qubits[3]);   // Controlled-Z: Applies the Z gate to the target if the control is |1⟩
    SWAP(qubits[4], qubits[5]); // SWAP: Exchanges the states of the two qubits

    return MResetEachZ(qubits);
}