import cirq

control, target = cirq.LineQubit.range(2)
circuit = cirq.Circuit(cirq.H(control), cirq.CNOT(control, target))
simulator = cirq.Simulator()
result = simulator.simulate(circuit)
circuit.append([cirq.measure(control, key='control'), cirq.measure(target, key='target')])
result = simulator.run(circuit, repetitions=1)
print(result)