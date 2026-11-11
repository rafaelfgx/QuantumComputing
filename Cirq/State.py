import cirq

qubit = cirq.LineQubit(0)
circuit = cirq.Circuit()
simulator = cirq.Simulator()
print(simulator.simulate(circuit))
circuit.append(cirq.H(qubit))
print(simulator.simulate(circuit))
circuit.append(cirq.measure(qubit))
result = simulator.run(circuit)
print(result)
circuit.append(cirq.reset(qubit))
print(simulator.simulate(circuit))