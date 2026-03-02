-- EOA_Data_Farming.lua
EOA_DATA = EOA_DATA or {}

EOA_DATA.Farming = {
    {
        id = "farm_eastern_plaguebats",
        name = "Plaguebat Circuit",
        mapID = 1415,
        x = 0.777,
        y = 0.552,
        type = "FARM",
        zoneGroup = "Eastern Kingdoms",
        tags = { "runecloth", "bats", "vendor" },
        description = "The eastern ridges host plaguebats with a practical loop for steady cloth and vendor trash farming. Pathing is simple enough to maintain momentum while avoiding unnecessary backtracking. It is suitable for solo sessions with consistent pull spacing and quick resets. The route rewards awareness but remains manageable with standard consumables and gear.",
    },
    {
        id = "farm_felwood_satyrs",
        name = "Felwood Satyr Camp",
        mapID = 1448,
        x = 0.375,
        y = 0.673,
        type = "FARM",
        zoneGroup = "Kalimdor",
        tags = { "felcloth", "satyr", "demons" },
        description = "Felwood satyr camps are a classic destination for players seeking demonic loot tables and repeatable grinding. The area supports circular pulls with minimal dead travel between packs. Hostiles can pressure cloth classes, but terrain remains readable and practical for controlled farming. The corrupted forest visuals make long sessions feel distinct and immersive.",
    },
    {
        id = "farm_winterfall_furbolgs",
        name = "Winterfall Furbolg Grounds",
        mapID = 1452,
        x = 0.659,
        y = 0.408,
        type = "FARM",
        zoneGroup = "Kalimdor",
        tags = { "reputation", "furbolg", "winterspring" },
        description = "Winterfall camps provide a compact grind route with clear spawn clusters in snowy terrain. Movement between targets is efficient and supports both reputation and material goals. The zone's visibility helps maintain pace and quickly identify respawn timings. This is a stable option for players who prefer structured loops over broad roaming.",
    },
    {
        id = "farm_silithus_twilight",
        name = "Twilight Base Camp",
        mapID = 1451,
        x = 0.483,
        y = 0.371,
        type = "FARM",
        zoneGroup = "Kalimdor",
        tags = { "twilight", "texts", "silithus" },
        description = "Twilight camps in Silithus are favored for repeatable kill loops and faction-related materials. The camp layout supports route planning with clear tent clusters and short transitions. Enemy density is high enough to keep combat continuous during active periods. Sandstorm ambience and cult encampments create a harsh but focused farming environment.",
    },
}
