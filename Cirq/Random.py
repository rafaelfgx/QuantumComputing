import cirq
import math

max = 10
num_qubits = math.ceil(math.log2(max))
qubits = cirq.LineQubit.range(num_qubits)
circuit = cirq.Circuit(cirq.H.on_each(*qubits), cirq.measure(*qubits, key="r"))
simulator = cirq.Simulator()
result = simulator.run(circuit)
random_number = int("".join(map(str, result.measurements["r"][0])), 2) % max
print(random_number)