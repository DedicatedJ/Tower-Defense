-- Art asset data. tools/artkit builds art/prompts.md from this file.
-- Edit here, then rebuild:  lovec tools/artkit <absolute repo root>
-- Rules followed (from the tower defense prompting guide):
--   say what the image is first, details second, style block last;
--   describe what to show, not what to avoid;
--   paint nothing that moves (cloth, flame, smoke, water are added in code);
--   one dominant color and one silhouette feature per enemy.

local A = {}

A.style = "Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, " ..
    "warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, " ..
    "grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; " ..
    "the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. " ..
    "Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos."

-- Settings shared by a group. draft/final are what to pick on Higgsfield.
A.settings = {
    tower = { model = "GPT Image 2.6", aspect = "1:1", background = "transparent",
              draft = "quality low, 1K", final = "quality high, 2K" },
    sheet = { model = "GPT Image 2.6", aspect = "3:4", background = "transparent",
              draft = "quality low, 1K", final = "quality high, 2K" },
    -- map_level1_v1 on GPT Image 2.6 ignored the road layout. Trying Nano
    -- Banana Pro next is a guess (it takes image references), not tested.
    map   = { model = "GPT Image 2.6; if it moves or bends the road, try Nano Banana Pro", aspect = "4:3", background = "opaque",
              draft = "quality low, 1K", final = "quality high, 2K (4K if offered)" },
    backdrop = { model = "GPT Image 2.6 or Nano Banana Pro", aspect = "4:3", background = "opaque",
              draft = "quality low, 1K", final = "quality high, 2K" },
    thumb = { model = "GPT Image 2.6", aspect = "4:3", background = "opaque",
              draft = "quality low, 1K", final = "quality medium, 1K" },
    icons = { model = "GPT Image 2.6", aspect = "16:9", background = "transparent",
              draft = "quality low, 1K", final = "quality high, 2K" },
    sfx   = { model = "Mirelo SFX (text to audio)", aspect = "-", background = "-",
              draft = "-", final = "duration as listed" },
}

------------------------------------------------------------------------
-- Towers. The first one is the master: approve it, then attach it as
-- image 1 for every other tower so the base and scale match.
------------------------------------------------------------------------
A.towerTemplate = "A single %s for a tower defense game, alone and centered on a transparent background, " ..
    "top-down three-quarter view. %s It stands on a square grey stone base that fills the lower third. " ..
    "The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people."

A.towerRedo = "Image 1 is an approved tower from the same set. Draw a different tower in the same set: " ..
    "keep exactly the square stone base, its size and shape, the camera angle, the scale, the light and the " ..
    "painting style. Change only the tower above the base. "

A.towers = {
    { id = "tower_archer", file = "sprites/towers/archer.png", master = true,
      name = "archer tower",
      desc = "A round tower of fitted grey stone topped by a wooden lookout platform with a ring of " ..
             "pointed wooden stakes along its edge and a bare wooden flagpole with a gold finial." },
    { id = "tower_cannon", file = "sprites/towers/cannon.png",
      name = "cannon tower",
      desc = "A squat square stone bastion with thick crenellated walls and one short black iron mortar " ..
             "on top pointing straight up, gold bands around its muzzle." },
    { id = "tower_magic", file = "sprites/towers/magic.png",
      name = "mage tower",
      desc = "A slender tower of pale stone with smooth carved bands, open at the top, where one large " ..
             "violet crystal floats upright above the rim." },
    { id = "tower_frost", file = "sprites/towers/frost.png",
      name = "frost tower",
      desc = "A tower of blue-grey stone whose crown is a cluster of tall pale ice-blue crystals, with " ..
             "frost on the upper stones." },
    { id = "tower_crossbow", file = "sprites/towers/crossbow.png",
      name = "crossbow tower",
      desc = "A sturdy tower of dark timber over stone, bound with iron straps, with a roofed firing deck " ..
             "on top and narrow firing slits on all four sides." },
    { id = "tower_bombard", file = "sprites/towers/bombard.png",
      name = "bombard tower",
      desc = "A low, wide round drum tower of stone wrapped in iron bands, with one fat iron mortar on top " ..
             "pointing straight up and a small stack of round iron bombs beside it." },
}

------------------------------------------------------------------------
-- Enemy walk sheets. 4 rows (toward camera, right, left, away) x
-- 3 columns (left foot forward, standing, right foot forward).
-- The first one is the master and uses the gray pose guide; every other
-- sheet is a redo of the approved master.
------------------------------------------------------------------------
A.sheetMaster = "Scene: A character walk sheet for a 2D game: twelve full-body drawings of the same %s " ..
    "in a grid of 4 rows and 3 columns on a transparent background, laid out exactly as in image 1. " ..
    "Image 1 is the pose and layout guide: twelve gray mannequins. Replace each mannequin with the %s, " ..
    "in the same cell, the same pose, the same facing and the same size.\n\n" ..
    "Layout: Row 1 walks toward the camera. Row 2 walks right. Row 3 walks left. Row 4 walks away, seen " ..
    "from behind. Each row is left foot forward, standing still, right foot forward. Big, obvious strides " ..
    "with arms swinging. One figure per cell, centered, every foot in a row on one line, wide clear space " ..
    "between figures. The same %s, the same gear and the same height in all twelve.\n\n" ..
    "Character: %s\n\nGear: %s Plain surfaces throughout.\n\n" ..
    "Details: Drawn from slightly above, to match a top-down three-quarter game map. Large head, compact " ..
    "body. Transparent background, with empty space under the feet."

A.sheetRedo = "Scene: Image 1 is an approved walk sheet. Redraw the whole sheet as a different %s. " ..
    "Keep exactly: the grid, the place of every figure, every pose and facing, the camera, the height of " ..
    "the figures, the proportions, the painting style and the transparent background. Change only the " ..
    "creature and its gear.\n\nCharacter: %s\n\nGear: %s Plain surfaces throughout.\n\nNot carried over: %s"

A.enemies = {
    { id = "enemy_zombie", file = "sprites/enemies/zombie.png", master = true,
      name = "zombie",
      character = "A hunched, shambling zombie with sickly green skin, sunken dark eyes and thin limbs. " ..
                  "One dominant color: sickly green.",
      gear = "A ragged brown hooded tunic with a torn hem and bare green feet." },
    { id = "enemy_skeleton", file = "sprites/enemies/skeleton.png",
      name = "skeleton warrior",
      character = "An upright skeleton with bone-white bones and a grinning skull. One dominant color: bone white.",
      gear = "A small round wooden shield on its left forearm and a rusted short sword in its right hand. No armor.",
      notCarried = "No hood, no tunic, no green skin. The skull is bare." },
    { id = "enemy_orc", file = "sprites/enemies/orc.png",
      name = "orc brute",
      character = "A broad, heavy orc with rust-red skin, small tusks and a thick neck, taller and wider in " ..
                  "the shoulders than the zombie. One dominant color: rust red.",
      gear = "A dented iron helmet with two short horns, a leather kilt and a heavy wooden club in its right hand.",
      notCarried = "No hood, no tunic. Skin is rust red, not green." },
    { id = "enemy_necromancer", file = "sprites/enemies/necromancer.png",
      name = "necromancer",
      character = "A gaunt pale figure whose face is in deep shadow under a tall pointed hood. " ..
                  "One dominant color: violet.",
      gear = "A long violet robe that reaches the ankles with a bone-white trim, and a tall dark staff in its " ..
             "right hand topped with a pale green orb.",
      notCarried = "No green skin, no torn hem. The hood is tall and pointed and the robe is whole." },
    { id = "enemy_dragon", file = "sprites/enemies/dragon.png",
      name = "young dragon flying",
      character = "A young dragon with ember-orange scales, a cream belly, two short horns and a long tail, " ..
                  "flying with its wings spread. In each row the three frames are wings raised, wings level, " ..
                  "wings lowered, instead of footsteps. It hovers with empty space below it and no feet on a line. " ..
                  "One dominant color: ember orange.",
      gear = "No gear.",
      notCarried = "No hood, no clothing, no human body. It is a four-legged winged dragon." },
}

------------------------------------------------------------------------
-- Map plate for level 1 (ground only; towers and units are sprites).
------------------------------------------------------------------------
A.map = {
    id = "map_level1", file = "sprites/maps/level1.png", guide = "art/guides/map_level1_blockout.png",
    -- v2 wording: a repaint of image 1 rather than "follow the layout", which
    -- v1 ignored (it drew its own serpentine road). Turn count is checkable.
    prompt = "Scene: Repaint image 1 as a finished painted map for a tower defense game, seen from directly " ..
        "above. Image 1 is a gray layout: the dark gray band is the road and the light gray is grass. Keep " ..
        "the road exactly where the dark band is: the same path, the same width, the same square corners, in " ..
        "the same places across the whole image. Do not add, move, straighten, widen or smooth any part of it.\n\n" ..
        "Road: packed brown earth. Any stone edging lies inside the dark band, so the road with its edging is " ..
        "no wider than the band. The road runs along the very top edge from the top left corner and has " ..
        "exactly eight right-angle turns. Its far end is the short stretch in the lower part of the image, " ..
        "right of center, where a small ruined stone gate stands across the road.\n\n" ..
        "Ground: open, flat mossy grass, even and uncluttered so a tower can stand on any patch of it, with " ..
        "small rocks, wildflowers and short tufts only. No trees, no buildings, no towers, no units, no " ..
        "animals, no smoke, no flags.",
}

------------------------------------------------------------------------
-- Map plates for the other levels (data/levels.lua). Same rules as level 1:
-- a repaint of the gray layout, road exactly where the gray band is.
--
-- tools/artcut mapcheck / mapfix find the painted road by its color: warm
-- earth (clearly redder than green, well above blue). So every road below
-- is a warm brown, tan or sandstone, and no open ground is brown, tan or
-- golden. A grey or violet road could not be lined up.
--
-- %s = how the roads run (written by tools/artkit from the level data),
-- %s = ground, %s = road surface, %s = rock sentence.
------------------------------------------------------------------------
A.mapStyle = "Painterly 2D game art in a clean hand-painted style, seen from directly above, warm light " ..
    "from the upper left. Muted natural palette with warm gold accents, crisp edges, readable at small size. " ..
    "No text, no logos."

A.levelMapTemplate = "Scene: Repaint image 1 as a finished painted map for a tower defense game, seen from " ..
    "directly above. Image 1 is a gray layout: the mid gray band is the road and the light gray is open " ..
    "ground. Keep the road exactly where the gray band is: the same path, the same width, the same square " ..
    "corners, in the same places across the whole image. Do not add, move, straighten, widen or smooth any " ..
    "part of it. %s\n\n" ..
    "Ground: %s.\n\n" ..
    "Road: %s. It is clearly warmer and browner than the ground around it. Any edging lies inside the band, " ..
    "so the road with its edging is no wider than the band.\n\n" ..
    "%s\n\n" ..
    "Open ground stays flat and even so a tower can stand on any patch of it, with small detail only. No " ..
    "trees, buildings, towers, units, animals or text anywhere on the map."

A.noRocks = "Every part of the layout that is not road is open ground."

-- ground, road, rock (rock = what fills the near-black areas, if any)
A.levelMaps = {
    crystal_spires = {
        ground = "a high plateau of short pale green grass with small clusters of blue crystal shards",
        road = "warm tan packed earth",
        rock = "tall jagged outcrops of pale blue crystal" },
    celestial_citadel = {
        ground = "the trimmed green lawn of a white stone citadel garden, with small white flowers",
        road = "warm honey-colored sandstone flagstones" },
    haunted_forest = {
        ground = "a dark mossy forest floor in deep green and grey-green, scattered with dead twigs and small grey stones",
        road = "a muddy brown dirt trail" },
    obsidian_caves = {
        ground = "a cave floor of dark grey ash and gravel with small glints of black obsidian",
        road = "rust-brown packed earth worn smooth",
        rock = "solid black obsidian rock with sharp glassy edges" },
    necropolis = {
        ground = "grey-violet cobblestones between low grave slabs set flat into the ground",
        road = "worn rust-brown paving stones",
        rock = "the walls and roofs of a stone crypt seen from above, in dark slate" },
    misty_borderlands = {
        ground = "a misty marsh border of blue-green grass with a few small shallow pools",
        road = "a raised brown dirt causeway" },
    ethereal_ruins = {
        ground = "green grass scattered with small pale grey ruin stones",
        road = "warm cracked sandstone paving",
        rock = "a collapsed wall of large pale grey stone blocks and rubble" },
    nexus_of_balance = {
        ground = "a twilight plain of blue-violet grass, slightly lighter toward the center",
        road = "warm amber packed earth",
        rock = "a ring of tall dark standing stones" },
}

------------------------------------------------------------------------
-- Screen backdrops (UI is drawn over the middle, so keep it calm).
------------------------------------------------------------------------
A.backdropTemplate = "A wide painted backdrop for a game menu screen, %s. The center of the image is calm " ..
    "and slightly darker so menu panels can sit over it; detail is at the edges. Evening light with mist. " ..
    "No people, no text."

A.backdrops = {
    { id = "bg_hub", file = "assets/backgrounds/hub_background.png",
      scene = "the inner courtyard of a fortified border keep at dusk, stone walls, braziers and stacked supply crates" },
    { id = "bg_level_select", file = "assets/backgrounds/level_select.png",
      scene = "seen from above, a weathered campaign map spread on a heavy wooden table, its land drawn as " ..
              "painted hills, forests and roads with no writing on it, held flat by a dagger and a candle stub" },
    { id = "bg_shop", file = "assets/backgrounds/shop.png",
      scene = "the interior of a quartermaster's armory with shelves of potions, crossbow bolts and shields " ..
              "lit by a warm lantern" },
    { id = "bg_tower_upgrade", file = "assets/backgrounds/tower_upgrade.png",
      scene = "a stonemason's workshop with small carved tower models on a workbench, chisels and blueprint " ..
              "sheets showing only drawn lines" },
    { id = "bg_pause", file = "assets/backgrounds/pause.png",
      scene = "a quiet night view from castle battlements over a misty valley, cold blue moonlight" },
}

------------------------------------------------------------------------
-- Level thumbnails (one image each; shown on 220 px wide cards).
------------------------------------------------------------------------
A.thumbTemplate = "A small painted preview of a tower defense battlefield, top-down three-quarter view: %s, " ..
    "with a winding road crossing it. Strong simple shapes that read at small size. No people, no text."

A.thumbs = {
    { id = "thumb_training_grounds", file = "assets/levels/training_grounds_thumb.png",
      scene = "a tidy training field with straw targets and a fenced dirt road" },
    { id = "thumb_wilderness", file = "assets/levels/wilderness_thumb.png",
      scene = "rolling green wilderness with scattered rocks and a stream" },
    { id = "thumb_ancient_ruins", file = "assets/levels/ancient_ruins_thumb.png",
      scene = "crumbling grey stone ruins and broken columns overgrown with moss" },
    { id = "thumb_sunlit_meadows", file = "assets/levels/sunlit_meadows_thumb.png",
      scene = "bright golden meadows with several forking roads" },
    { id = "thumb_crystal_spires", file = "assets/levels/crystal_spires_thumb.png",
      scene = "raised rock plateaus crowned with pale crystals, joined by wooden bridges" },
    { id = "thumb_celestial_citadel", file = "assets/levels/celestial_citadel_thumb.png",
      scene = "a round white-stone citadel at the center of a ring road under a gold sky" },
    { id = "thumb_haunted_forest", file = "assets/levels/haunted_forest_thumb.png",
      scene = "a dark twisted forest with a narrow winding road and pale green fog" },
    { id = "thumb_obsidian_caves", file = "assets/levels/obsidian_caves_thumb.png",
      scene = "black glassy cave tunnels lit by thin orange lava seams" },
    { id = "thumb_necropolis", file = "assets/levels/necropolis_thumb.png",
      scene = "a maze of tombs and mausoleums with two glowing violet portal arches" },
    { id = "thumb_misty_borderlands", file = "assets/levels/misty_borderlands_thumb.png",
      scene = "grey moorland half hidden by drifting banks of fog" },
    { id = "thumb_ethereal_ruins", file = "assets/levels/ethereal_ruins_thumb.png",
      scene = "pale floating stone ruins with broken walls over a soft blue glow" },
    { id = "thumb_nexus_of_balance", file = "assets/levels/nexus_of_balance_thumb.png",
      scene = "ground split into a sunlit half and a shadowed violet half, meeting at a stone circle" },
}

------------------------------------------------------------------------
-- Achievement icons: one sheet, 8 icons, box guide as image 1.
------------------------------------------------------------------------
A.icons = {
    id = "icons_achievements", guide = "art/guides/icon_sheet_8_guide.png",
    folder = "sprites/ui/achievements/",
    items = {
        { "first_tower", "one small stone tower" },
        { "tower_master", "exactly three small stone towers side by side" },
        { "wave_survivor", "a battered round shield with a crack across it" },
        { "hero_legend", "a gold crown resting on a laurel wreath" },
        { "resource_king", "a tidy stack of gold bars" },
        { "perfect_wave", "an unbroken round shield with a gold star on its face" },
        { "tower_synergy", "two small stone towers joined by a gold beam of light" },
        { "faction_master", "three crossed swords, gold, silver and violet" },
    },
    prompt = "Scene: An icon sheet of exactly 8 separate game icons on a transparent background, laid out as " ..
        "in image 1. Image 1 is the layout guide: 8 empty boxes in two rows of four. Put one icon in each box, " ..
        "centered, with clear space around it. Every icon sits on the same round bronze medallion with a thin " ..
        "gold rim, front-facing, all the same size. No ground under them and no shadows.\n\n" ..
        "Icons, left to right, top row then bottom: %s.",
}

------------------------------------------------------------------------
-- Sound effects (Mirelo SFX). Short, dry, no music.
------------------------------------------------------------------------
-- Game sounds (systems/audio.lua plays the event sounds; tower shots play by the
-- tower's projectileType in data/factions.lua). Already in sounds/sfx and
-- not listed: button_click, enemy_die, enemy_hit, game_over, shot_basic,
-- shot_cannon, shot_magic, shot_sniper (the bolt shot), tower_place,
-- tower_sell, tower_upgrade, victory, wave_start.
A.sfx = {
    { id = "sfx_player_damage", file = "sounds/sfx/player_damage.wav", dur = 1,
      prompt = "a heavy wooden gate being struck once, a dull thud with a short creak" },
    { id = "sfx_hero_ability", file = "sounds/sfx/hero_ability.wav", dur = 2,
      prompt = "a bright magical whoosh rising into a short shimmering chime" },
    { id = "sfx_purchase", file = "sounds/sfx/purchase.wav", dur = 1,
      prompt = "a few gold coins dropped into a leather pouch, short and crisp" },
    { id = "sfx_level_up", file = "sounds/sfx/level_up.wav", dur = 2,
      prompt = "a short triumphant rising harp glissando ending on a bell" },
    { id = "sfx_shot_holy", file = "sounds/sfx/shot_holy.wav", dur = 1,
      prompt = "a single soft bright chime with a quick airy swish, like a beam of light" },
    { id = "sfx_shot_fire", file = "sounds/sfx/shot_fire.wav", dur = 1,
      prompt = "a quick whoosh of a fireball launching, with a short crackle" },
    { id = "sfx_shot_poison", file = "sounds/sfx/shot_poison.wav", dur = 1,
      prompt = "a short wet hiss and a bubbling splash, like a glob of acid" },
    { id = "sfx_shot_void", file = "sounds/sfx/shot_void.wav", dur = 1,
      prompt = "a short deep warbling hum that drops in pitch, dark and hollow" },
    { id = "sfx_shot_soul", file = "sounds/sfx/shot_soul.wav", dur = 1,
      prompt = "a short ghostly whispering whoosh with a faint eerie tone, no words" },
    { id = "sfx_shot_hybrid", file = "sounds/sfx/shot_hybrid.wav", dur = 1,
      prompt = "a quick shimmer that is half a high bright chime and half a low dark hum, together" },
    { id = "sfx_shot_frost", file = "sounds/sfx/shot_frost.wav", dur = 1,
      prompt = "a quick icy crystalline shatter and hiss" },
}

------------------------------------------------------------------------
-- Faction Model C (data/factions.lua). Towers attach the approved
-- tower_archer final as image 1 (same plinth, scale, light); hero sheets
-- attach the approved enemy_zombie sheet as image 1 (same grid, poses,
-- size). When a file is cut in, point that tower's `sprite` in
-- data/factions.lua at sprites/towers/<id>.png.
------------------------------------------------------------------------
A.cTowers = {
    { id = "tower_holy_bastion", file = "sprites/towers/holy_bastion.png", name = "healing shrine tower",
      desc = "A round tower of white stone with gold trim, topped by an open gold-domed shrine holding a softly glowing pale gold orb." },
    { id = "tower_seraphim_altar", file = "sprites/towers/seraphim_altar.png", name = "holy fire altar tower",
      desc = "A square stone tower topped by a gold altar bowl holding a tall steady white-gold flame, with two small carved stone wings at its sides." },
    { id = "tower_seraphs_watch", file = "sprites/towers/seraphs_watch.png", name = "tall sniper watchtower",
      desc = "A tall slender white stone spire with a gold-roofed lookout at the very top and a long gold crossbow mounted pointing straight forward." },
    { id = "tower_cursed_spire", file = "sprites/towers/cursed_spire.png", name = "cursed poison spire",
      desc = "A narrow black stone spire with cracked surfaces, sickly green crystals set into its sides and a hollow top holding still pale green mist." },
    { id = "tower_oblivion_engine", file = "sprites/towers/oblivion_engine.png", name = "necromantic summoning tower",
      desc = "A dark violet stone tower ringed with bone ribs, a round summoning circle carved on its flat top, and a violet crystal floating above it." },
    { id = "tower_soul_forge", file = "sprites/towers/soul_forge.png", name = "soul forge tower",
      desc = "A squat dark iron forge tower with a glowing teal furnace mouth on its front, a short chimney, and chains hanging from iron hooks." },
    { id = "tower_dawn_dusk_nexus", file = "sprites/towers/dawn_dusk_nexus.png", name = "dawn and dusk tower",
      desc = "A round tower split down the middle: the left half pale stone with gold trim, the right half dark slate with silver trim, topped by an orb that is half gold and half deep blue." },
    { id = "tower_eclipse_monolith", file = "sprites/towers/eclipse_monolith.png", name = "eclipse monolith",
      desc = "A tall black obsidian monolith with a ring-shaped opening near its top, and a dark disc with a thin bright rim floating inside the ring." },
    { id = "tower_elemental_nexus", file = "sprites/towers/elemental_nexus.png", name = "fire and ice tower",
      desc = "A round tower of blue-grey stone crowned with two crystals side by side: one ember orange, one ice blue." },
}

-- Hero sheets follow each hero's portrait (assets/hero images/...), so the
-- figure on the road is recognisably the same person. Galahad and Michael
-- are both radiant: Galahad is blond in white plate, Michael dark-haired in
-- gold plate with wings, so they stay apart at sprite size.
A.cHeroes = {
    { id = "hero_sir_galahad", file = "sprites/heroes/sir_galahad.png", name = "holy knight",
      character = "A young man with short spiky blond hair. One dominant color: white with gold trim.",
      gear = "White plate armor with gold edges and a gold sun emblem on the chest, large gold feathered shoulder guards, a long white cape lined with blue, and a longsword with a gold hilt in his right hand.",
      notCarried = "No hood, no green skin, no torn clothing, no wings. He is a healthy human man." },
    { id = "hero_lady_celestia", file = "sprites/heroes/lady_celestia.png", name = "priestess",
      character = "A tall woman with very long flowing silver-white hair. One dominant color: white with gold trim.",
      gear = "A long white gown with gold embroidery, gold shoulder armor, white gloves, a light blue cape, and a tall gold staff topped with a ring around a glowing orb in her right hand.",
      notCarried = "No hood, no green skin, no torn clothing. She is a healthy human woman." },
    { id = "hero_archangel_michael", file = "sprites/heroes/archangel_michael.png", name = "archangel",
      character = "A tall man with long dark brown hair and very large white feathered wings folded behind him. One dominant color: gold.",
      gear = "Gleaming gold plate armor over a white tunic, a gold longbow in his left hand and a quiver on his back between the wings.",
      notCarried = "No hood, no green skin, no torn clothing." },
    { id = "hero_malachi", file = "sprites/heroes/malachi.png", name = "necromancer lord",
      character = "A pale gaunt man with straight shoulder-length white hair. One dominant color: dark blue with blood red accents.",
      gear = "A long dark blue robe with a few thin red lines, black spiked shoulder armor set with red gems, a skull clasp on the chest, a black cape, and a staff topped with a skull holding a red crystal in his right hand.",
      notCarried = "No green skin, no torn clothing, no hood." },
    { id = "hero_morgana", file = "sprites/heroes/morgana.png", name = "dark sorceress",
      character = "A slim woman with long straight black hair. One dominant color: black with silver.",
      gear = "A long black high-collared robe and cape with silver edges and three small white skull ornaments down the front, white gloves, and a tall gold staff with a ring top in her right hand.",
      notCarried = "No green skin, no torn clothing, no hood." },
    { id = "hero_dark_lord_malak", file = "sprites/heroes/dark_lord_malak.png", name = "dark warlord",
      character = "A towering armored warlord with glowing violet eyes behind a horned helm. One dominant color: black with violet.",
      gear = "Spiked black plate armor, a black cape, a large two-handed black greatsword held in both hands.",
      notCarried = "No green skin, no hood." },
    { id = "hero_zephyr", file = "sprites/heroes/zephyr.png", name = "knight duelist",
      character = "A lean young man with short messy black hair. One dominant color: silver steel with crimson.",
      gear = "Engraved silver plate armor over a crimson tunic and crimson sash, a long white cape, and one long straight silver sword in his right hand.",
      notCarried = "No green skin, no torn clothing, no hood." },
    { id = "hero_lyra", file = "sprites/heroes/lyra.png", name = "star mage",
      character = "A young woman with short straight silver-white hair. One dominant color: deep navy blue with gold.",
      gear = "A long deep navy robe and cape with a few large silver moons and gold stars, gold edges, white gloves, and a tall gold staff with a ring top in her right hand.",
      notCarried = "No green skin, no torn clothing, no hood." },
    { id = "hero_elemental_sage", file = "sprites/heroes/elemental_sage.png", name = "elemental sage",
      character = "An old man with a long white beard. One dominant color: half orange, half ice blue.",
      gear = "A long robe whose left half is ember orange and right half is ice blue, and a staff topped with one orange and one blue crystal.",
      notCarried = "No green skin, no torn clothing, no hood." },
}

-- The existing portraits are clean-lined, cel-shaded anime-style paintings,
-- cropped from the thighs up, head near the top center (Unit.portrait crops
-- the face from there), a bright sky with clouds and a distant stone tower.
A.portraitTemplate = "A character portrait in exactly the same art style, line work, coloring, framing and " ..
    "light as image 1 (an approved portrait from the same set), but a different person: %s Shown from the " ..
    "thighs up, facing the viewer, with the head near the top center of the frame as in image 1. Behind: %s, " ..
    "painted the same way as the background of image 1. Do not copy the person, armor or weapon from " ..
    "image 1. No text, no logos, no watermark."

A.portraits = {
    { id = "portrait_archangel_michael", file = "assets/hero images/radiant order/Michael/Archangel Michael.jpg",
      desc = "an archangel with long dark brown hair, very large white feathered wings spread behind him, gleaming gold plate armor over a white tunic, holding a gold longbow.",
      bg = "a bright sky with soft clouds and a distant white stone tower" },
    { id = "portrait_dark_lord_malak", file = "assets/hero images/shadow covenant/Malak/Dark Lord Malak.jpg",
      desc = "a towering warlord in spiked black plate armor and a horned helm with glowing violet eyes, a black greatsword resting on his shoulder.",
      bg = "a dusk violet sky over dark mountains" },
    { id = "portrait_elemental_sage", file = "assets/hero images/twilight balance/Sage/Elemental Sage.jpg",
      desc = "an old sage with a long white beard in a robe that is half ember orange and half ice blue, holding a staff topped with one orange and one blue crystal.",
      bg = "a bright sky with soft clouds over distant green hills" },
}

return A
