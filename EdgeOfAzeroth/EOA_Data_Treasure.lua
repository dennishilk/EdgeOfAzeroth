-- EOA_Data_Treasure.lua
EOA_DATA = EOA_DATA or {}

EOA_DATA.Treasure = {
    {
        id = "treasure_searing_gorge_chest_loop",
        name = "Searing Gorge Chest Sweep",
        mapID = 1427,
        x = 0.500,
        y = 0.500,
        type = "TREASURE",
        levelMin = 50,
        levelMax = 60,
        profession = nil,
        resource = "World Chests",
        tags = { "chests", "contested", "loop" },
        description = "Open terrain makes this a popular circuit for scattered world chest spawns."
    },
    {
        id = "treasure_azshara_blood_elf_tower",
        name = "Azshara Ruin Chest Spots",
        mapID = 1447,
        x = 0.570,
        y = 0.740,
        type = "TREASURE",
        levelMin = 45,
        levelMax = 60,
        profession = nil,
        resource = "World Chests",
        tags = { "chests", "ruins", "high-level" },
        description = "Ruined structures and tower areas hold frequent chest and rare spawn checks."
    },
    {
        id = "treasure_badlands_rare_patrols",
        name = "Badlands Rare Patrol Route",
        mapID = 1418,
        x = 0.430,
        y = 0.560,
        type = "TREASURE",
        levelMin = 38,
        levelMax = 48,
        profession = nil,
        resource = "Rare Spawns",
        tags = { "rares", "patrol", "mid" },
        description = "Canyon roads and ridges are ideal for looping known rare patrol areas."
    },
    {
        id = "treasure_silithus_twilight_camps",
        name = "Silithus Twilight Camps",
        mapID = 1451,
        x = 0.455,
        y = 0.400,
        type = "TREASURE",
        levelMin = 55,
        levelMax = 60,
        profession = nil,
        resource = "Encrypted Twilight Text",
        tags = { "rares", "camp", "endgame" },
        description = "Farm camps for summon items and rare elite opportunities nearby."
    },
    {
        id = "treasure_hinterlands_troll_ruins",
        name = "Hinterlands Troll Ruins Chests",
        mapID = 1425,
        x = 0.560,
        y = 0.430,
        type = "TREASURE",
        levelMin = 42,
        levelMax = 52,
        profession = nil,
        resource = "World Chests",
        tags = { "chests", "troll", "ruins" },
        description = "Ruin clusters in the Hinterlands are good chest and rare spawn checkpoints."
    },
    {
        id = "treasure_feralas_ruins_loop",
        name = "Feralas Ruins Treasure Path",
        mapID = 1444,
        x = 0.320,
        y = 0.470,
        type = "TREASURE",
        levelMin = 40,
        levelMax = 50,
        profession = nil,
        resource = "World Chests",
        tags = { "chests", "ogre", "route" },
        description = "Cycle through ruin compounds and coast camps for chest resets and rares."
    },
}
