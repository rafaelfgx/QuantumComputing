import cirq
import math
import fractions
import numpy as np

def build_controlled_modular_exponentiation_circuit(base, exponent, modulus, control_qubit, target_qubits):
    gates = []
    for i in range(exponent):
        a_power = pow(base, 2**i, modulus)
        n = len(target_qubits)
        dim = 2**n
        matrix = np.eye(dim, dtype=complex)
        
        for j in range(dim):
            matrix[(j * a_power) % modulus, j] = 1
            matrix[j, j] = 0
        
        controlled_gate = cirq.MatrixGate(matrix).controlled_by(control_qubit)
        gates.append(controlled_gate.on(control_qubit, *target_qubits))
    
    return gates

def find_order_classical(base, modulus, max_attempts=1000):
    for r in range(1, max_attempts):
        if pow(base, r, modulus) == 1:
            return r
    return None

def shor(base, modulus):
    order = find_order_classical(base, modulus)
    if order is None or order % 2 != 0:
        return None, None
    
    n_bits = modulus.bit_length()
    n_control_qubits = 2 * n_bits
    counting_qubits = cirq.LineQubit.range(n_control_qubits)
    work_qubits = cirq.LineQubit.range(n_control_qubits, n_control_qubits + n_bits)
    
    circuit = cirq.Circuit()
    
    circuit.append(cirq.H.on_each(*counting_qubits))
    circuit.append(cirq.X(work_qubits[-1]))
    
    for i in range(n_control_qubits):
        pow(2, i, order)
        controlled_ops = build_controlled_modular_exponentiation_circuit(base, 1, modulus, counting_qubits[i], work_qubits)
        circuit.append(controlled_ops)
    
    circuit.append(cirq.qft(*counting_qubits, inverse=True))
    circuit.append(cirq.measure(*counting_qubits, key='m'))
    
    return circuit, n_control_qubits

def extract_period_from_measurement(measured_bits, n_control_qubits, modulus):
    measured_int = 0
    for i, bit in enumerate(measured_bits):
        measured_int = (measured_int << 1) | int(bit)
    
    if measured_int == 0:
        return None
    
    phase = measured_int / (2**n_control_qubits)
    fraction = fractions.Fraction(phase).limit_denominator(modulus)
    
    return fraction.denominator if fraction.denominator != 0 else None

def find_factors(number):
    if number % 2 == 0:
        return 2, number // 2
    
    for i in range(3, int(math.sqrt(number)) + 1, 2):
        if number % i == 0:
            return i, number // i

    simulator = cirq.Simulator()
    attempts = 0
    max_attempts = 100

    while attempts < max_attempts:
        attempts += 1
        
        base = np.random.randint(2, number)
        gcd_value = math.gcd(base, number)
        
        if 1 < gcd_value < number:
            return gcd_value, number // gcd_value
        
        if gcd_value != 1:
            continue
        
        order = find_order_classical(base, number, max_attempts=1000)
        
        if order is None or order % 2 != 0:
            continue
        
        half_period_pow = pow(base, order // 2, number)
        
        if half_period_pow == number - 1 or half_period_pow == 1:
            continue
        
        factor1 = math.gcd(half_period_pow - 1, number)
        factor2 = math.gcd(half_period_pow + 1, number)
        
        if factor1 > 1 and factor1 < number:
            return factor1, number // factor1
        
        if factor2 > 1 and factor2 < number:
            return factor2, number // factor2
    
    return None, None

if __name__ == "__main__":
    number = 15
    factor1, factor2 = find_factors(number)
    
    if factor1 is not None and factor2 is not None:
        print(f"Number: {number} | Factors: {factor1} and {factor2}")
        print(f"Verification: {factor1} × {factor2} = {factor1 * factor2}")
    else:
        print(f"Failed to factorize {number}")