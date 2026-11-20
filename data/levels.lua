-- Level data: three levels per faction, played in order (finishing one
-- unlocks the next). Pure data, no functions or requires, so tools/artkit
-- can load it too. systems/level.lua builds the map from it and
-- systems/wave.lua builds the waves.
--
-- Map: 24 x 18 cells of 32 px. Cells are {column, row}, 1-based, with
-- {1, 1} at the top left.
--
-- paths: one or more roads. Each is a list of waypoints; consecutive
--   waypoints share a row or a column and the road runs straight between
--   them. The string "portal" between two waypoints means enemies vanish at
--   the first and reappear at the second. Enemies take turns between paths.
--   Paths may share cells (they merge).
-- rocks: {x1, y1, x2, y2} rectangles where nothing can be built.
-- palette: ground colors for the generated map (systems/level.lua). A level
--   with a painted `plate` uses that image instead.
-- waves: count, plus optional overrides of the curve in systems/wave.lua;
--   toughness scales enemy health on that level (tuned with
--   tests/run.sh balance).
-- startGold, lives: what the player starts with.

local Levels = { cols = 24, rows = 18 }

Levels.list = {
    --------------------------------------------------------------------
    -- Radiant Order
    --------------------------------------------------------------------
    {
        id = "sunlit_meadows", faction = "radiant", order = 1,
        name = "Sunlit Meadows",
        description = "One long winding road through open fields. Learn the ropes.",
        difficulty = 1, palette = "meadow", plate = "sprites/maps/level1.png",
        startGold = 220, lives = 20,
        paths = {
            { {1, 1}, {8, 1}, {8, 8}, {14, 8}, {14, 3}, {18, 3}, {18, 12}, {4, 12}, {4, 17}, {18, 17} },
        },
        waves = { count = 10 },
    },
    {
        id = "crystal_spires", faction = "radiant", order = 2,
        name = "Crystal Spires",
        description = "Two roads from the west meet at the bridge. Cover both.",
        difficulty = 2, palette = "crystal",
        startGold = 260, lives = 20,
        paths = {
            { {1, 3}, {9, 3}, {9, 9}, {13, 9}, {13, 16}, {20, 16}, {20, 10}, {24, 10} },
            { {1, 15}, {5, 15}, {5, 9}, {9, 9}, {13, 9}, {13, 16}, {20, 16}, {20, 10}, {24, 10} },
        },
        rocks = { { 19, 2, 23, 6 }, { 15, 12, 18, 14 } },
        waves = { count = 12, toughness = 1.6 },
    },
    {
        id = "celestial_citadel", faction = "radiant", order = 3,
        name = "Celestial Citadel",
        description = "The road spirals in to the citadel at the center. Long, but the waves are relentless.",
        difficulty = 3, palette = "citadel",
        startGold = 300, lives = 15,
        paths = {
            { {1, 2}, {22, 2}, {22, 16}, {3, 16}, {3, 6}, {18, 6}, {18, 12}, {8, 12}, {8, 9}, {13, 9} },
        },
        waves = { count = 15, toughness = 0.85 },
    },

    --------------------------------------------------------------------
    -- Shadow Covenant
    --------------------------------------------------------------------
    {
        id = "haunted_forest", faction = "shadow", order = 1,
        name = "Haunted Forest",
        description = "A switchback trail through dead trees. Long enough to wear them down.",
        difficulty = 1, palette = "forest",
        startGold = 220, lives = 20,
        paths = {
            { {1, 3}, {20, 3}, {20, 7}, {4, 7}, {4, 11}, {20, 11}, {20, 15}, {1, 15} },
        },
        waves = { count = 10 },
    },
    {
        id = "obsidian_caves", faction = "shadow", order = 2,
        name = "Obsidian Caves",
        description = "Narrow tunnels between walls of rock. Few places to build.",
        difficulty = 2, palette = "cave",
        startGold = 280, lives = 20,
        paths = {
            { {1, 9}, {6, 9}, {6, 3}, {12, 3}, {12, 15}, {18, 15}, {18, 9}, {24, 9} },
        },
        rocks = {
            { 1, 1, 4, 6 }, { 1, 12, 9, 18 }, { 14, 1, 24, 6 }, { 20, 12, 24, 18 },
            { 8, 6, 10, 12 }, { 14, 9, 16, 12 },
        },
        waves = { count = 12, toughness = 1.35 },
    },
    {
        id = "necropolis", faction = "shadow", order = 3,
        name = "Necropolis",
        description = "A crypt maze. Enemies step through a portal into the far side of the city.",
        difficulty = 3, palette = "necro",
        startGold = 300, lives = 15,
        paths = {
            { {1, 2}, {10, 2}, {10, 7}, {3, 7}, {3, 13}, "portal",
              {15, 4}, {21, 4}, {21, 10}, {15, 10}, {15, 16}, {24, 16} },
        },
        rocks = { { 6, 10, 9, 17 } },
        waves = { count = 15, toughness = 0.8 },
    },

    --------------------------------------------------------------------
    -- Twilight Balance
    --------------------------------------------------------------------
    {
        id = "misty_borderlands", faction = "twilight", order = 1,
        name = "Misty Borderlands",
        description = "A road along the border marsh, doubling back on itself.",
        difficulty = 1, palette = "mist",
        startGold = 220, lives = 20,
        paths = {
            { {1, 9}, {5, 9}, {5, 3}, {12, 3}, {12, 15}, {19, 15}, {19, 6}, {24, 6} },
        },
        waves = { count = 10 },
    },
    {
        id = "ethereal_ruins", faction = "twilight", order = 2,
        name = "Ethereal Ruins",
        description = "Roads from the north and south gates join in the old courtyard.",
        difficulty = 2, palette = "ruins",
        startGold = 260, lives = 20,
        paths = {
            { {1, 3}, {8, 3}, {8, 9}, {14, 9}, {14, 14}, {20, 14}, {20, 5}, {24, 5} },
            { {1, 15}, {5, 15}, {5, 9}, {8, 9}, {14, 9}, {14, 14}, {20, 14}, {20, 5}, {24, 5} },
        },
        rocks = { { 16, 2, 18, 8 } },
        waves = { count = 12, toughness = 1.7 },
    },
    {
        id = "nexus_of_balance", faction = "twilight", order = 3,
        name = "Nexus of Balance",
        description = "Enemies pour in from the west and from the north, and meet at the nexus.",
        difficulty = 3, palette = "nexus",
        startGold = 300, lives = 15,
        paths = {
            { {1, 3}, {7, 3}, {7, 9}, {3, 9}, {3, 15}, {13, 15}, {13, 11}, {18, 11}, {18, 16}, {24, 16} },
            { {16, 1}, {16, 4}, {22, 4}, {22, 8}, {13, 8}, {13, 11}, {18, 11}, {18, 16}, {24, 16} },
        },
        rocks = { { 8, 11, 11, 13 }, { 19, 12, 22, 14 } },
        waves = { count = 15 },
    },
}

-- Ground colors for generated maps: base grass/soil, speckle, road,
-- road edge, rock
Levels.palettes = {
    meadow  = { ground = { 0.36, 0.55, 0.27 }, speck = { 0.46, 0.66, 0.32 }, road = { 0.62, 0.50, 0.34 }, edge = { 0.45, 0.36, 0.24 }, rock = { 0.45, 0.45, 0.42 } },
    crystal = { ground = { 0.40, 0.55, 0.50 }, speck = { 0.60, 0.80, 0.85 }, road = { 0.72, 0.70, 0.66 }, edge = { 0.50, 0.50, 0.52 }, rock = { 0.55, 0.72, 0.85 } },
    citadel = { ground = { 0.50, 0.55, 0.40 }, speck = { 0.75, 0.70, 0.45 }, road = { 0.80, 0.75, 0.62 }, edge = { 0.60, 0.55, 0.42 }, rock = { 0.70, 0.68, 0.60 } },
    forest  = { ground = { 0.18, 0.26, 0.20 }, speck = { 0.26, 0.34, 0.22 }, road = { 0.38, 0.30, 0.24 }, edge = { 0.24, 0.18, 0.14 }, rock = { 0.30, 0.30, 0.30 } },
    cave    = { ground = { 0.24, 0.22, 0.24 }, speck = { 0.32, 0.28, 0.30 }, road = { 0.42, 0.36, 0.32 }, edge = { 0.28, 0.24, 0.22 }, rock = { 0.10, 0.09, 0.12 } },
    necro   = { ground = { 0.26, 0.24, 0.30 }, speck = { 0.34, 0.30, 0.40 }, road = { 0.46, 0.44, 0.48 }, edge = { 0.30, 0.28, 0.34 }, rock = { 0.18, 0.16, 0.22 } },
    mist    = { ground = { 0.34, 0.42, 0.40 }, speck = { 0.48, 0.55, 0.56 }, road = { 0.55, 0.50, 0.42 }, edge = { 0.40, 0.36, 0.30 }, rock = { 0.40, 0.42, 0.44 } },
    ruins   = { ground = { 0.52, 0.48, 0.36 }, speck = { 0.62, 0.58, 0.44 }, road = { 0.70, 0.66, 0.58 }, edge = { 0.50, 0.46, 0.40 }, rock = { 0.58, 0.55, 0.50 } },
    nexus   = { ground = { 0.30, 0.26, 0.38 }, speck = { 0.55, 0.48, 0.30 }, road = { 0.58, 0.52, 0.60 }, edge = { 0.40, 0.34, 0.44 }, rock = { 0.22, 0.18, 0.30 } },
}

return Levels
