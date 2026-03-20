param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

function New-GearPath {
    param(
        [float]$CenterX,
        [float]$CenterY,
        [float]$OuterRadius,
        [float]$InnerRadius,
        [float]$HubRadius,
        [int]$Teeth
    )

    $points = New-Object "System.Collections.Generic.List[System.Drawing.PointF]"
    $stepCount = $Teeth * 2
    $startAngle = -[Math]::PI / 2

    for ($i = 0; $i -lt $stepCount; $i++) {
        $angle = $startAngle + ($i * (2 * [Math]::PI / $stepCount))
        $radius = if (($i % 2) -eq 0) { $OuterRadius } else { $InnerRadius }
        $x = $CenterX + ([Math]::Cos($angle) * $radius)
        $y = $CenterY + ([Math]::Sin($angle) * $radius)
        $points.Add([System.Drawing.PointF]::new([float]$x, [float]$y))
    }

    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $path.FillMode = [System.Drawing.Drawing2D.FillMode]::Alternate
    $path.AddPolygon($points.ToArray())
    $path.AddEllipse(
        [float]($CenterX - $HubRadius),
        [float]($CenterY - $HubRadius),
        [float]($HubRadius * 2),
        [float]($HubRadius * 2)
    )

    return $path
}

function New-Brush {
    param(
        [System.Drawing.RectangleF]$Rect,
        [System.Drawing.Color]$StartColor,
        [System.Drawing.Color]$EndColor,
        [float]$Angle = 90
    )

    return [System.Drawing.Drawing2D.LinearGradientBrush]::new($Rect, $StartColor, $EndColor, $Angle)
}

function Draw-AutomationIconBitmap {
    param(
        [int]$Size
    )

    $bitmap = [System.Drawing.Bitmap]::new($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)

    $center = $Size / 2.0
    $diskInset = $Size * 0.10
    $diskRect = [System.Drawing.RectangleF]::new(
        [float]$diskInset,
        [float]$diskInset,
        [float]($Size - ($diskInset * 2)),
        [float]($Size - ($diskInset * 2))
    )

    $diskPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $diskPath.AddEllipse($diskRect)

    $backgroundBrush = [System.Drawing.Drawing2D.PathGradientBrush]::new($diskPath)
    $backgroundBrush.CenterPoint = [System.Drawing.PointF]::new([float]$center, [float]$center)
    $backgroundBrush.CenterColor = [System.Drawing.Color]::FromArgb(255, 16, 34, 86)
    $backgroundBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(255, 4, 12, 34))
    $graphics.FillPath($backgroundBrush, $diskPath)

    $highlightRect = [System.Drawing.RectangleF]::new(
        [float]($Size * 0.18),
        [float]($Size * 0.18),
        [float]($Size * 0.48),
        [float]($Size * 0.30)
    )
    $highlightBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        $highlightRect,
        [System.Drawing.Color]::FromArgb(75, 122, 205, 255),
        [System.Drawing.Color]::FromArgb(0, 122, 205, 255),
        90
    )
    $graphics.FillEllipse($highlightBrush, $highlightRect)

    foreach ($glow in @(
        @{ Alpha = 34; Width = $Size * 0.13 },
        @{ Alpha = 84; Width = $Size * 0.07 },
        @{ Alpha = 255; Width = [Math]::Max(1.0, $Size * 0.022) }
    )) {
        $pen = [System.Drawing.Pen]::new(
            [System.Drawing.Color]::FromArgb([int]$glow.Alpha, 58, 215, 255),
            [float]$glow.Width
        )
        $graphics.DrawEllipse($pen, $diskRect)
        $pen.Dispose()
    }

    $largeGear = New-GearPath `
        -CenterX ($Size * 0.43) `
        -CenterY ($Size * 0.44) `
        -OuterRadius ($Size * 0.17) `
        -InnerRadius ($Size * 0.135) `
        -HubRadius ($Size * 0.052) `
        -Teeth 8
    $largeGearRect = [System.Drawing.RectangleF]::new(
        [float]($Size * 0.26),
        [float]($Size * 0.27),
        [float]($Size * 0.34),
        [float]($Size * 0.34)
    )
    $largeBrush = New-Brush `
        -Rect $largeGearRect `
        -StartColor ([System.Drawing.Color]::FromArgb(255, 255, 231, 110)) `
        -EndColor ([System.Drawing.Color]::FromArgb(255, 205, 138, 22)) `
        -Angle 90
    $graphics.FillPath($largeBrush, $largeGear)
    $largeOutline = [System.Drawing.Pen]::new(
        [System.Drawing.Color]::FromArgb(255, 255, 210, 92),
        [float][Math]::Max(1.0, $Size * 0.016)
    )
    $graphics.DrawPath($largeOutline, $largeGear)

    $smallGear = New-GearPath `
        -CenterX ($Size * 0.64) `
        -CenterY ($Size * 0.63) `
        -OuterRadius ($Size * 0.125) `
        -InnerRadius ($Size * 0.10) `
        -HubRadius ($Size * 0.038) `
        -Teeth 7
    $smallGearRect = [System.Drawing.RectangleF]::new(
        [float]($Size * 0.51),
        [float]($Size * 0.50),
        [float]($Size * 0.26),
        [float]($Size * 0.26)
    )
    $smallBrush = New-Brush `
        -Rect $smallGearRect `
        -StartColor ([System.Drawing.Color]::FromArgb(255, 255, 255, 255)) `
        -EndColor ([System.Drawing.Color]::FromArgb(255, 176, 190, 212)) `
        -Angle 90
    $graphics.FillPath($smallBrush, $smallGear)
    $smallOutline = [System.Drawing.Pen]::new(
        [System.Drawing.Color]::FromArgb(255, 241, 248, 255),
        [float][Math]::Max(1.0, $Size * 0.014)
    )
    $graphics.DrawPath($smallOutline, $smallGear)

    $hubBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 14, 27, 73))
    $hubOutline = [System.Drawing.Pen]::new(
        [System.Drawing.Color]::FromArgb(230, 167, 220, 255),
        [float][Math]::Max(1.0, $Size * 0.01)
    )
    foreach ($hub in @(
        [System.Drawing.RectangleF]::new(
            [float]($Size * 0.378),
            [float]($Size * 0.388),
            [float]($Size * 0.104),
            [float]($Size * 0.104)
        ),
        [System.Drawing.RectangleF]::new(
            [float]($Size * 0.602),
            [float]($Size * 0.592),
            [float]($Size * 0.076),
            [float]($Size * 0.076)
        )
    )) {
        $graphics.FillEllipse($hubBrush, $hub)
        $graphics.DrawEllipse($hubOutline, $hub)
    }

    $rimShadow = [System.Drawing.Pen]::new(
        [System.Drawing.Color]::FromArgb(78, 10, 20, 56),
        [float]($Size * 0.018)
    )
    $shadowRect = [System.Drawing.RectangleF]::new(
        [float]($diskInset + ($Size * 0.01)),
        [float]($diskInset + ($Size * 0.01)),
        [float]($diskRect.Width - ($Size * 0.02)),
        [float]($diskRect.Height - ($Size * 0.02))
    )
    $graphics.DrawEllipse($rimShadow, $shadowRect)

    $rimShadow.Dispose()
    $hubOutline.Dispose()
    $hubBrush.Dispose()
    $smallOutline.Dispose()
    $smallBrush.Dispose()
    $smallGear.Dispose()
    $largeOutline.Dispose()
    $largeBrush.Dispose()
    $largeGear.Dispose()
    $highlightBrush.Dispose()
    $backgroundBrush.Dispose()
    $diskPath.Dispose()
    $graphics.Dispose()

    return $bitmap
}

function Convert-BitmapToPngBytes {
    param(
        [System.Drawing.Bitmap]$Bitmap
    )

    $stream = [System.IO.MemoryStream]::new()
    $Bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
    $bytes = $stream.ToArray()
    $stream.Dispose()
    return $bytes
}

function Write-PngIco {
    param(
        [string]$Path,
        [byte[][]]$PngImages,
        [int[]]$Sizes
    )

    $fileStream = [System.IO.File]::Create($Path)
    $writer = [System.IO.BinaryWriter]::new($fileStream)

    try {
        $writer.Write([UInt16]0)
        $writer.Write([UInt16]1)
        $writer.Write([UInt16]$PngImages.Count)

        $offset = 6 + ($PngImages.Count * 16)
        for ($i = 0; $i -lt $PngImages.Count; $i++) {
            $size = $Sizes[$i]
            $writer.Write([byte]($(if ($size -ge 256) { 0 } else { $size })))
            $writer.Write([byte]($(if ($size -ge 256) { 0 } else { $size })))
            $writer.Write([byte]0)
            $writer.Write([byte]0)
            $writer.Write([UInt16]1)
            $writer.Write([UInt16]32)
            $writer.Write([UInt32]$PngImages[$i].Length)
            $writer.Write([UInt32]$offset)
            $offset += $PngImages[$i].Length
        }

        for ($i = 0; $i -lt $PngImages.Count; $i++) {
            $writer.Write($PngImages[$i])
        }
    }
    finally {
        $writer.Dispose()
        $fileStream.Dispose()
    }
}

$assetsDir = Join-Path $RepoRoot "assets"
New-Item -ItemType Directory -Path $assetsDir -Force | Out-Null

$sizes = @(16, 20, 24, 32, 40, 48, 64, 128, 256)
$pngPayloads = [System.Collections.Generic.List[byte[]]]::new()

foreach ($size in $sizes) {
    $bitmap = Draw-AutomationIconBitmap -Size $size

    if ($size -eq 256) {
        $previewPath = Join-Path $assetsDir "tray-icon-preview.png"
        $bitmap.Save($previewPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }

    $pngPayloads.Add((Convert-BitmapToPngBytes -Bitmap $bitmap))
    $bitmap.Dispose()
}

$mainIconPath = Join-Path $RepoRoot "main.ico"
$secondaryIconPath = Join-Path $RepoRoot "icon.ico"

Write-PngIco -Path $mainIconPath -PngImages $pngPayloads.ToArray() -Sizes $sizes
Write-PngIco -Path $secondaryIconPath -PngImages $pngPayloads.ToArray() -Sizes $sizes

Write-Host "Generated:"
Write-Host " - $mainIconPath"
Write-Host " - $secondaryIconPath"
Write-Host " - $(Join-Path $assetsDir 'tray-icon-preview.png')"
