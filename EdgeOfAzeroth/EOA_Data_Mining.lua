-- EOA_Data_Mining.lua
EOA_DATA = EOA_DATA or {}

EOA_DATA.Mining = {
    {
        id = "mining_searing_gorge_loop",
        name = "Searing Gorge Outer Ring",
        mapID = 1427,
        x = 0.420,
        y = 0.350,
        type = "FARM",
        levelMin = 45,
        levelMax = 55,
        profession = "Mining",
        resource = "Mithril/Thorium",
        tags = { "loop", "ore", "mid-high" },
        description = "Run the outer cliffs and lava edges for dense mithril with thorium pockets."
    },
    {
        id = "mining_burning_steppes_ridge",
        name = "Burning Steppes Ridge Route",
        mapID = 1428,
        x = 0.620,
        y = 0.370,
        type = "FARM",
        levelMin = 50,
        levelMax = 60,
        profession = "Mining",
        resource = "Thorium",
        tags = { "loop", "ore", "high" },
        description = "Ridge-to-ridge circuit with reliable small thorium node coverage."
    },
    {
        id = "mining_winterspring_ice_thistle",
        name = "Winterspring Ice Thistle Loop",
        mapID = 1452,
        x = 0.610,
        y = 0.420,
        type = "FARM",
        levelMin = 55,
        levelMax = 60,
        profession = "Mining",
        resource = "Rich Thorium",
        tags = { "loop", "ore", "endgame" },
        description = "High-level route along northern and eastern walls with rich thorium spawns."
    },
    {
        id = "mining_ungoro_crater_circuit",
        name = "Un'Goro Crater Wall Circuit",
        mapID = 1449,
        x = 0.490,
        y = 0.550,
        type = "FARM",
        levelMin = 50,
        levelMax = 60,
        profession = "Mining",
        resource = "Thorium",
        tags = { "loop", "ore", "elemental" },
        description = "Follow crater walls and cave mouths for thorium and crystal nodes."
    },
    {
        id = "mining_felwood_irontree",
        name = "Felwood Irontree Path",
        mapID = 1448,
        x = 0.540,
        y = 0.200,
        type = "FARM",
        levelMin = 48,
        levelMax = 58,
        profession = "Mining",
        resource = "Mithril/Thorium",
        tags = { "loop", "ore", "contested" },
        description = "Mine along Irontree and central lanes while weaving around satyr camps."
    },
    {
        id = "mining_badlands_western_sweep",
        name = "Badlands Western Sweep",
        mapID = 1418,
        x = 0.180,
        y = 0.550,
        type = "FARM",
        levelMin = 38,
        levelMax = 48,
        profession = "Mining",
        resource = "Iron/Mithril",
        tags = { "loop", "ore", "mid" },
        description = "Good iron and mithril route around canyons and trogg hills."
    },
}
