param(
    [string]$InputObj = "c:\Users\abina\Documents\antigravity\happy-newton\neurostack_model.obj",
    [string]$OutputStl = "c:\Users\abina\Documents\antigravity\happy-newton\neurostack_prototype.stl"
)

$verts = [System.Collections.Generic.List[double[]]]::new()
$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("solid NeuroStack3D")

$lines = [System.IO.File]::ReadAllLines($InputObj)
foreach ($line in $lines) {
    if ($line.StartsWith("v ")) {
        $parts = $line.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
        $vx = [double]::Parse($parts[1])
        $vy = [double]::Parse($parts[2])
        $vz = [double]::Parse($parts[3])
        $verts.Add(@($vx, $vy, $vz))
    } elseif ($line.StartsWith("f ")) {
        $parts = $line.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
        $i1 = [int]::Parse($parts[1].Split("/")[0]) - 1
        $i2 = [int]::Parse($parts[2].Split("/")[0]) - 1
        $i3 = [int]::Parse($parts[3].Split("/")[0]) - 1
        
        $p1 = $verts[$i1]
        $p2 = $verts[$i2]
        $p3 = $verts[$i3]
        
        # Normal
        $ux = $p2[0] - $p1[0]; $uy = $p2[1] - $p1[1]; $uz = $p2[2] - $p1[2]
        $vx = $p3[0] - $p1[0]; $vy = $p3[1] - $p1[1]; $vz = $p3[2] - $p1[2]
        $nx = $uy * $vz - $uz * $vy
        $ny = $uz * $vx - $ux * $vz
        $nz = $ux * $vy - $uy * $vx
        $len = [Math]::Sqrt($nx*$nx + $ny*$ny + $nz*$nz)
        if ($len -gt 0) { $nx /= $len; $ny /= $len; $nz /= $len } else { $nz = 1.0 }
        
        [void]$sb.AppendLine("  facet normal $([Math]::Round($nx, 4)) $([Math]::Round($ny, 4)) $([Math]::Round($nz, 4))")
        [void]$sb.AppendLine("    outer loop")
        [void]$sb.AppendLine("      vertex $([Math]::Round($p1[0], 4)) $([Math]::Round($p1[1], 4)) $([Math]::Round($p1[2], 4))")
        [void]$sb.AppendLine("      vertex $([Math]::Round($p2[0], 4)) $([Math]::Round($p2[1], 4)) $([Math]::Round($p2[2], 4))")
        [void]$sb.AppendLine("      vertex $([Math]::Round($p3[0], 4)) $([Math]::Round($p3[1], 4)) $([Math]::Round($p3[2], 4))")
        [void]$sb.AppendLine("    endloop")
        [void]$sb.AppendLine("  endfacet")
    }
}
[void]$sb.AppendLine("endsolid NeuroStack3D")
[System.IO.File]::WriteAllText($OutputStl, $sb.ToString())
Write-Host "Successfully converted OBJ to STL: $OutputStl ($($verts.Count) vertices converted)"
