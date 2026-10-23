"""
================================================================================
NeuroStack-3D: Biomimetic Spiking Column Numerical Simulator
================================================================================
Simulates:
  - Presynaptic Poisson Spike Trains (DVS Retinomorphic input @ Tier 0)
  - 1S1R Memristive Crossbar Synaptic Weight Integration (Tier 1)
  - Subthreshold Leaky Integrate-and-Fire (LIF) Soma Dynamics (Tier 2)
  - Asynchronous Output Spike Raster (3D-AER Packet Routing @ Tier 3)
================================================================================
"""

import math
import random
import csv
import sys

def run_simulation(duration_ms=100.0, dt_ms=0.1):
    print("=" * 70)
    print("NeuroStack-3D: Cortical Column Transient Neuromorphic Simulation")
    print("=" * 70)
    
    # --------------------------------------------------------------------------
    # Circuit & Biophysical Parameters
    # --------------------------------------------------------------------------
    num_inputs = 16          # 16 afferent wordlines from DVS Sensor
    input_rate_hz = 60.0     # Average firing frequency of DVS pixels
    
    # Synaptic Crossbar Parameters (1S1R HfOx / OTS)
    # Conductance G in micro-Siemens (uS)
    G_min = 15.0             # High Resistance State (HRS)
    G_max = 180.0            # Low Resistance State (LRS)
    
    # Initialize random synaptic conductance distribution
    synaptic_weights = [random.uniform(G_min, G_max) for _ in range(num_inputs)]
    
    # Subthreshold LIF Soma Parameters (Tier 2)
    C_mem_pF = 1.2           # Membrane Capacitance (1.2 pF)
    R_leak_MOhm = 45.0       # Subthreshold leak resistance (45 MOhm)
    tau_leak = (R_leak_MOhm * 1e6) * (C_mem_pF * 1e-12) * 1000.0 # Time constant ~ 54 ms
    V_rest = 0.0             # Resting potential (0.0 V)
    V_th = 0.55              # Firing threshold (550 mV)
    V_reset = 0.05           # Post-firing reset potential (50 mV)
    t_refractory_ms = 2.0    # Absolute refractory period
    
    V_spike_amp = 1.0        # Presynaptic spike voltage pulse amplitude (1.0 V)
    t_spike_width_ms = 0.5   # Spike pulse duration
    
    # --------------------------------------------------------------------------
    # Simulation Loop
    # --------------------------------------------------------------------------
    total_steps = int(duration_ms / dt_ms)
    time_points = []
    v_mem_points = []
    spike_events = []
    
    v_mem = V_rest
    refractory_countdown = 0.0
    post_spike_count = 0
    total_pre_spikes = 0
    
    # Generate presynaptic Poisson spike events
    pre_spikes = {i: [] for i in range(num_inputs)}
    for i in range(num_inputs):
        prob = (input_rate_hz * (dt_ms / 1000.0))
        for step in range(total_steps):
            if random.random() < prob:
                pre_spikes[i].append(step)
                total_pre_spikes += 1

    print(f"[*] Configuration: {num_inputs} Presynaptic Synapses -> 1 LIF Soma")
    print(f"[*] Input Event Count: {total_pre_spikes} spikes generated across {duration_ms} ms")
    print(f"[*] Simulating time step dt = {dt_ms} ms (Total {total_steps} steps)...")

    log_data = []

    for step in range(total_steps):
        t = step * dt_ms
        time_points.append(t)
        
        # Calculate instantaneous synaptic current: I_syn = sum(G_i * V_pre)
        i_syn_uA = 0.0
        for i in range(num_inputs):
            # Check if synapse i has an active pulse
            for spk_step in pre_spikes[i]:
                pulse_age = (step - spk_step) * dt_ms
                if 0.0 <= pulse_age <= t_spike_width_ms:
                    # Conductance (uS) * Voltage (V) = Current (uA)
                    i_syn_uA += (synaptic_weights[i] * 1e-6) * V_spike_amp * 1e6
                    break
        
        # Update membrane potential
        if refractory_countdown > 0.0:
            refractory_countdown -= dt_ms
            v_mem = V_reset
            fired = False
        else:
            # dV/dt = - (V - V_rest)/tau + (I_syn / C_mem)
            dv_dt = -(v_mem - V_rest) / tau_leak + (i_syn_uA * 1e-6) / (C_mem_pF * 1e-12) * 1e-3
            v_mem += dv_dt * dt_ms
            
            # Threshold detection
            if v_mem >= V_th:
                fired = True
                post_spike_count += 1
                spike_events.append((t, v_mem))
                v_mem = 0.90 # Spike peak visually
                refractory_countdown = t_refractory_ms
            else:
                fired = False

        v_mem_points.append(v_mem)
        log_data.append((t, v_mem, i_syn_uA, 1 if fired else 0))

    # --------------------------------------------------------------------------
    # Output Metrics & ASCII Plot
    # --------------------------------------------------------------------------
    print(f"[+] Simulation Completed.")
    print(f"[+] Output Spikes Emitted (Tier 3 Axon Router): {post_spike_count} spikes")
    if duration_ms > 0:
        print(f"[+] Post-synaptic Firing Rate: {(post_spike_count / (duration_ms / 1000.0)):.1f} Hz")
    
    # Save CSV
    csv_file = "neurostack_simulation_results.csv"
    with open(csv_file, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["Time_ms", "V_mem_V", "I_syn_uA", "Spike_Fired"])
        writer.writerows(log_data)
    print(f"[+] Full telemetry exported to '{csv_file}'")

    # Render ASCII Plot of Membrane Potential (First 40 ms)
    print("\n" + "=" * 70)
    print("Membrane Potential V_mem(t) Waveform Trace (0 to 40 ms)")
    print("=" * 70)
    display_steps = min(len(time_points), int(40.0 / dt_ms))
    subsample = max(1, display_steps // 60)
    
    rows = 12
    v_max_plot = 1.0
    v_min_plot = 0.0
    
    grid = [[" " for _ in range(display_steps // subsample)] for _ in range(rows)]
    
    for col_idx, step_idx in enumerate(range(0, display_steps, subsample)):
        v = v_mem_points[step_idx]
        row_idx = int((v - v_min_plot) / (v_max_plot - v_min_plot) * (rows - 1))
        row_idx = max(0, min(rows - 1, row_idx))
        grid[rows - 1 - row_idx][col_idx] = "*" if v < V_th else "^"

    for r in range(rows):
        v_level = v_max_plot - r * (v_max_plot - v_min_plot) / (rows - 1)
        line = "".join(grid[r])
        print(f"{v_level:4.2f} V | {line}")
    print("       +" + "-" * (display_steps // subsample))
    print(" Time  | 0ms" + " " * ((display_steps // subsample) - 10) + "40ms")
    print(" Legend: '*' = Analog Integration, '^' = Axonal Action Potential Fired\n")

if __name__ == "__main__":
    run_simulation()
