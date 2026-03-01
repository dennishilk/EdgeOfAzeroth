-- EOA_Data_PvP.lua
EOA_DATA = EOA_DATA or {}

EOA_DATA.PvP = {
    {
        id = "pvp_tarren_mill_vs_ss",
        name = "Tarren Mill vs Southshore",
        mapID = 1424,
        x = 0.500,
        y = 0.460,
        type = "PVP",
        levelMin = 25,
        levelMax = 60,
        profession = nil,
        resource = nil,
        tags = { "world-pvp", "hillsbrad", "classic" },
        description = "Historic world PvP corridor between Southshore and Tarren Mill roads."
    },
    {
        id = "pvp_stranglethorn_road",
        name = "Stranglethorn Main Road",
        mapID = 1434,
        x = 0.430,
        y = 0.540,
        type = "PVP",
        levelMin = 30,
        levelMax = 60,
        profession = nil,
        resource = nil,
        tags = { "world-pvp", "gank", "contested" },
        description = "Heavy cross-faction traffic from quests and flight paths fuels frequent fights."
    },
    {
        id = "pvp_blackrock_mountain",
        name = "Blackrock Mountain Chains",
        mapID = 1428,
        x = 0.355,
        y = 0.840,
        type = "PVP",
        levelMin = 50,
        levelMax = 60,
        profession = nil,
        resource = nil,
        tags = { "world-pvp", "raid", "instance" },
        description = "Raid nights create constant skirmishes at Blackrock Mountain entrances."
    },
    {
        id = "pvp_gurubashi_arena",
        name = "Gurubashi Arena",
        mapID = 1434,
        x = 0.324,
        y = 0.770,
        type = "PVP",
        levelMin = 30,
        levelMax = 60,
        profession = nil,
        resource = nil,
        tags = { "ffa", "arena", "chest" },
        description = "Free-for-all arena with periodic chest events and regular PvP groups."
    },
    {
        id = "pvp_eastern_plaguelands_towers",
        name = "Eastern Plaguelands Towers",
        mapID = 1423,
        x = 0.680,
        y = 0.730,
        type = "PVP",
        levelMin = 55,
        levelMax = 60,
        profession = nil,
        resource = nil,
        tags = { "world-pvp", "tower", "objective" },
        description = "Open-zone objective fights around EPL towers and turn-in hubs."
    },
    {
        id = "pvp_tanaris_gadgetzan_outskirts",
        name = "Gadgetzan Outskirts",
        mapID = 1446,
        x = 0.520,
        y = 0.280,
        type = "PVP",
        levelMin = 40,
        levelMax = 60,
        profession = nil,
        resource = nil,
        tags = { "world-pvp", "neutral-town", "contested" },
        description = "Frequent skirmishes happen around neutral guards and nearby quest hubs."
    },
}
