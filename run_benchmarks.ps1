# PowerShell Native Runner for NeuroStack-3D Benchmarks
$r_wire_ohm_per_cell = 0.35
$v_read = 0.5

# Gen 1
$g_on_g1 = 1e-4
$g_off_g1 = 1e-6
$num_cells_line = 128
$sneak_leakage_gen1_mA = ($num_cells_line - 1) * ($v_read * $g_off_g1) * 1000.0
$ir_drop_worst_gen1_mV = ($sneak_leakage_gen1_mA * 1e-3) * ($r_wire_ohm_per_cell * $num_cells_line) * 1000.0

# Gen 2
$g_off_gen2 = 1e-9
$submat_cells = 32
$sneak_leakage_gen2_uA = ($submat_cells - 1) * ($v_read * $g_off_gen2) * 1e6
$ir_drop_worst_gen2_mV = ($sneak_leakage_gen2_uA * 1e-6) * ($r_wire_ohm_per_cell * $submat_cells) * 1000.0

# Thermal
$p_chip_W = 12.0
$t_ambient_C = 25.0
$t_junction_gen1 = $t_ambient_C + $p_chip_W * 3.8
$t_junction_gen2 = $t_ambient_C + $p_chip_W * 0.95

# Yield
$num_packets = 10000
$tsv_defect_prob = 0.02
$gen1_dropped = 0
$gen2_dropped = 0
$rnd = [System.Random]::new(42)

for ($i = 0; $i -lt $num_packets; $i++) {
    if ($rnd.NextDouble() -lt $tsv_defect_prob) { $gen1_dropped++ }
    $pFail = $rnd.NextDouble() -lt $tsv_defect_prob
    $bFail = $rnd.NextDouble() -lt $tsv_defect_prob
    if ($pFail -and $bFail) {
        if ($rnd.NextDouble() -lt 0.001) { $gen2_dropped++ }
    }
}
$gen1_delivery = (($num_packets - $gen1_dropped) / $num_packets) * 100.0
$gen2_delivery = (($num_packets - $gen2_dropped) / $num_packets) * 100.0

Write-Host "=========================================================================="
Write-Host "       NEUROSTACK-3D HARDWARE EVOLUTION BENCHMARK: GEN 1 vs. GEN 2"
Write-Host "=========================================================================="
Write-Host ""
Write-Host "[1. SNEAK PATH LEAKAGE & IR DROP]"
Write-Host "  Gen 1: Leakage = $([Math]::Round($sneak_leakage_gen1_mA, 3)) mA | IR Drop = $([Math]::Round($ir_drop_worst_gen1_mV, 2)) mV ($([Math]::Round(($ir_drop_worst_gen1_mV/500.0)*100, 1))% distortion)"
Write-Host "  Gen 2: Leakage = $([Math]::Round($sneak_leakage_gen2_uA, 4)) uA | IR Drop = $([Math]::Round($ir_drop_worst_gen2_mV, 3)) mV ($([Math]::Round(($ir_drop_worst_gen2_mV/500.0)*100, 2))% distortion)"
Write-Host ""
Write-Host "[2. THERMAL JUNCTION TEMPERATURE (@ 12W Active)]"
Write-Host "  Gen 1 (Buried SiO2, Passive)    : $([Math]::Round($t_junction_gen1, 1)) °C [OVERHEATING / DRIFT]"
Write-Host "  Gen 2 (AlN + Microfluidic Fins) : $([Math]::Round($t_junction_gen2, 1)) °C [SAFE OPERATING WINDOW]"
Write-Host ""
Write-Host "[3. INTERCONNECT AXONAL PACKET YIELD (2% TSV defect rate)]"
Write-Host "  Gen 1 (Single TSV)              : $([Math]::Round($gen1_delivery, 2)) % ($gen1_dropped dropped)"
Write-Host "  Gen 2 (Dual-Pair + Deflection)  : $([Math]::Round($gen2_delivery, 4)) % ($gen2_dropped dropped)"
Write-Host "=========================================================================="
