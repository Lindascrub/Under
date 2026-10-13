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
$singles = "1_Interiors/16x16/Theme_Sorter_Black_Shadow_Singles"
$bedroom = "$singles/4_Bedroom_Black_Shadow_SIngles_16x16/Bedroom_Black_Shadow_Singles_{0}.png"
$conference = "$singles/13_Conference_Hall_Black_Shadow_Singles_16x16/Conference_Hall_Shadow_Singles_{0}.png"
$living = "$singles/2_LivingRoom_Black_Shadow_Singles_16x16/Living_Room_Black_Shadow_Singles_{0}.png"
$ext = "Modern_Exteriors_16x16/ME_Theme_Sorter_16x16"
$building = "$ext/4_Generic_Building_Singles_16x16/ME_Singles_Generic_Building_16x16_{0}.png"
$cityProp = "$ext/3_City_Props_Singles_16x16/ME_Singles_City_Props_16x16_{0}.png"

$interiors = [ordered]@{
    "1_Interiors/16x16/Room_Builder_16x16.png" = "tiles/room_builder.png"
    ($bedroom -f 99)     = "props/bed.png"
    ($bedroom -f 267)    = "props/dresser.png"
    ($bedroom -f 379)    = "props/robot_toy.png"
    ($living -f 37)      = "props/wardrobe.png"
    ($living -f 96)      = "props/boxes_small.png"
    ($living -f 99)      = "props/boxes.png"
    ($living -f 14)      = "props/palm.png"
    ($living -f 16)      = "props/plant.png"
    ($living -f 79)      = "props/lamp.png"
    ($conference -f 29)  = "props/office_desk.png"
    ($conference -f 30)  = "props/computer.png"
    ($conference -f 37)  = "props/office_chair.png"
    ($conference -f 41)  = "props/terminal.png"
    ($conference -f 45)  = "props/trash.png"
    ($conference -f 54)  = "props/portrait.png"
}
for ($i = 1; $i -le 20; $i++) {
    $n = "{0:D2}" -f $i
    $interiors["2_Characters/Character_Generator/0_Premade_Characters/16x16/Premade_Character_$n.png"] = "characters/char_$n.png"
}

$exteriors = [ordered]@{
    "$ext/2_City_Terrains_16x16.png" = "tiles/city_terrains.png"
    ($building -f "Condo_3_46")        = "buildings/home.png"
    ($building -f "Condo_5_1")         = "buildings/condo_blue.png"
    ($building -f "Condo_5_3")         = "buildings/condo_yellow.png"
    ($building -f "Condo_9_Example")   = "buildings/condo_dirty.png"
    ($building -f "Condo_6_Example")   = "buildings/condo_big.png"
    "$ext/16_Office_Singles_16x16/ME_Singles_Office_16x16_Example_2.png" = "buildings/cheap_tower.png"
}
$props = @{
    "Bench_3" = "bench_side"; "Bench_1" = "bench"; "Street_Lamp_1" = "lamp"; "Tree_1" = "tree"; "Tree_3" = "tree_round"
    "Trashbin_1" = "trashbin"; "Black_Open_Full_Trash_Can" = "trash_can_full"; "Trash_Pile_1" = "trash_pile_1"
    "Trash_Pile_2" = "trash_pile_2"; "Trash_Pile_3" = "trash_pile_3"; "Cardboard_Trash_1" = "cardboard"
    "Small_Trash_Pile_1" = "trash_bags"; "Kiosk_Coffee_Empty" = "coffee_kiosk"; "Hydrant_1" = "hydrant"
    "Pigeon_1" = "pigeon_1"; "Pigeon_2" = "pigeon_2"; "Dumpster_1" = "dumpster"; "Dumpster_2" = "dumpster_graffiti"
    "Car_Wreck_1" = "car_wreck"; "Junk_Shack_1" = "shack"; "Phone_Booth_1" = "phone_booth"; "Mailbox_1" = "mailbox"
    "Flower_Bush_1" = "flowers"; "Billboard_1" = "billboard"; "Box_Trash_1" = "box_trash"; "Scrap_Metal_Pile_1" = "scrap"
}
foreach ($k in $props.Keys) { $exteriors[($cityProp -f $k)] = "street/$($props[$k]).png" }

# Parco
$garden = "$ext/17_Garden_Singles_16x16/ME_Singles_Garden_16x16_{0}.png"
$exteriors["$ext/1_Terrains_and_Fences_16x16.png"] = "tiles/terrains.png"
$exteriors[($cityProp -f "Fountain_1")] = "park/fountain.png"
$exteriors[($garden -f "Statue_Angel_1")] = "park/angel.png"
$exteriors[($garden -f "Medium_Bench_Horizontal")] = "park/bench.png"
$exteriors[($garden -f "Bush_1")] = "park/bush.png"
$exteriors[($garden -f "Bush_5")] = "park/bush_2.png"
$exteriors[($garden -f "Big_Sunflower")] = "park/sunflower.png"
$exteriors[($cityProp -f "Tree_2")] = "park/tree_2.png"

# Auto per il traffico (viste di lato)
$vehicle = "$ext/10_Vehicles_Singles_16x16/ME_Singles_Vehicles_16x16_{0}.png"
foreach ($n in 1..6) {
    $exteriors[($vehicle -f "Car_Left_$n")] = "cars/car_left_$n.png"
    $exteriors[($vehicle -f "Car_Right_$n")] = "cars/car_right_$n.png"
}

$files = @{ "moderninteriors-win.zip" = $interiors; "modernexteriors-win.zip" = $exteriors }

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
