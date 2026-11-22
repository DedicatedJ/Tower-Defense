-- Faction data: the single source for factions, towers and heroes.
-- Pure data, no functions: systems/tower.lua, systems/unit.lua and
-- systems/effects.lua give it behavior. Content is "Model C" (formerly
-- the unused systems/faction.lua); notes mark where an effect had to be
-- reinterpreted to do something in this game.
--
-- Units of measure: range/radius in pixels (map tiles are 32 px),
-- fireRate and attackRate in attacks per second, durations in seconds,
-- dps in damage per second, armor as the fraction of damage blocked.
--
-- Effect types are documented in systems/effects.lua. Ability targets:
--   enemies  enemies within radius of the hero
--   enemy    the strongest enemy within the hero's range
--   allies   allied units within radius (includes the hero)
--   area     enemies and allies within radius; each effect says `on`
--   towers   towers within radius
--   self     the hero only
--   point    a spot on the road (teleport)

local Factions = {}

------------------------------------------------------------------------
-- Radiant Order
------------------------------------------------------------------------
Factions.radiant = {
    id = "radiant",
    order = 1,
    name = "Radiant Order",
    description = "Holy warriors who shield and heal their own and burn the undead.",
    color = { 1, 0.85, 0.4 },
    bonus = { towerDamage = 0.10, heroHealing = 0.05 },
    bonusText = "+10% tower damage, +5% hero healing",
    towers = {
        {
            id = "holy_bastion",
            name = "Holy Bastion",
            description = "Heals your units in range and strikes nearby enemies.",
            cost = 100, damage = 20, fireRate = 1.0, range = 150,
            projectileType = "holy",
            sprite = "sprites/towers/archer.png",
            heal = { amount = 5, interval = 1 },
            upgrades = {
                { name = "Divine Light", description = "Heal amount +50%", cost = 150,
                  mods = { { stat = "healAmount", mult = 1.5 } } },
                { name = "Blessed Aura", description = "Range +50% (heals and attacks)", cost = 200,
                  mods = { { stat = "range", mult = 1.5 } } },
            },
        },
        {
            id = "seraphim_altar",
            name = "Seraphim Altar",
            description = "Holy fire that keeps burning after the hit.",
            cost = 200, damage = 45, fireRate = 0.8, range = 180,
            projectileType = "fire",
            sprite = "sprites/towers/cannon.png",
            onHit = { { type = "burn", dps = 10, duration = 3 } },
            upgrades = {
                { name = "Divine Flame", description = "Burn damage +50%", cost = 300,
                  mods = { { stat = "burnDps", mult = 1.5 } } },
                { name = "Holy Inferno", description = "Burn lasts 50% longer", cost = 250,
                  mods = { { stat = "burnDuration", mult = 1.5 } } },
            },
        },
        {
            id = "seraphs_watch",
            name = "Seraph's Watch",
            description = "Long-range sniper with a chance to crit for double damage.",
            cost = 300, damage = 80, fireRate = 0.5, range = 300,
            projectileType = "bolt",
            sprite = "sprites/towers/crossbow.png",
            critChance = 0.2, critMult = 2,
            upgrades = {
                { name = "Divine Mark", description = "Hits mark enemies: they take 50% more damage for 3 s", cost = 400,
                  mods = { { stat = "markMult", set = 1.5 } } },
                { name = "Holy Precision", description = "Every shot is a critical hit", cost = 450,
                  mods = { { stat = "critChance", set = 1 } } },
            },
        },
    },
    heroes = {
        {
            id = "sir_galahad",
            name = "Sir Galahad",
            role = "tank",
            description = "Tank and protector. Holds the road against several enemies at once.",
            portrait = "assets/hero images/radiant order/Galahad/Sir Galahad.jpg",
            stats = { health = 600, damage = 20, attackRate = 1.0, range = 40, speed = 60, armor = 0.3, blockCount = 3 },
            abilities = {
                { name = "Aegis of Dawn", description = "Allies nearby take 50% less damage for 5 s",
                  cooldown = 15, target = "allies", radius = 150,
                  effects = { { type = "damageReduction", amount = 0.5, duration = 5 } } },
                { name = "Divine Shield", description = "Allies nearby are invulnerable for 3 s",
                  cooldown = 20, target = "allies", radius = 150,
                  effects = { { type = "invulnerable", duration = 3 } } },
                { name = "Holy Light", description = "Heals allies nearby by 50 and adds 20% damage for 4 s",
                  cooldown = 25, target = "allies", radius = 150,
                  effects = { { type = "heal", amount = 50 }, { type = "damageBoost", amount = 0.2, duration = 4 } } },
            },
            -- Model C: "+20% tower armor". Towers are never attacked here,
            -- so the armor goes to your units instead.
            passive = { name = "Tower Armor", description = "Your units have 20% more armor",
                        kind = "allyArmor", mult = 1.2 },
        },
        {
            id = "lady_celestia",
            name = "Lady Celestia",
            role = "healer",
            description = "Healer who burns enemies while restoring allies.",
            portrait = "assets/hero images/radiant order/Celestia/Lady Celestia.jpg",
            stats = { health = 350, damage = 18, attackRate = 1.0, range = 140, speed = 60, armor = 0.1, blockCount = 1 },
            abilities = {
                { name = "Purifying Conflagration", description = "Burns enemies nearby (30/s for 5 s) and heals allies by 100",
                  cooldown = 20, target = "area", radius = 140,
                  effects = { { type = "burn", dps = 30, duration = 5, on = "enemy" },
                              { type = "heal", amount = 100, on = "ally" } } },
                { name = "Radiant Burst", description = "40 damage to enemies nearby, heals allies by 30",
                  cooldown = 15, target = "area", radius = 140,
                  effects = { { type = "damage", amount = 40, on = "enemy" },
                              { type = "heal", amount = 30, on = "ally" } } },
                { name = "Light's Blessing", description = "Healing on allies nearby is 50% stronger for 8 s",
                  cooldown = 30, target = "allies", radius = 160,
                  effects = { { type = "healingBoost", amount = 0.5, duration = 8 } } },
            },
            passive = { name = "Holy Healing", description = "Holy Bastions heal 15% more",
                        kind = "towerStat", tower = "holy_bastion", stat = "healAmount", mult = 1.15 },
        },
        {
            id = "archangel_michael",
            name = "Archangel Michael",
            role = "dps",
            description = "Ranged damage dealer with a devastating single-target strike.",
            stats = { health = 380, damage = 30, attackRate = 1.2, range = 150, speed = 70, armor = 0.1, blockCount = 1 },
            abilities = {
                { name = "Divine Judgment", description = "200 damage to the strongest enemy in range",
                  cooldown = 25, target = "enemy",
                  effects = { { type = "damage", amount = 200 } } },
                -- Model C: "temporary flight and speed boost". No terrain to
                -- fly over, so it is a speed and attack-rate boost.
                { name = "Wings of Light", description = "Moves and attacks 50% faster for 8 s",
                  cooldown = 20, target = "self",
                  effects = { { type = "haste", amount = 0.5, duration = 8 } } },
                { name = "Holy Shield", description = "Allies nearby reflect 30% of damage taken for 6 s",
                  cooldown = 30, target = "allies", radius = 150,
                  effects = { { type = "reflect", amount = 0.3, duration = 6 } } },
            },
            passive = { name = "Critical Strike", description = "15% chance to deal double damage",
                        kind = "heroCrit", chance = 0.15, mult = 2 },
        },
    },
}

------------------------------------------------------------------------
-- Shadow Covenant
------------------------------------------------------------------------
Factions.shadow = {
    id = "shadow",
    order = 2,
    name = "Shadow Covenant",
    description = "Necromancers who poison, bind and raise the fallen to fight for them.",
    color = { 0.6, 0.4, 0.9 },
    bonus = { poisonDamage = 0.15, minionHealth = 0.10 },
    bonusText = "+15% poison damage, +10% minion health",
    towers = {
        {
            id = "cursed_spire",
            name = "Cursed Spire",
            description = "Poisons what it hits.",
            cost = 100, damage = 18, fireRate = 1.0, range = 160,
            projectileType = "poison",
            sprite = "sprites/towers/cursed_spire.png",
            onHit = { { type = "poison", dps = 3, duration = 3 } },
            upgrades = {
                { name = "Venomous", description = "Poison damage +50%", cost = 150,
                  mods = { { stat = "poisonDps", mult = 1.5 } } },
                { name = "Plague", description = "Poison lasts 50% longer", cost = 200,
                  mods = { { stat = "poisonDuration", mult = 1.5 } } },
            },
        },
        {
            id = "oblivion_engine",
            name = "Oblivion Engine",
            description = "Raises a skeleton minion on the road every 20 s.",
            cost = 200, damage = 50, fireRate = 0.7, range = 200,
            projectileType = "void",
            sprite = "sprites/towers/magic.png",
            summon = { interval = 20, max = 1,
                       minion = { sheet = "skeleton", tint = { 0.75, 0.6, 1 }, health = 120, damage = 10,
                                  attackRate = 1, speed = 50, armor = 0.1 } },
            upgrades = {
                { name = "Soul Harvester", description = "Minions arrive 30% sooner", cost = 300,
                  mods = { { stat = "summonInterval", mult = 0.7 } } },
                { name = "Necromancer", description = "One more minion at a time", cost = 250,
                  mods = { { stat = "summonMax", add = 1 } } },
            },
        },
        {
            id = "soul_forge",
            name = "Soul Forge",
            description = "Enemies that die in range may rise as your minions for 20 s.",
            cost = 300, damage = 60, fireRate = 0.8, range = 140,
            projectileType = "soul",
            sprite = "sprites/towers/bombard.png",
            convert = { chance = 0.2,
                        minion = { tint = { 0.6, 1, 0.75 }, health = 50, damage = 10, attackRate = 1,
                                   speed = 60, armor = 0, duration = 20 } },
            upgrades = {
                { name = "Soul Harvest", description = "Rise chance +50%", cost = 400,
                  mods = { { stat = "convertChance", mult = 1.5 } } },
                { name = "Necrotic Aura", description = "Deals 10 damage per second to enemies within 100 px", cost = 450,
                  mods = { { stat = "auraDps", set = 10 }, { stat = "auraRange", set = 100 } } },
            },
        },
    },
    heroes = {
        {
            id = "malachi",
            name = "Malachi",
            role = "summoner",
            description = "Summoner who drains enemies and raises skeletons.",
            portrait = "assets/hero images/shadow covenant/Malachi/Malachi.jpg",
            stats = { health = 320, damage = 16, attackRate = 1.0, range = 140, speed = 60, armor = 0.1, blockCount = 1 },
            abilities = {
                { name = "Soul Harvest", description = "Drains up to 5 enemies (5/s for 8 s) and heals allies by 40",
                  cooldown = 12, target = "area", radius = 150, maxTargets = 5,
                  effects = { { type = "drain", dps = 5, duration = 8, on = "enemy" },
                              { type = "heal", amount = 40, on = "ally" } } },
                -- Model C: "sacrifices health for damage". Kept, and raises
                -- two skeletons, the summoner's signature.
                { name = "Dark Ritual", description = "Costs 50 health: 100 damage to enemies nearby and raises 2 skeletons for 20 s",
                  cooldown = 15, target = "enemies", radius = 120,
                  effects = { { type = "selfDamage", amount = 50 }, { type = "damage", amount = 100 },
                              { type = "summon", count = 2,
                                minion = { sheet = "skeleton", tint = { 0.6, 1, 0.6 }, health = 80, damage = 10,
                                           attackRate = 1, speed = 55, armor = 0.1, duration = 20 } } } },
                { name = "Necrotic Aura", description = "10 damage and 30% slow for 6 s to enemies nearby",
                  cooldown = 20, target = "enemies", radius = 140,
                  effects = { { type = "damage", amount = 10 }, { type = "slow", amount = 0.3, duration = 6 } } },
            },
            passive = { name = "Minion Mastery", description = "Minions last 25% longer",
                        kind = "minionDuration", mult = 1.25 },
        },
        {
            id = "morgana",
            name = "Morgana",
            role = "cc",
            description = "Controls the battlefield with slows, roots and chains.",
            portrait = "assets/hero images/shadow covenant/Morgana/Morgana.jpg",
            stats = { health = 360, damage = 20, attackRate = 1.0, range = 140, speed = 60, armor = 0.1, blockCount = 1 },
            abilities = {
                { name = "Veil of Despair", description = "Slows enemies nearby by 40% and strips 30% armor for 6 s",
                  cooldown = 25, target = "enemies", radius = 150,
                  effects = { { type = "slow", amount = 0.4, duration = 6 }, { type = "armorShred", amount = 0.3, duration = 6 } } },
                { name = "Dark Binding", description = "Roots enemies nearby for 3 s and deals 30 damage",
                  cooldown = 15, target = "enemies", radius = 130,
                  effects = { { type = "root", duration = 3 }, { type = "damage", amount = 30 } } },
                { name = "Soul Shackles", description = "Chains enemies nearby for 5 s: damage to one is shared with the rest",
                  cooldown = 30, target = "enemies", radius = 150,
                  effects = { { type = "chain", share = 0.5, duration = 5 } } },
            },
            passive = { name = "Curse Enhancement", description = "Cursed Spires poison 30% harder",
                        kind = "towerStat", tower = "cursed_spire", stat = "poisonDps", mult = 1.3 },
        },
        {
            id = "dark_lord_malak",
            name = "Dark Lord Malak",
            role = "dps",
            description = "Melee brawler who steals life and steps through shadows.",
            stats = { health = 450, damage = 35, attackRate = 1.2, range = 40, speed = 65, armor = 0.2, blockCount = 2 },
            abilities = {
                { name = "Soul Drain", description = "30 damage to enemies nearby, heals for half the damage dealt",
                  cooldown = 20, target = "enemies", radius = 130,
                  effects = { { type = "damage", amount = 30, lifesteal = 0.5 } } },
                { name = "Shadow Step", description = "Teleports to the enemy furthest along the road within 250 px",
                  cooldown = 15, target = "point", radius = 250,
                  effects = { { type = "teleport" } } },
                { name = "Death Nova", description = "50 damage and 30% slow for 4 s to enemies nearby",
                  cooldown = 25, target = "enemies", radius = 140,
                  effects = { { type = "damage", amount = 50 }, { type = "slow", amount = 0.3, duration = 4 } } },
            },
            passive = { name = "Life Steal", description = "Heals for 20% of damage dealt",
                        kind = "heroLifesteal", amount = 0.2 },
        },
    },
}

------------------------------------------------------------------------
-- Twilight Balance
------------------------------------------------------------------------
Factions.twilight = {
    id = "twilight",
    order = 3,
    name = "Twilight Balance",
    description = "Masters of light and dark who switch elements to fit the fight.",
    color = { 0.55, 0.75, 1 },
    bonus = { hybridDamage = 0.10, abilityDuration = 0.05 },
    bonusText = "+10% hybrid tower damage, +5% hero ability duration",
    towers = {
        {
            id = "dawn_dusk_nexus",
            name = "Dawn-Dusk Nexus",
            -- Light hurts undead 25% more, dark hurts the living 25% more
            -- (see the `nature` of each enemy in systems/enemy.lua).
            description = "Hybrid tower: half light, half dark damage.",
            cost = 100, damage = 25, fireRate = 1.0, range = 170,
            projectileType = "hybrid",
            sprite = "sprites/towers/dawn_dusk_nexus.png",
            hybrid = { light = 15, dark = 10 },
            upgrades = {
                { name = "Balance", description = "Light and dark damage +30%", cost = 150,
                  mods = { { stat = "lightDamage", mult = 1.3 }, { stat = "darkDamage", mult = 1.3 } } },
                -- Model C: "alternates between light/dark". With the
                -- light/dark weakness rule, each shot uses the better one.
                { name = "Eclipse", description = "Each shot is all light or all dark, whichever the target is weak to", cost = 200,
                  mods = { { stat = "hybridSmart", set = true } } },
            },
        },
        {
            id = "eclipse_monolith",
            name = "Eclipse Monolith",
            description = "Drains 2% of its target's max health every second on top of its shots.",
            cost = 200, damage = 40, fireRate = 0.6, range = 190,
            projectileType = "void",
            sprite = "sprites/towers/eclipse_monolith.png",
            drain = { percent = 0.02 },
            upgrades = {
                { name = "Void Walker", description = "Drain +50%", cost = 300,
                  mods = { { stat = "drainPercent", mult = 1.5 } } },
                { name = "Cosmic Void", description = "Drains every enemy within 100 px of the tower", cost = 250,
                  mods = { { stat = "drainArea", set = 100 } } },
            },
        },
        {
            id = "elemental_nexus",
            name = "Elemental Nexus",
            description = "Hybrid tower that alternates fire (burn) and ice (freeze) shots.",
            cost = 300, damage = 45, fireRate = 1.0, range = 160,
            projectileType = "frost",
            sprite = "sprites/towers/frost.png",
            hybrid = { light = 25, dark = 20 },
            elemental = { burnDps = 10, burnDuration = 3, freezeDuration = 1 },
            upgrades = {
                { name = "Elemental Mastery", description = "+50% damage to enemies already burning or frozen", cost = 400,
                  mods = { { stat = "elementalBonus", set = 0.5 } } },
                { name = "Primal Rage", description = "Every 15 s, deals 50% more damage for 5 s", cost = 450,
                  mods = { { stat = "rageMult", set = 1.5 }, { stat = "rageDuration", set = 5 }, { stat = "rageInterval", set = 15 } } },
            },
        },
    },
    heroes = {
        {
            id = "zephyr",
            name = "Zephyr",
            role = "dps",
            description = "Hybrid duelist who switches between damage and life steal.",
            portrait = "assets/hero images/twilight balance/Zephyr/Zephyr.jpg",
            stats = { health = 380, damage = 28, attackRate = 1.2, range = 150, speed = 70, armor = 0.1, blockCount = 1 },
            abilities = {
                { name = "Dusk Shift", description = "Switch between +30% damage and 30% life steal",
                  cooldown = 1, target = "self", auto = false,
                  effects = { { type = "toggle", modes = { { damageBoost = 0.3 }, { lifesteal = 0.3 } } } } },
                { name = "Elemental Burst", description = "Enemies nearby burn (20/s for 3 s) or freeze (2 s), alternating each cast",
                  cooldown = 15, target = "enemies", radius = 140,
                  effects = { { type = "alternate", options = {
                      { { type = "burn", dps = 20, duration = 3 } },
                      { { type = "freeze", duration = 2 } } } } } },
                { name = "Primal Storm", description = "40 damage and a 2 s stun to enemies nearby",
                  cooldown = 30, target = "enemies", radius = 150,
                  effects = { { type = "damage", amount = 40 }, { type = "stun", duration = 2 } } },
            },
            passive = { name = "Hybrid Mastery", description = "Hybrid towers deal 20% more damage",
                        kind = "towerHybridDamage", mult = 1.2 },
        },
        {
            id = "lyra",
            name = "Lyra",
            role = "support",
            description = "Support who strengthens allies and towers and weakens enemies.",
            portrait = "assets/hero images/twilight balance/Lyra/Lyra.jpg",
            stats = { health = 360, damage = 18, attackRate = 1.0, range = 140, speed = 60, armor = 0.1, blockCount = 1 },
            abilities = {
                { name = "Equilibrium Wave", description = "Allies and towers nearby deal 15% more damage; enemies lose 20% armor (6 s)",
                  cooldown = 18, target = "area", radius = 180, includeTowers = true,
                  effects = { { type = "armorShred", amount = 0.2, duration = 6, on = "enemy" },
                              { type = "damageBoost", amount = 0.15, duration = 6, on = "ally" } } },
                { name = "Nature's Blessing", description = "Towers nearby fire 20% faster for 5 s; heals allies by 40",
                  cooldown = 20, target = "area", radius = 200, includeTowers = true,
                  effects = { { type = "haste", amount = 0.2, duration = 5, on = "tower" },
                              { type = "heal", amount = 40, on = "ally" } } },
                { name = "Primal Rage", description = "Allies and towers nearby deal 30% more damage for 4 s",
                  cooldown = 25, target = "area", radius = 180, includeTowers = true,
                  effects = { { type = "damageBoost", amount = 0.3, duration = 4, on = "ally" } } },
            },
            passive = { name = "Fusion Mastery", description = "Elemental Nexus shots both burn and freeze",
                        kind = "towerStat", tower = "elemental_nexus", stat = "fusion", set = true },
        },
        {
            id = "elemental_sage",
            name = "Elemental Sage",
            role = "dps",
            description = "Elemental caster whose burns hit harder.",
            stats = { health = 360, damage = 26, attackRate = 1.1, range = 150, speed = 65, armor = 0.1, blockCount = 1 },
            abilities = {
                { name = "Elemental Burst", description = "Enemies nearby burn (25/s for 3 s) or freeze (2 s), alternating each cast",
                  cooldown = 15, target = "enemies", radius = 140,
                  effects = { { type = "alternate", options = {
                      { { type = "burn", dps = 25, duration = 3 } },
                      { { type = "freeze", duration = 2 } } } } } },
                { name = "Nature's Blessing", description = "Towers nearby fire 20% faster for 5 s; heals allies by 40",
                  cooldown = 20, target = "area", radius = 200, includeTowers = true,
                  effects = { { type = "haste", amount = 0.2, duration = 5, on = "tower" },
                              { type = "heal", amount = 40, on = "ally" } } },
                { name = "Primal Storm", description = "40 damage and a 2 s stun to enemies nearby",
                  cooldown = 30, target = "enemies", radius = 150,
                  effects = { { type = "damage", amount = 40 }, { type = "stun", duration = 2 } } },
            },
            passive = { name = "Elemental Mastery", description = "Burns from this hero deal 25% more damage",
                        kind = "heroBurn", mult = 1.25 },
        },
    },
}

------------------------------------------------------------------------
-- Derived fields the menus read (hero select draws health/attack/speed
-- bars from these). Kept next to the data so there is one source.
------------------------------------------------------------------------
for _, faction in pairs(Factions) do
    for _, hero in ipairs(faction.heroes) do
        hero.health = hero.stats.health
        hero.attack = hero.stats.damage
        hero.speed = hero.stats.speed
        hero.faction = faction.id
    end
    for _, tower in ipairs(faction.towers) do
        tower.faction = faction.id
    end
end

return Factions
