# Copia dagli zip LimeZu solo i file che il gioco usa, con nomi semplici,
# dentro assets/limezu/ (cartella esclusa da git: gli asset comprati non si ridistribuiscono).
#
# Uso:  powershell -ExecutionPolicy Bypass -File tools\import_assets.ps1 [-Source "cartella con gli zip"]
# Di default cerca gli zip nella cartella sopra il progetto.

param(
    [string]$Source = (Join-Path $PSScriptRoot "..\..")
)

Add-Type -AssemblyName System.IO.Compression.FileSystem

$dest = Join-Path $PSScriptRoot "..\assets\limezu"
$bedroom = "1_Interiors/16x16/Theme_Sorter_Black_Shadow_Singles/4_Bedroom_Black_Shadow_SIngles_16x16/Bedroom_Black_Shadow_Singles_{0}.png"
$conference = "1_Interiors/16x16/Theme_Sorter_Black_Shadow_Singles/13_Conference_Hall_Black_Shadow_Singles_16x16/Conference_Hall_Shadow_Singles_{0}.png"

$files = @{
    "moderninteriors-win.zip" = [ordered]@{
        "1_Interiors/16x16/Room_Builder_16x16.png" = "tiles/room_builder.png"
        ($bedroom -f 99)     = "props/bed.png"
        ($bedroom -f 267)    = "props/dresser.png"
        ($bedroom -f 397)    = "props/wardrobe.png"
        ($bedroom -f 379)    = "props/robot_toy.png"
        ($conference -f 29)  = "props/office_desk.png"
        ($conference -f 30)  = "props/computer.png"
        ($conference -f 37)  = "props/office_chair.png"
        ($conference -f 41)  = "props/terminal.png"
        ($conference -f 45)  = "props/trash.png"
        ($conference -f 51)  = "props/cooler.png"
        ($conference -f 54)  = "props/portrait.png"
    }
    "modernexteriors-win.zip" = [ordered]@{
        "Modern_Exteriors_16x16/ME_Theme_Sorter_16x16/2_City_Terrains_16x16.png"     = "tiles/city_terrains.png"
        "Modern_Exteriors_16x16/ME_Theme_Sorter_16x16/4_Generic_Buildings_16x16.png" = "tiles/generic_buildings.png"
    }
}
for ($i = 1; $i -le 20; $i++) {
    $n = "{0:D2}" -f $i
    $files["moderninteriors-win.zip"]["2_Characters/Character_Generator/0_Premade_Characters/16x16/Premade_Character_$n.png"] = "characters/char_$n.png"
}

$copied = 0
foreach ($zipName in $files.Keys) {
    $zipPath = Join-Path $Source $zipName
    if (-not (Test-Path $zipPath)) {
        Write-Warning "Non trovo $zipPath"
        continue
    }
    $zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $zipPath))
    try {
        foreach ($entryName in $files[$zipName].Keys) {
            $entry = $zip.GetEntry($entryName)
            if ($null -eq $entry) {
                Write-Warning "Nello zip $zipName manca: $entryName"
                continue
            }
            $out = Join-Path $dest $files[$zipName][$entryName]
            New-Item -ItemType Directory -Force (Split-Path $out) | Out-Null
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $out, $true)
            $copied++
        }
    } finally {
        $zip.Dispose()
    }
}
Write-Host "Copiati $copied file in $dest"
