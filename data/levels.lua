-- Level data: three levels per faction, played in order (finishing one
-- unlocks the next). Pure data, no functions or requires, so tools/artkit
-- can load it too. systems/level.lua builds the map from it and
-- systems/wave.lua builds the waves.
--
-- Map: the whole 1280 x 720 screen. Positions are in units of 40 px (a
-- 32 x 18 grid, fractions allowed), {0, 0} at the top left; a point just
-- outside (x -1 or 33, y -1 or 19) makes a road enter or leave at the edge.
--
-- paths: one or more roads, each a list of waypoints; the road runs
--   straight between them and its corners are rounded (systems/path.lua).
--   The string "portal" between two waypoints means enemies vanish at the
--   first and reappear at the second. Enemies take turns between paths.
--   Paths may share their last stretch (they merge); each runs to the end.
-- roadWidth: optional, pixels (default Levels.roadWidth).
-- zones: {x1, y1, x2, y2} rectangles where towers can be built, anywhere
--   inside (not on the road, not too close to another tower).
-- palette: ground colors for the generated map (systems/level.lua). A level
--   with a painted `plate` uses that image instead; the road is always drawn
--   over it from the path data.
-- waves: count, plus optional overrides of the curve in systems/wave.lua;
--   toughness scales enemy health on that level (tuned with
--   tests/run.sh balance).
-- startGold, lives: what the player starts with.
--
-- Levels.hud: screen boxes the in-game HUD covers ({x, y, w, h}, pixels).
-- Roads stay out of them (Level.validate) and towers cannot be built under
-- them. states/game.lua lays the HUD out in these boxes.

local Levels = {
    width = 1280, height = 720, unit = 40, roadWidth = 80,
    cols = 32, rows = 18,
    hud = {
        status = { 460, 6, 360, 40 },    -- lives, gold, wave
        controls = { 1004, 6, 270, 44 }, -- pause, speed, start wave
        hero = { 6, 630, 284, 84 },      -- hero card and abilities
        towers = { 1004, 630, 270, 84 }, -- tower buttons
    },
}

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
            { {-1, 1}, {10, 1}, {10, 7.5}, {18, 7.5}, {18, 2.5}, {23.5, 2.5}, {23.5, 11.5}, {8.5, 11.5}, {8.5, 16.5}, {23.5, 16.5} },
        },
        zones = {
            { 0, 3, 8, 8 }, { 11.5, 2, 16.5, 6 }, { 19.5, 4, 22, 10 }, { 25, 1, 31, 9 }, { 10, 13, 22, 15 }, { 2, 10, 7, 15 },
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
            { {-1, 2.5}, {11.5, 2.5}, {11.5, 8.5}, {16.5, 8.5}, {16.5, 14.5}, {26, 14.5}, {26, 9.5}, {33, 9.5} },
            { {-1, 14.5}, {6, 14.5}, {6, 8.5}, {11.5, 8.5}, {16.5, 8.5}, {16.5, 14.5}, {26, 14.5}, {26, 9.5}, {33, 9.5} },
        },
        zones = {
            { 1, 4, 10, 7 }, { 7.5, 10, 15, 16 }, { 13, 4, 20, 7 }, { 18, 10, 24.5, 13 }, { 27.5, 11, 32, 15.5 }, { 0, 9, 4.5, 13 },
        },
        waves = { count = 12, toughness = 1.1 },
    },
    {
        id = "celestial_citadel", faction = "radiant", order = 3,
        name = "Celestial Citadel",
        description = "The road spirals in to the citadel at the center. Long, but the waves are relentless.",
        difficulty = 3, palette = "citadel",
        startGold = 300, lives = 15,
        paths = {
            { {-1, 2.5}, {28.5, 2.5}, {28.5, 14.5}, {3.5, 14.5}, {3.5, 6.5}, {23.5, 6.5}, {23.5, 10.5}, {9, 10.5} },
        },
        zones = {
            { 5, 4, 27, 5 }, { 25, 4, 27, 13 }, { 5, 8, 22, 9 }, { 5, 12, 27, 13 }, { 30, 4, 32, 16 }, { 0, 4, 2, 13 },
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
            { {-1, 2.5}, {26, 2.5}, {26, 6.5}, {4.5, 6.5}, {4.5, 10.5}, {26, 10.5}, {26, 14.5}, {-1, 14.5} },
        },
        zones = {
            { 2, 4, 24.5, 5 }, { 6, 8, 24.5, 9 }, { 2, 12, 24.5, 13 }, { 27.5, 4, 31, 13 }, { 0, 7, 3, 10 },
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
            { {-1, 8.5}, {7.5, 8.5}, {7.5, 2.5}, {15.5, 2.5}, {15.5, 14.5}, {23.5, 14.5}, {23.5, 8.5}, {33, 8.5} },
        },
        zones = {
            { 9, 4, 14, 8 }, { 9, 10, 14, 15 }, { 17, 4, 22, 7 }, { 17, 9.5, 22, 13 }, { 1, 10, 6, 13 }, { 25, 10, 31, 13 },
        },
        waves = { count = 12, toughness = 1.0 },
    },
    {
        id = "necropolis", faction = "shadow", order = 3,
        name = "Necropolis",
        description = "A crypt maze. Enemies step through a portal into the far side of the city.",
        difficulty = 3, palette = "necro",
        startGold = 300, lives = 15,
        paths = {
            { {-1, 2.5}, {12.5, 2.5}, {12.5, 6.5}, {3.5, 6.5}, {3.5, 12.5}, "portal", {19.5, 3.5}, {27.5, 3.5}, {27.5, 9.5}, {19.5, 9.5}, {19.5, 14.5}, {33, 14.5} },
        },
        zones = {
            { 0, 4, 11, 5 }, { 5, 8, 11, 13 }, { 14, 1, 18, 8 }, { 21, 5, 26, 8 }, { 21, 11, 30, 13 }, { 29, 5, 32, 11 },
        },
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
            { {-1, 8.5}, {6, 8.5}, {6, 2.5}, {15.5, 2.5}, {15.5, 14.5}, {24.5, 14.5}, {24.5, 5.5}, {33, 5.5} },
        },
        zones = {
            { 0, 3, 4.5, 7 }, { 7.5, 4, 14, 13 }, { 17, 4, 23, 13 }, { 26, 7, 31, 12 }, { 1, 10, 6, 14 },
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
            { {-1, 2.5}, {10, 2.5}, {10, 8.5}, {18, 8.5}, {18, 13.5}, {26, 13.5}, {26, 4.5}, {33, 4.5} },
            { {-1, 14.5}, {6, 14.5}, {6, 8.5}, {10, 8.5}, {18, 8.5}, {18, 13.5}, {26, 13.5}, {26, 4.5}, {33, 4.5} },
        },
        zones = {
            { 1, 4, 8.5, 7 }, { 7.5, 10, 16.5, 15 }, { 11.5, 4, 24.5, 7 }, { 19.5, 9, 24.5, 12 }, { 27.5, 6, 32, 12 }, { 0, 9, 4.5, 13 },
        },
        waves = { count = 12, toughness = 1.35 },
    },
    {
        id = "nexus_of_balance", faction = "twilight", order = 3,
        name = "Nexus of Balance",
        description = "Enemies pour in from the west and from the north, and meet at the nexus.",
        difficulty = 3, palette = "nexus",
        startGold = 300, lives = 15,
        paths = {
            { {-1, 2.5}, {8.5, 2.5}, {8.5, 8.5}, {3.5, 8.5}, {3.5, 14.5}, {16.5, 14.5}, {16.5, 10.5}, {23.5, 10.5}, {23.5, 14.5}, {33, 14.5} },
            { {22, -1}, {22, 3.5}, {28.5, 3.5}, {28.5, 7.5}, {16.5, 7.5}, {16.5, 10.5}, {23.5, 10.5}, {23.5, 14.5}, {33, 14.5} },
        },
        zones = {
            { 0, 4, 7, 7 }, { 5, 10, 15, 13 }, { 10, 1, 20.5, 6 }, { 18, 11.5, 22, 13.5 }, { 25, 9, 32, 13 }, { 29.5, 4, 32, 8 },
        },
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
