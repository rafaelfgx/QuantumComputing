from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister, transpile
from qiskit.circuit.library import QFTGate
from qiskit.circuit import Gate
from qiskit_aer import AerSimulator
import numpy as np
import random
import math
from fractions import Fraction

def is_prime(n):
    if n < 4:
        return n > 1
    for i in range(2, int(math.sqrt(n)) + 1):
        if n % i == 0:
            return False
    return True

def continued_fraction_period(measured, n_count, a, N):
    phase = measured / (2 ** n_count)
    frac = Fraction(phase).limit_denominator(N)
    r = frac.denominator

    if pow(a, r, N) == 1:
        return r
    return None

def modular_multiplication_unitary(a, power, N, n_qubits):
    dimension = 2 ** n_qubits
    U = np.zeros((dimension, dimension), dtype=complex)

    for x in range(dimension):
        if x < N:
            y = (pow(a, power, N) * x) % N
            U[y, x] = 1
        else:
            U[x, x] = 1

    return Gate(name=f"{a}^{power} mod {N}", num_qubits=n_qubits, params=[]).definition_from_matrix(U)

def modular_exponentiation_gate(a, power, N, n_qubits):
    dimension = 2 ** n_qubits
    U = np.zeros((dimension, dimension), dtype=complex)

    multiplier = pow(a, power, N)

    for x in range(dimension):
        if x < N:
            y = (multiplier * x) % N
            U[y, x] = 1
        else:
            U[x, x] = 1

    from qiskit.circuit.library import UnitaryGate
    return UnitaryGate(U, label=f"{a}^{power} mod {N}")


def quantum_order_finding(a, N):
    n_count = 2 * math.ceil(math.log2(N))
    n_work = math.ceil(math.log2(N))

    counting = QuantumRegister(n_count, "count")
    work = QuantumRegister(n_work, "work")
    classical = ClassicalRegister(n_count, "c")

    qc = QuantumCircuit(counting, work, classical)

    qc.x(work[0])
    qc.h(counting)

    for q in range(n_count):
        power = 2 ** q
        gate = modular_exponentiation_gate(a, power, N, n_work)
        qc.append(gate.control(), [counting[q]] + work[:])

    qc.append(QFTGate(n_count).inverse(), counting)
    qc.measure(counting, classical)

    simulator = AerSimulator()
    compiled = transpile(qc, simulator)
    result = simulator.run(compiled, shots=1).result()
    counts = result.get_counts()

    measured = int(next(iter(counts)), 2)
    return continued_fraction_period(measured, n_count, a, N)


def shor(N):
    if is_prime(N):
        print("The number is prime.")
        return None

    while True:
        a = random.randint(2, N - 2)
        g = math.gcd(a, N)

        if g > 1:
            print("Trivial factor found:", g)
            return g, N // g

        r = quantum_order_finding(a, N)

        if r is None or r % 2 != 0:
            continue

        x = pow(a, r // 2, N)

        if x == N - 1:
            continue

        p = math.gcd(x - 1, N)
        q = math.gcd(x + 1, N)

        if p > 1 and q > 1:
            return p, q


if __name__ == "__main__":
    number = 15
    print(f"Factors of {number}:", shor(number))
