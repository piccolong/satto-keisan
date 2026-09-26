Add-Type -AssemblyName System.Drawing
$root = "C:\Users\ryout\サッと計算"
$out = "$root\store_listing\graphics"
$src = [System.Drawing.Image]::FromFile("$root\assets\icon\app_icon.png")

function New-Canvas($w, $h) {
  $bmp = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'; $g.InterpolationMode = 'HighQualityBicubic'
  $g.PixelOffsetMode = 'HighQuality'; $g.TextRenderingHint = 'AntiAliasGridFit'
  return @($bmp, $g)
}
function RoundRect($x, $y, $w, $h, $r) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = 2 * $r
  $p.AddArc($x, $y, $d, $d, 180, 90); $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90); $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $p.CloseFigure(); return $p
}

# ── 512x512 アイコン(Play が角丸マスクをかけるので正方形のまま) ──
$bmp, $g = New-Canvas 512 512
$g.DrawImage($src, 0, 0, 512, 512)
$bmp.Save("$out\icon-512.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()

# ── 1024x500 フィーチャー グラフィック ──
$bmp, $g = New-Canvas 1024 500
$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.Point 0, 0), (New-Object System.Drawing.Point 1024, 500), ([System.Drawing.Color]::FromArgb(90, 196, 252)), ([System.Drawing.Color]::FromArgb(26, 136, 240))
$g.FillRectangle($bg, 0, 0, 1024, 500)

# 左: アイコン(角丸 + 影)
$ix = 84; $iy = 90; $is = 320; $ir = 72
$shadow = RoundRect ($ix + 6) ($iy + 12) $is $is $ir
$g.FillPath((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(60, 0, 40, 110))), $shadow)
$clip = RoundRect $ix $iy $is $is $ir
$g.SetClip($clip); $g.DrawImage($src, $ix, $iy, $is, $is); $g.ResetClip()

# 右: テキスト
$white = [System.Drawing.Brushes]::White
$soft = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(235, 255, 255, 255))
$fTitle = New-Object System.Drawing.Font 'Noto Sans JP Black', 84, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$fSub = New-Object System.Drawing.Font 'Noto Sans JP Medium', 30, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$fChip = New-Object System.Drawing.Font 'Noto Sans JP Medium', 24, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$tx = 460
$g.DrawString('サッと計算', $fTitle, $white, $tx - 6, 108)
$g.DrawString('日常の計算を、これ1つでサッと。', $fSub, $soft, $tx, 232)

# 機能チップ
$chips = @('割り勘', '消費税', '日数・日付', '単位変換', '％計算')
$cx = $tx; $cy = 312
$chipBg = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(56, 255, 255, 255))
foreach ($c in $chips) {
  $sz = $g.MeasureString($c, $fChip)
  $w = [math]::Ceiling($sz.Width) + 22; $h = 46
  if ($cx + $w -gt 980) { $cx = $tx; $cy += $h + 12 }
  $g.FillPath($chipBg, (RoundRect $cx $cy $w $h 23))
  $g.DrawString($c, $fChip, $white, $cx + 11, $cy + 6)
  $cx += $w + 12
}
# Play の規定: フィーチャー グラフィックは透明度なし(24 ビット)の PNG
$rgb = $bmp.Clone((New-Object System.Drawing.Rectangle 0, 0, 1024, 500), [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$rgb.Save("$out\feature-graphic-1024x500.png", [System.Drawing.Imaging.ImageFormat]::Png); $rgb.Dispose()
$g.Dispose(); $bmp.Dispose(); $src.Dispose()
Get-ChildItem $out | Select-Object Name, Length
