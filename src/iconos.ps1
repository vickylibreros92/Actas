# Genera los íconos de la app (Android, iOS, adaptable/maskable y favicon)
Add-Type -AssemblyName System.Drawing
$dir = $PSScriptRoot
function Icono([int]$s, [string]$nombre, [double]$escala, [bool]$redondo) {
  $b = New-Object Drawing.Bitmap $s, $s; $g = [Drawing.Graphics]::FromImage($b)
  $g.SmoothingMode = 'AntiAlias'; $g.PixelOffsetMode = 'HighQuality'
  $naranja = [Drawing.Color]::FromArgb(226, 88, 43)
  if ($redondo) { $g.Clear([Drawing.Color]::Transparent); $p = New-Object Drawing.Drawing2D.GraphicsPath; $r = [int]($s * 0.22)
    $p.AddArc(0, 0, $r, $r, 180, 90); $p.AddArc($s - $r - 1, 0, $r, $r, 270, 90); $p.AddArc($s - $r - 1, $s - $r - 1, $r, $r, 0, 90); $p.AddArc(0, $s - $r - 1, $r, $r, 90, 90); $p.CloseFigure()
    $g.FillPath((New-Object Drawing.SolidBrush $naranja), $p) } else { $g.Clear($naranja) }
  # hoja con renglones y firma (escala = proporción del ícono que ocupa la hoja)
  $w = [int]($s * 0.62 * $escala); $h = [int]($s * 0.78 * $escala); $x = [int](($s - $w) / 2); $y = [int](($s - $h) / 2)
  $g.FillRectangle([Drawing.Brushes]::White, $x, $y, $w, $h)
  $pen = New-Object Drawing.Pen $naranja, ([float]([math]::Max(1, $s * 0.022 * $escala)))
  for ($i = 0; $i -lt 5; $i++) { $ly = $y + [int]($h * (0.18 + 0.13 * $i)); $g.DrawLine($pen, $x + [int]($w * 0.14), $ly, $x + [int]($w * 0.86), $ly) }
  $pen2 = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(11, 31, 92)), ([float]([math]::Max(1.2, $s * 0.032 * $escala))); $pen2.StartCap = 'Round'; $pen2.EndCap = 'Round'
  $pts = @(); for ($t = 0; $t -le 24; $t++) { $pts += New-Object Drawing.PointF ([float]($x + $w * 0.14 + $w * 0.72 * $t / 24)), ([float]($y + $h * 0.86 - [math]::Sin($t / 24 * 9.5) * $h * 0.055)) }
  $g.DrawCurve($pen2, [Drawing.PointF[]]$pts)
  $b.Save("$dir\$nombre", [Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $b.Dispose()
}
Icono 192 'icon-192.png' 0.80 $false           # Android (any)
Icono 512 'icon-512.png' 0.80 $false
Icono 512 'icon-maskable-512.png' 0.62 $false  # adaptable: el dibujo queda dentro de la zona segura
Icono 192 'icon-maskable-192.png' 0.62 $false
Icono 180 'apple-touch-icon.png' 0.74 $false   # iPhone/iPad (iOS redondea las esquinas solo)
Icono 32  'favicon-32.png' 0.86 $true
"Íconos generados"
