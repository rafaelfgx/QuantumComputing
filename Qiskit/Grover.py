from qiskit import QuantumCircuit, transpile
from qiskit.circuit.library import PhaseOracleGate, grover_operator
from qiskit_aer import AerSimulator
import numpy as np

# Define the logical boolean expression we want the quantum computer to solve
expression = "A & B & ~C & D"

# Create the Oracle: a quantum gate that "marks" the solution by flipping its phase
oracle = PhaseOracleGate(expression)

# Create the Grover operator, which combines the oracle with the diffusion (amplification) logic
grover = grover_operator(oracle)

# Initialize a quantum circuit with the number of qubits required by the oracle
qc = QuantumCircuit(oracle.num_qubits)

# Apply Hadamard gates to all qubits to create a uniform superposition of all possible states
qc.h(range(oracle.num_qubits))

# Calculate the mathematically optimal number of iterations to maximize the probability of success
iterations = int(np.floor(np.pi / 4 * np.sqrt(2**oracle.num_qubits)))

# Loop to append the Grover operator to the circuit for the calculated number of times
for _ in range(iterations):
    qc.append(grover, range(oracle.num_qubits))

# Add measurement gates to collapse the quantum state into classical bits (0s and 1s)
qc.measure_all()

# Set the backend to the AerSimulator for local high-performance simulation
simulator = AerSimulator()

# Transpile the circuit to optimize it for the specific backend and chosen optimization level
qc_optimized = transpile(qc, simulator, optimization_level=3)

# Run the circuit 1024 times (shots) to gather statistical data on the results
result = simulator.run(qc_optimized, shots=1024).result()

# Retrieve the counts dictionary showing how many times each outcome was measured
counts = result.get_counts()

# Find the most frequent result, reverse it, and print it
print(f"Expression: {expression} Result: {list(max(counts, key=counts.get)[::-1])}")