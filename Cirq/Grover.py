import cirq
import math


def oracle(qubits, target):
    operations = []
    for index, qubit in enumerate(qubits):
        if ((target >> index) & 1) == 0:
            operations.append(cirq.X(qubit))

    operations.append(cirq.Z(qubits[-1]).controlled_by(*qubits[:-1]))

    for index, qubit in enumerate(qubits):
        if ((target >> index) & 1) == 0:
            operations.append(cirq.X(qubit))

    return operations


def diffuser(qubits):
    return [
        cirq.H.on_each(*qubits),
        cirq.X.on_each(*qubits),
        cirq.Z(qubits[-1]).controlled_by(*qubits[:-1]),
        cirq.X.on_each(*qubits),
        cirq.H.on_each(*qubits),
    ]


def grover_iteration(qubits, target):
    return oracle(qubits, target) + diffuser(qubits)


def main():
    target = 10
    quantity_qubits = 5
    search_space_size = 1 << quantity_qubits

    if not 0 <= target < search_space_size:
        raise ValueError(f"target must be between 0 and {search_space_size - 1}")

    qubits = cirq.LineQubit.range(quantity_qubits)
    circuit = cirq.Circuit(cirq.H.on_each(*qubits))

    iterations = max(1, round((math.pi / 4) * math.sqrt(search_space_size)))

    for _ in range(iterations):
        circuit.append(grover_iteration(qubits, target))

    circuit.append(cirq.measure(*qubits, key="result"))

    simulator = cirq.Simulator()
    result = simulator.run(circuit, repetitions=1)
    measurement = result.measurements["result"][0]
    number_result = sum(bit << index for index, bit in enumerate(measurement))

    print(f"Number: {target} Result: {number_result} Iterations: {iterations} Possibilities: {search_space_size}")


if __name__ == "__main__":
    main()