# PowerShell STL Generator for NeuroStack-3D
param(
    [string]$ExplodedFile = "c:\Users\abina\Documents\antigravity\happy-newton\neurostack_exploded.stl",
    [string]$AssembledFile = "c:\Users\abina\Documents\antigravity\happy-newton\neurostack_assembled.stl"
)

function New-StlGenerator {
    return [PSCustomObject]@{
        Facets = [System.Collections.Generic.List[string]]::new()
    }
}

function Add-Triangle {
    param($gen, $p1, $p2, $p3)
    # Compute normal
    $ux = $p2[0] - $p1[0]; $uy = $p2[1] - $p1[1]; $uz = $p2[2] - $p1[2]
    $vx = $p3[0] - $p1[0]; $vy = $p3[1] - $p1[1]; $vz = $p3[2] - $p1[2]
    $nx = $uy * $vz - $uz * $vy
    $ny = $uz * $vx - $ux * $vz
    $nz = $ux * $vy - $uy * $vx
    $len = [Math]::Sqrt($nx*$nx + $ny*$ny + $nz*$nz)
    if ($len -gt 0) { $nx /= $len; $ny /= $len; $nz /= $len } else { $nz = 1.0 }
    
    $facet = "  facet normal $([Math]::Round($nx,4)) $([Math]::Round($ny,4)) $([Math]::Round($nz,4))`n" +
             "    outer loop`n" +
             "      vertex $([Math]::Round($p1[0],4)) $([Math]::Round($p1[1],4)) $([Math]::Round($p1[2],4))`n" +
             "      vertex $([Math]::Round($p2[0],4)) $([Math]::Round($p2[1],4)) $([Math]::Round($p2[2],4))`n" +
             "      vertex $([Math]::Round($p3[0],4)) $([Math]::Round($p3[1],4)) $([Math]::Round($p3[2],4))`n" +
             "    endloop`n" +
             "  endfacet"
    $gen.Facets.Add($facet)
}

function Add-StlBox {
    param($gen, $x0, $x1, $y0, $y1, $z0, $z1)
    $v1 = @($x0, $y0, $z0); $v2 = @($x1, $y0, $z0); $v3 = @($x1, $y1, $z0); $v4 = @($x0, $y1, $z0)
    $v5 = @($x0, $y0, $z1); $v6 = @($x1, $y0, $z1); $v7 = @($x1, $y1, $z1); $v8 = @($x0, $y1, $z1)
    # Bottom
    Add-Triangle $gen $v1 $v2 $v3; Add-Triangle $gen $v1 $v3 $v4
    # Top
    Add-Triangle $gen $v5 $v7 $v6; Add-Triangle $gen $v5 $v8 $v7
    # Front
    Add-Triangle $gen $v1 $v6 $v2; Add-Triangle $gen $v1 $v5 $v6
    # Back
    Add-Triangle $gen $v4 $v3 $v7; Add-Triangle $gen $v4 $v7 $v8
    # Left
    Add-Triangle $gen $v1 $v4 $v8; Add-Triangle $gen $v1 $v8 $v5
    # Right
    Add-Triangle $gen $v2 $v6 $v7; Add-Triangle $gen $v2 $v7 $v3
}

function Add-StlCylinder {
    param($gen, $cx, $cy, $z0, $z1, $r, $sides = 12)
    $botVerts = @()
    $topVerts = @()
    for ($i = 0; $i -lt $sides; $i++) {
        $a = ($i / $sides) * [Math]::PI * 2.0
        $botVerts += ,@($cx + $r * [Math]::Cos($a), $cy + $r * [Math]::Sin($a), $z0)
        $topVerts += ,@($cx + $r * [Math]::Cos($a), $cy + $r * [Math]::Sin($a), $z1)
    }
    $botCenter = @($cx, $cy, $z0)
    $topCenter = @($cx, $cy, $z1)
    
    for ($i = 0; $i -lt $sides; $i++) {
        $next = ($i + 1) % $sides
        # Bottom fan
        Add-Triangle $gen $botCenter $botVerts[$next] $botVerts[$i]
        # Top fan
        Add-Triangle $gen $topCenter $topVerts[$i] $topVerts[$next]
        # Sides
        Add-Triangle $gen $botVerts[$i] $topVerts[$i] $topVerts[$next]
        Add-Triangle $gen $botVerts[$i] $topVerts[$next] $botVerts[$next]
    }
}

function Build-Model {
    param([double]$gap)
    $gen = New-StlGenerator
    $dieSize = 30.0
    $halfDie = $dieSize / 2.0

    # 1. Base / Backside PDN
    $z0 = 0.0
    $z1 = 3.0
    Add-StlBox $gen (-$halfDie - 1.5) ($halfDie + 1.5) (-$halfDie - 1.5) ($halfDie + 1.5) $z0 $z1

    # 2. Tier 3: Axon / 3D-AER Router
    $z0 = $z1 + $gap
    $z1 = $z0 + 2.5
    Add-StlBox $gen (-$halfDie) ($halfDie) (-$halfDie) ($halfDie) $z0 $z1

    # 3. TSV Array
    $tsvZ0 = $z1
    $tsvZ1 = $tsvZ0 + $gap + 2.5
    for ($ix = -2; $ix -le 2; $ix++) {
        for ($iy = -2; $iy -le 2; $iy++) {
            Add-StlCylinder $gen ($ix * 5.0) ($iy * 5.0) $tsvZ0 $tsvZ1 0.7 10
        }
    }

    # 4. Tier 2: Soma LIF Logic
    $z0 = $tsvZ1 - 2.5
    $z1 = $tsvZ1
    Add-StlBox $gen (-$halfDie) ($halfDie) (-$halfDie) ($halfDie) $z0 $z1

    # 5. Tier 1: Synaptic Crossbars
    $z0 = $z1 + $gap
    $z1 = $z0 + 1.2
    Add-StlBox $gen (-$halfDie + 2.0) ($halfDie - 2.0) (-$halfDie + 2.0) ($halfDie - 2.0) $z0 $z1

    # Wordlines & Bitlines & Memristor nodes
    for ($i = -3; $i -le 3; $i++) {
        $y = $i * 2.5
        Add-StlBox $gen (-10.0) (10.0) ($y - 0.3) ($y + 0.3) ($z1) ($z1 + 0.3)
    }
    for ($ix = -3; $ix -le 3; $ix++) {
        for ($iy = -3; $iy -le 3; $iy++) {
            $x = $ix * 2.5; $y = $iy * 2.5
            Add-StlBox $gen ($x - 0.4) ($x + 0.4) ($y - 0.4) ($y + 0.4) ($z1 + 0.3) ($z1 + 0.8)
        }
    }
    for ($i = -3; $i -le 3; $i++) {
        $x = $i * 2.5
        Add-StlBox $gen ($x - 0.3) ($x + 0.3) (-10.0) (10.0) ($z1 + 0.8) ($z1 + 1.1)
    }
    $z1 = $z1 + 1.2

    # 6. Hybrid Bonding Interface
    $z0 = $z1 + $gap
    $z1 = $z0 + 0.8
    Add-StlBox $gen (-$halfDie + 1.0) ($halfDie - 1.0) (-$halfDie + 1.0) ($halfDie - 1.0) $z0 $z1

    # 7. Tier 0: DVS Sensor + Microlenses
    $z0 = $z1 + $gap
    $z1 = $z0 + 2.5
    Add-StlBox $gen (-$halfDie) ($halfDie) (-$halfDie) ($halfDie) $z0 $z1

    for ($lx = -3; $lx -le 3; $lx++) {
        for ($ly = -3; $ly -le 3; $ly++) {
            Add-StlCylinder $gen ($lx * 3.2) ($ly * 3.2) $z1 ($z1 + 0.6) 1.2 12
        }
    }

    return $gen
}

Write-Host "Generating Exploded STL model..."
$genExploded = Build-Model 5.0
$sbExploded = [System.Text.StringBuilder]::new()
[void]$sbExploded.AppendLine("solid NeuroStack3D_Exploded")
foreach ($f in $genExploded.Facets) { [void]$sbExploded.AppendLine($f) }
[void]$sbExploded.AppendLine("endsolid NeuroStack3D_Exploded")
[System.IO.File]::WriteAllText($ExplodedFile, $sbExploded.ToString())
Write-Host "Created $ExplodedFile with $($genExploded.Facets.Count) triangles."

Write-Host "Generating Assembled Watertight STL model..."
$genAssembled = Build-Model 0.0
$sbAssembled = [System.Text.StringBuilder]::new()
[void]$sbAssembled.AppendLine("solid NeuroStack3D_Assembled")
foreach ($f in $genAssembled.Facets) { [void]$sbAssembled.AppendLine($f) }
[void]$sbAssembled.AppendLine("endsolid NeuroStack3D_Assembled")
[System.IO.File]::WriteAllText($AssembledFile, $sbAssembled.ToString())
Write-Host "Created $AssembledFile with $($genAssembled.Facets.Count) triangles."
