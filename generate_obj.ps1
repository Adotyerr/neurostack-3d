# PowerShell 3D Wavefront OBJ Generator for NeuroStack-3D Gen 2 (Hardened Prototype)
param(
    [string]$OutputFile = "c:\Users\abina\Documents\antigravity\happy-newton\neurostack_model.obj"
)

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("# NeuroStack-3D Gen 2 Hardened Neuromorphic Prototype Model")
[void]$sb.AppendLine("mtllib neurostack_model.mtl")

$script:vertCount = 0

function Add-Box {
    param($x0, $x1, $y0, $y1, $z0, $z1, $mtl, $name)
    [void]$script:sb.AppendLine("o $name")
    [void]$script:sb.AppendLine("usemtl $mtl")
    
    # 8 vertices
    [void]$script:sb.AppendLine("v $x0 $y0 $z0") # 1
    [void]$script:sb.AppendLine("v $x1 $y0 $z0") # 2
    [void]$script:sb.AppendLine("v $x1 $y1 $z0") # 3
    [void]$script:sb.AppendLine("v $x0 $y1 $z0") # 4
    [void]$script:sb.AppendLine("v $x0 $y0 $z1") # 5
    [void]$script:sb.AppendLine("v $x1 $y0 $z1") # 6
    [void]$script:sb.AppendLine("v $x1 $y1 $z1") # 7
    [void]$script:sb.AppendLine("v $x0 $y1 $z1") # 8
    
    $b = $script:vertCount
    # Bottom
    [void]$script:sb.AppendLine("f $($b+1) $($b+2) $($b+3)")
    [void]$script:sb.AppendLine("f $($b+1) $($b+3) $($b+4)")
    # Top
    [void]$script:sb.AppendLine("f $($b+5) $($b+7) $($b+6)")
    [void]$script:sb.AppendLine("f $($b+5) $($b+8) $($b+7)")
    # Front
    [void]$script:sb.AppendLine("f $($b+1) $($b+6) $($b+2)")
    [void]$script:sb.AppendLine("f $($b+1) $($b+5) $($b+6)")
    # Back
    [void]$script:sb.AppendLine("f $($b+4) $($b+3) $($b+7)")
    [void]$script:sb.AppendLine("f $($b+4) $($b+7) $($b+8)")
    # Left
    [void]$script:sb.AppendLine("f $($b+1) $($b+4) $($b+8)")
    [void]$script:sb.AppendLine("f $($b+1) $($b+8) $($b+5)")
    # Right
    [void]$script:sb.AppendLine("f $($b+2) $($b+6) $($b+7)")
    [void]$script:sb.AppendLine("f $($b+2) $($b+7) $($b+3)")
    
    $script:vertCount += 8
}

function Add-Cylinder {
    param($cx, $cy, $z0, $z1, $r, $sides = 10, $mtl, $name)
    [void]$script:sb.AppendLine("o $name")
    [void]$script:sb.AppendLine("usemtl $mtl")
    
    $b = $script:vertCount
    
    for ($i = 0; $i -lt $sides; $i++) {
        $angle = ($i / $sides) * [Math]::PI * 2.0
        $x = $cx + $r * [Math]::Cos($angle)
        $y = $cy + $r * [Math]::Sin($angle)
        [void]$script:sb.AppendLine("v $([Math]::Round($x, 4)) $([Math]::Round($y, 4)) $z0")
    }
    for ($i = 0; $i -lt $sides; $i++) {
        $angle = ($i / $sides) * [Math]::PI * 2.0
        $x = $cx + $r * [Math]::Cos($angle)
        $y = $cy + $r * [Math]::Sin($angle)
        [void]$script:sb.AppendLine("v $([Math]::Round($x, 4)) $([Math]::Round($y, 4)) $z1")
    }
    
    [void]$script:sb.AppendLine("v $cx $cy $z0")
    [void]$script:sb.AppendLine("v $cx $cy $z1")
    $botCenter = $b + 2 * $sides + 1
    $topCenter = $b + 2 * $sides + 2
    
    for ($i = 0; $i -lt $sides; $i++) {
        $next = ($i + 1) % $sides
        $vBotCurr = $b + $i + 1
        $vBotNext = $b + $next + 1
        $vTopCurr = $b + $sides + $i + 1
        $vTopNext = $b + $sides + $next + 1
        
        [void]$script:sb.AppendLine("f $botCenter $vBotNext $vBotCurr")
        [void]$script:sb.AppendLine("f $topCenter $vTopCurr $vTopNext")
        [void]$script:sb.AppendLine("f $vBotCurr $vTopCurr $vTopNext")
        [void]$script:sb.AppendLine("f $vBotCurr $vTopNext $vBotNext")
    }
    
    $script:vertCount += (2 * $sides + 2)
}

Write-Host "Constructing NeuroStack-3D Gen 2 Hardened Mesh..."

$dieSize = 32.0
$halfDie = $dieSize / 2.0
$gap = 6.5 # Visual exploded gap

# ==============================================================================
# 1. Base Substrate with Integrated Microchannel Liquid Cooling
# ==============================================================================
$z0 = 0.0
$z1 = 3.5
# Solid base carrier plate
Add-Box (-$halfDie - 1.5) ($halfDie + 1.5) (-$halfDie - 1.5) ($halfDie + 1.5) $z0 ($z0 + 1.0) "Silicon_Dark" "Base_Silicon_Carrier"

# Etched Microfluidic Cooling Fins (Channels through which coolant circulates)
for ($channel = -4; $channel -le 4; $channel++) {
    $yPos = $channel * 3.2
    # Cooling Fin walls
    Add-Box (-$halfDie - 1.0) ($halfDie + 1.0) ($yPos - 0.7) ($yPos + 0.7) ($z0 + 1.0) ($z1) "Copper_Interconnect" "Cooling_Fin_$channel"
}

# ==============================================================================
# 2. Tier 3: Axon / 3D-AER Router with Fault-Tolerant Deflection Engines
# ==============================================================================
$z0 = $z1 + $gap
$z1 = $z0 + 2.5
Add-Box (-$halfDie) ($halfDie) (-$halfDie) ($halfDie) $z0 $z1 "Silicon_Dark" "Tier3_AER_Deflection_Router_Die"

# ==============================================================================
# 3. Interconnect Matrix: Redundant TSV Pairs + Thermal Relief Vias (TRVs)
# ==============================================================================
$tsvZ0 = $z1
$tsvZ1 = $tsvZ0 + $gap + 2.5

# A. Dual Redundant TSV Pairs (Signal A and Backup B for 100% yield protection)
for ($ix = -2; $ix -le 2; $ix++) {
    for ($iy = -2; $iy -le 2; $iy++) {
        $px = $ix * 5.5
        $py = $iy * 5.5
        # Primary Via
        Add-Cylinder ($px - 0.7) $py $tsvZ0 $tsvZ1 0.45 8 "Copper_Interconnect" "Primary_TSV_${ix}_${iy}"
        # Redundant Backup Via
        Add-Cylinder ($px + 0.7) $py $tsvZ0 $tsvZ1 0.45 8 "Copper_Interconnect" "Backup_TSV_${ix}_${iy}"
    }
}

# B. Thermal Relief Vias (TRVs) along the perimeter to wick heat downwards
for ($tx = -3; $tx -le 3; $tx++) {
    Add-Cylinder ($tx * 4.5) (-$halfDie + 1.5) $tsvZ0 $tsvZ1 0.6 8 "Gold_Wordline" "TRV_Thermal_Via_Y0_$tx"
    Add-Cylinder ($tx * 4.5) ($halfDie - 1.5) $tsvZ0 $tsvZ1 0.6 8 "Gold_Wordline" "TRV_Thermal_Via_Y1_$tx"
}

# ==============================================================================
# 4. Tier 2: Soma LIF Logic Die
# ==============================================================================
$z0 = $tsvZ1 - 2.5
$z1 = $tsvZ1
Add-Box (-$halfDie) ($halfDie) (-$halfDie) ($halfDie) $z0 $z1 "Silicon_Dark" "Tier2_Soma_Logic_Die"

# ==============================================================================
# 5. Tier 1: Sub-Mat Partitioned Synaptic Decks (4 sub-mats to stop IR drop)
# ==============================================================================
$z0 = $z1 + $gap
$z1 = $z0 + 1.5

# AlN High-Conductivity Heat-Spreader Plate
Add-Box (-$halfDie + 1.0) ($halfDie - 1.0) (-$halfDie + 1.0) ($halfDie - 1.0) $z0 ($z0 + 0.3) "Dielectric_Glass" "AlN_Thermal_Spreader_Plate"

# Four isolated 4x4 sub-mats (Quad-Core Crossbar Partitioning)
$quadCenters = @(
    @(-7.0, -7.0),
    @( 7.0, -7.0),
    @(-7.0,  7.0),
    @( 7.0,  7.0)
)

$subIdx = 0
foreach ($qc in $quadCenters) {
    $qX = $qc[0]
    $qY = $qc[1]
    $subIdx++
    
    # Sub-mat dielectric bed
    Add-Box ($qX - 5.5) ($qX + 5.5) ($qY - 5.5) ($qY + 5.5) ($z0 + 0.3) ($z0 + 0.6) "Dielectric_Glass" "SubMat_Bed_$subIdx"
    
    # Wordlines (Gold, X-direction)
    for ($i = -1; $i -le 1; $i++) {
        $wy = $qY + $i * 2.2
        Add-Box ($qX - 4.5) ($qX + 4.5) ($wy - 0.25) ($wy + 0.25) ($z0 + 0.6) ($z0 + 0.8) "Gold_Wordline" "Sub_${subIdx}_WL_$i"
    }
    
    # 1S1R Bilayer Memristive Nodes with High-Selectivity OTS
    for ($ix = -1; $ix -le 1; $ix++) {
        for ($iy = -1; $iy -le 1; $iy++) {
            $mx = $qX + $ix * 2.2
            $my = $qY + $iy * 2.2
            Add-Box ($mx - 0.35) ($mx + 0.35) ($my - 0.35) ($my + 0.35) ($z0 + 0.8) ($z0 + 1.1) "Memristor_Active_Oxide" "Sub_${subIdx}_1S1R_${ix}_${iy}"
        }
    }
    
    # Bitlines (Copper, Y-direction)
    for ($i = -1; $i -le 1; $i++) {
        $bx = $qX + $i * 2.2
        Add-Box ($bx - 0.25) ($bx + 0.25) ($qY - 4.5) ($qY + 4.5) ($z0 + 1.1) ($z0 + 1.3) "Copper_Interconnect" "Sub_${subIdx}_BL_$i"
    }
}
$z1 = $z0 + 1.5

# ==============================================================================
# 6. Hybrid Cu-Cu Direct Bonding Interface
# ==============================================================================
$z0 = $z1 + $gap
$z1 = $z0 + 0.8
Add-Box (-$halfDie + 1.0) ($halfDie - 1.0) (-$halfDie + 1.0) ($halfDie - 1.0) $z0 $z1 "Dielectric_Glass" "Interface_HybridBonding"

# ==============================================================================
# 7. Tier 0: Event-Driven Sensory Transduction Layer + Micro-lenses
# ==============================================================================
$z0 = $z1 + $gap
$z1 = $z0 + 2.5
Add-Box (-$halfDie) ($halfDie) (-$halfDie) ($halfDie) $z0 $z1 "Silicon_Dark" "Tier0_DVS_Sensor_Die"

# Micro-lenses
for ($lx = -3; $lx -le 3; $lx++) {
    for ($ly = -3; $ly -le 3; $ly++) {
        Add-Cylinder ($lx * 3.4) ($ly * 3.4) $z1 ($z1 + 0.6) 1.2 10 "Optical_Lens" "Microlens_${lx}_${ly}"
    }
}

[System.IO.File]::WriteAllText($OutputFile, $sb.ToString())
Write-Host "Exported NeuroStack-3D Gen 2 OBJ mesh with $($script:vertCount) vertices to $OutputFile"
