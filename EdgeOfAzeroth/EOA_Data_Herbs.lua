-- EOA_Data_Herbs.lua
EOA_DATA = EOA_DATA or {}

EOA_DATA.Herbs = {
    {
        id = "herbs_felwood_whipper_root",
        name = "Felwood North-South Herb Line",
        mapID = 1448,
        x = 0.500,
        y = 0.300,
        type = "FARM",
        levelMin = 48,
        levelMax = 60,
        profession = "Herbalism",
        resource = "Gromsblood/Dreamfoil",
        tags = { "herbs", "loop", "endgame" },
        description = "Long north-south sweep for Dreamfoil, Gromsblood, and Plaguebloom pockets."
    },
    {
        id = "herbs_western_plaguelands_farms",
        name = "Western Plaguelands Farm Ring",
        mapID = 1422,
        x = 0.470,
        y = 0.530,
        type = "FARM",
        levelMin = 50,
        levelMax = 60,
        profession = "Herbalism",
        resource = "Plaguebloom/Arthas' Tears",
        tags = { "herbs", "loop", "undead" },
        description = "Circle around farms and ruins to gather high-value plague herbs."
    },
    {
        id = "herbs_eastern_plaguelands_corridor",
        name = "Eastern Plaguelands Corridor",
        mapID = 1423,
        x = 0.550,
        y = 0.620,
        type = "FARM",
        levelMin = 53,
        levelMax = 60,
        profession = "Herbalism",
        resource = "Plaguebloom",
        tags = { "herbs", "loop", "endgame" },
        description = "Disease-scarred route with reliable Plaguebloom and Dreamfoil coverage."
    },
    {
        id = "herbs_azshara_cliff_route",
        name = "Azshara Cliffside Route",
        mapID = 1447,
        x = 0.420,
        y = 0.580,
        type = "FARM",
        levelMin = 45,
        levelMax = 60,
        profession = "Herbalism",
        resource = "Dreamfoil/Mountain Silversage",
        tags = { "herbs", "loop", "coast" },
        description = "Traverse cliffs and road cuts for high-tier herbs with low mob density."
    },
    {
        id = "herbs_feralas_dreamfoil",
        name = "Feralas Central Circuit",
        mapID = 1444,
        x = 0.480,
        y = 0.420,
        type = "FARM",
        levelMin = 40,
        levelMax = 55,
        profession = "Herbalism",
        resource = "Sungrass/Ghost Mushroom",
        tags = { "herbs", "loop", "jungle" },
        description = "Balanced herb route across central Feralas roads, ruins, and cave edges."
    },
    {
        id = "herbs_swamp_of_sorrows_pools",
        name = "Swamp of Sorrows Marsh Ring",
        mapID = 1435,
        x = 0.500,
        y = 0.600,
        type = "FARM",
        levelMin = 35,
        levelMax = 45,
        profession = "Herbalism",
        resource = "Blindweed/Khadgar's Whisker",
        tags = { "herbs", "loop", "mid" },
        description = "Marsh perimeter path with dense Blindweed and steady mid-tier herb picks."
    },
}
