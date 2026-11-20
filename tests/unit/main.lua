-- Unit tests (run with tests/run.sh unit).
-- Checks the game's logic modules directly, with expected values worked
-- out by hand from the rules, not from the code under test. Prints
-- [UNIT] PASS/FAIL lines. Saves go to the "tower-defense-unittest" folder.

love.filesystem.setIdentity("tower-defense-unittest")

local function log(...)
    local parts = {}
    for i = 1, select('#', ...) do parts[#parts + 1] = tostring(select(i, ...)) end
    print("[UNIT] " .. table.concat(parts, " "))
    io.stdout:flush()
end

local failures, passes = 0, 0
local function check(cond, msg)
    if cond then passes = passes + 1; log("PASS", msg)
    else failures = failures + 1; log("FAIL", msg) end
end
local function near(a, b, eps) return type(a) == "number" and math.abs(a - b) < (eps or 1e-6) end
local function fmt(x) return type(x) == "number" and string.format("%.3f", x) or tostring(x) end
local function checkNear(actual, expected, msg, eps)
    check(near(actual, expected, eps), msg .. " (expected " .. fmt(expected) .. ", got " .. fmt(actual) .. ")")
end

function love.errorhandler(msg)
    log("CRASH", tostring(msg))
    log(debug.traceback("", 2))
    io.stdout:flush()
    os.exit(2)
end

local Factions = require('data.factions')
local ShopItems = require('data.shop_items')
local Effects = require('systems.effects')
local Enemy = require('systems.enemy')
local Tower = require('systems.tower')
local Unit = require('systems.unit')

local FACTION_IDS = { "radiant", "shadow", "twilight" }

------------------------------------------------------------------------
-- Test doubles
------------------------------------------------------------------------
-- A two-cell road; enemies made here never move unless updated
local PATH = { { x = 1, y = 1 }, { x = 2, y = 1 } }
local function enemy(kind)
    local e = Enemy.create(kind or "zombie", PATH, 32)
    e.health, e.maxHealth = 1000, 1000
    return e
end

-- A bare target with no armor (hero-like), for effect checks
local function dummy(health)
    local d = { health = health or 1000, maxHealth = health or 1000, statuses = {} }
    function d:takeDamage(a) local x = math.min(a * Effects.damageTakenMult(self), self.health); self.health = self.health - x; return x end
    function d:heal(a) self.health = math.min(self.maxHealth, self.health + a * Effects.healingMult(self)) end
    return d
end

local function heroData(id)
    for _, fid in ipairs(FACTION_IDS) do
        for _, h in ipairs(Factions[fid].heroes) do
            if h.id == id then return h, Factions[fid] end
        end
    end
end

-- Walk every effect, including the ones nested in alternate and toggle
local function eachEffect(list, fn)
    for _, e in ipairs(list or {}) do
        fn(e)
        for _, opt in ipairs(e.options or {}) do eachEffect(opt, fn) end
    end
end

------------------------------------------------------------------------
local function testData()
    log("== Faction data")
    local KNOWN_EFFECTS = {
        damage = true, heal = true, selfDamage = true, burn = true, poison = true, drain = true,
        slow = true, root = true, stun = true, freeze = true, mark = true, armorShred = true,
        chain = true, damageReduction = true, invulnerable = true, reflect = true,
        damageBoost = true, haste = true, healingBoost = true, lifesteal = true,
        summon = true, teleport = true, toggle = true, alternate = true,
    }
    local KNOWN_TARGETS = { enemies = true, enemy = true, allies = true, area = true, towers = true, self = true, point = true }
    local KNOWN_PASSIVES = {
        allyArmor = true, heroBurn = true, heroCrit = true, heroLifesteal = true,
        minionDuration = true, towerHybridDamage = true, towerStat = true,
    }
    local HERO_STATS = { "health", "damage", "attackRate", "range", "speed", "armor", "blockCount" }

    local orders, towerIds, heroIds = {}, {}, {}
    local bad = {}
    local function fail(msg) bad[#bad + 1] = msg end

    for _, fid in ipairs(FACTION_IDS) do
        local f = Factions[fid]
        check(f and f.id == fid, fid .. ": faction exists with matching id")
        orders[#orders + 1] = f.order
        check(#f.towers == 3 and #f.heroes == 3, fid .. ": 3 towers and 3 heroes")
        check(type(f.bonus) == "table" and next(f.bonus) ~= nil and type(f.bonusText) == "string", fid .. ": has a bonus and its text")

        for _, t in ipairs(f.towers) do
            if towerIds[t.id] then fail("duplicate tower id " .. t.id) end
            towerIds[t.id] = true
            if not (t.cost > 0 and t.damage >= 0 and t.fireRate > 0 and t.range > 0) then fail(t.id .. " has a bad cost/damage/fireRate/range") end
            if #t.upgrades ~= 2 then fail(t.id .. " does not have 2 upgrades") end
            for i, up in ipairs(t.upgrades) do
                if not (up.cost > 0 and up.name and #up.mods > 0) then fail(t.id .. " upgrade " .. i .. " is incomplete") end
                for _, m in ipairs(up.mods) do
                    if not (m.stat and (m.mult or m.add or m.set ~= nil)) then fail(t.id .. " upgrade " .. i .. " has a mod with no stat/mult/add/set") end
                end
            end
            for _, e in ipairs(t.onHit or {}) do
                if not KNOWN_EFFECTS[e.type] then fail(t.id .. " onHit uses unknown effect " .. tostring(e.type)) end
            end
        end

        for _, h in ipairs(f.heroes) do
            if heroIds[h.id] then fail("duplicate hero id " .. h.id) end
            heroIds[h.id] = true
            for _, s in ipairs(HERO_STATS) do
                if type(h.stats[s]) ~= "number" then fail(h.id .. " stat " .. s .. " is missing") end
            end
            if #h.abilities ~= 3 then fail(h.id .. " does not have 3 abilities") end
            for _, ab in ipairs(h.abilities) do
                if not (ab.cooldown and ab.cooldown > 0) then fail(h.id .. " " .. ab.name .. " has no cooldown") end
                if not KNOWN_TARGETS[ab.target] then fail(h.id .. " " .. ab.name .. " has unknown target " .. tostring(ab.target)) end
                if #(ab.effects or {}) == 0 then fail(h.id .. " " .. ab.name .. " has no effects") end
                eachEffect(ab.effects, function(e)
                    if not KNOWN_EFFECTS[e.type] then fail(h.id .. " " .. ab.name .. " uses unknown effect " .. tostring(e.type)) end
                end)
            end
            if not (h.passive and KNOWN_PASSIVES[h.passive.kind]) then fail(h.id .. " passive kind is unknown") end
            if h.portrait and not love.filesystem.getInfo(h.portrait) then fail(h.id .. " portrait file is missing: " .. h.portrait) end
        end
    end
    table.sort(orders)
    check(orders[1] == 1 and orders[2] == 2 and orders[3] == 3, "faction order is 1, 2, 3")
    for _, msg in ipairs(bad) do log("  " .. msg) end
    check(#bad == 0, "every tower, upgrade, hero, ability and passive is well formed (" .. #bad .. " problems)")

    -- Art pipeline lists every tower and hero, so missing art has a prompt
    local A = love.filesystem.load("art/assets.lua")()
    local listed = {}
    for _, t in ipairs(A.cTowers or {}) do listed[t.id] = true end
    for _, h in ipairs(A.cHeroes or {}) do listed[h.id] = true end
    local missing = {}
    for id in pairs(towerIds) do if not listed["tower_" .. id] then missing[#missing + 1] = "tower_" .. id end end
    for id in pairs(heroIds) do if not listed["hero_" .. id] then missing[#missing + 1] = "hero_" .. id end end
    check(#missing == 0, "art/assets.lua has a prompt for every tower and hero" ..
        (#missing > 0 and (" (missing " .. table.concat(missing, ", ") .. ")") or ""))
end

------------------------------------------------------------------------
local function testEffects()
    log("== Effects")
    local e = enemy("zombie") -- armor 0
    Effects.apply(e, { type = "mark", mult = 1.5, duration = 3 })
    checkNear(e:takeDamage(100), 150, "mark x1.5: 100 damage deals 150")

    local s = enemy("skeleton") -- armor 0.2
    checkNear(s:takeDamage(100), 80, "skeleton armor 0.2: 100 damage deals 80")
    Effects.apply(s, { type = "armorShred", amount = 0.2, duration = 5 })
    checkNear(s:takeDamage(100), 100, "armor shred 0.2 removes skeleton armor")

    local tank = enemy("zombie")
    tank.armor = 5
    checkNear(tank:takeDamage(100), 10, "armor is capped at 90%")

    local d = dummy()
    Effects.apply(d, { type = "invulnerable", duration = 2 })
    checkNear(d:takeDamage(100), 0, "invulnerable takes no damage")
    d = dummy()
    Effects.apply(d, { type = "damageReduction", amount = 0.5, duration = 2 })
    checkNear(d:takeDamage(100), 50, "damage reduction 0.5 halves damage")

    -- Burn 10 dps for 3 s = 30 damage, then the status is gone
    local b = enemy("zombie")
    Effects.apply(b, { type = "burn", dps = 10, duration = 3 })
    for _ = 1, 80 do Effects.update(b, 0.05) end -- 4 s
    checkNear(b.maxHealth - b.health, 30, "burn 10 dps x 3 s deals 30", 0.6)
    check(not Effects.has(b, "burn"), "burn expires after its duration")

    -- Refresh keeps the stronger tick and the longer duration
    local r = enemy("zombie")
    Effects.apply(r, { type = "burn", dps = 10, duration = 3 })
    Effects.apply(r, { type = "burn", dps = 5, duration = 5 })
    check(r.statuses.burn.dps == 10 and r.statuses.burn.remaining == 5, "burn refresh keeps 10 dps and 5 s")

    local m = enemy("zombie")
    Effects.apply(m, { type = "slow", amount = 0.3, duration = 2 })
    Effects.apply(m, { type = "slow", amount = 0.5, duration = 2 })
    checkNear(Effects.speedMult(m), 0.5, "strongest slow wins (0.3 then 0.5)")
    Effects.apply(m, { type = "haste", amount = 0.2, duration = 2 })
    checkNear(Effects.speedMult(m), 0.6, "slow 0.5 with haste 0.2 moves at 0.6")

    local st = enemy("zombie")
    Effects.apply(st, { type = "stun", duration = 1 })
    check(Effects.speedMult(st) == 0 and not Effects.canAttack(st), "stun stops movement and attacks")
    local rt = enemy("zombie")
    Effects.apply(rt, { type = "root", duration = 1 })
    check(Effects.speedMult(rt) == 0 and Effects.canAttack(rt), "root stops movement but not attacks")
    local fz = enemy("zombie")
    Effects.apply(fz, { type = "freeze", duration = 1 })
    check(Effects.speedMult(fz) == 0 and not Effects.canAttack(fz), "freeze stops movement and attacks")

    local dm = enemy("zombie")
    Effects.apply(dm, { type = "slow", amount = 0.5, duration = 2 }, { durationMult = 2 })
    for _ = 1, 60 do Effects.update(dm, 0.05) end -- 3 s
    check(Effects.has(dm, "slow"), "durationMult 2 makes a 2 s slow last past 3 s")

    -- Drain heals the caster for what it deals
    local caster = dummy(1000)
    caster.health = 500
    local dr = enemy("zombie")
    Effects.apply(dr, { type = "drain", dps = 10, duration = 1 }, { caster = caster })
    for _ = 1, 20 do Effects.update(dr, 0.05) end
    checkNear(caster.health, 510, "drain 10 dps x 1 s heals the caster 10", 0.6)

    -- Lifesteal on an instant hit
    local ls = dummy(1000)
    ls.health = 500
    Effects.apply(enemy("zombie"), { type = "damage", amount = 100, lifesteal = 0.5 }, { caster = ls })
    checkNear(ls.health, 550, "lifesteal 0.5 on a 100 hit heals 50")

    -- Chain: a direct hit is shared, damage over time is not
    local a, b2, c = enemy("zombie"), enemy("zombie"), enemy("zombie")
    Effects.chain({ a, b2, c }, { type = "chain", share = 0.5, duration = 5 })
    a:takeDamage(100)
    check(a.health == 900 and b2.health == 950 and c.health == 950, "chain share 0.5: 100 on one deals 50 to each other")
    a:takeDamage(10, nil, { dot = true })
    check(b2.health == 950, "chain does not share damage over time")

    local h = dummy(1000)
    h.health = 500
    Effects.apply(h, { type = "healingBoost", amount = 0.5, duration = 3 })
    Effects.apply(h, { type = "heal", amount = 100 })
    checkNear(h.health, 650, "healing boost 0.5: heal 100 restores 150")
    Effects.apply(h, { type = "heal", amount = 10000 })
    checkNear(h.health, 1000, "heal is capped at max health")

    local en = enemy("zombie")
    Effects.apply(en, { type = "heal", amount = 100 })
    checkNear(en.health, 1000, "enemies are never healed")
end

------------------------------------------------------------------------
local function testEnemies()
    log("== Enemies")
    check(enemy("dragon").flying == true and enemy("zombie").flying == false, "dragons fly, zombies do not")
    check(enemy("zombie").nature == "undead" and enemy("orc").nature == "living", "zombie is undead, orc is living")
    local e = enemy("zombie")
    e.health = 40
    checkNear(e:takeDamage(100), 40, "damage dealt is capped at remaining health")
    check(e.dead and e.justDied, "an enemy at 0 health is dead and flagged for XP")
    checkNear(e:takeDamage(100), 0, "a dead enemy takes no more damage")
end

------------------------------------------------------------------------
local function testUnits()
    log("== Units")
    local hd, fd = heroData("sir_galahad")
    local u = Unit.newHero(hd, fd, 100, 100)
    check(u.level == 1 and u.maxHealth == hd.stats.health and u.damage == hd.stats.damage, "level 1 hero has its base stats")

    local u3 = Unit.newHero(hd, fd, 0, 0, { level = 3 })
    checkNear(u3.maxHealth, hd.stats.health * 1.2, "level 3: health +20%")
    checkNear(u3.damage, hd.stats.damage * 1.2, "level 3: damage +20%")

    local um = Unit.newHero(hd, fd, 0, 0, { statMods = { health = 1.2, damage = 1.15, speed = 1.1 } })
    checkNear(um.maxHealth, hd.stats.health * 1.2, "shop item: health x1.2")
    checkNear(um.speed, hd.stats.speed * 1.1, "shop item: speed x1.1")

    local x = Unit.newHero(hd, fd, 0, 0)
    x:gainXp(200)
    check(x.level == 2 and x.xp == 0, "200 XP: level 2 with 0 XP left")
    x:gainXp(450)
    check(x.level == 4 and x.xp == 50, "450 more XP: level 4 with 50 XP left")
    x:gainXp(100000)
    check(x.level == 10 and x.xp == 0, "XP stops at level 10")
    check(Unit.newHero(hd, fd, 0, 0, { level = 99 }).level == 10, "a saved level above 10 is clamped")

    -- Leveling keeps the health fraction
    local hp = Unit.newHero(hd, fd, 0, 0)
    hp.health = hp.maxHealth / 2
    hp:gainXp(200)
    checkNear(hp.health / hp.maxHealth, 0.5, "leveling up keeps the health fraction")

    -- Galahad armor 0.3: 100 damage deals 70
    local t = Unit.newHero(hd, fd, 0, 0)
    checkNear(t:takeDamage(100), 100 * (1 - hd.stats.armor), "hero armor reduces damage")
    checkNear(t:takeDamage(100, nil, { ignoreArmor = true }), 100, "ignoreArmor skips armor")

    -- Death, respawn, and freeing blocked enemies
    local dead = Unit.newHero(hd, fd, 50, 60)
    local held = enemy("zombie")
    held.blocker = dead
    dead.blocking = { held }
    dead.x, dead.y = 300, 300
    dead:takeDamage(1e9, nil, { ignoreArmor = true })
    check(dead.dead and dead.respawnTimer == Unit.RESPAWN_TIME and held.blocker == nil,
        "a dead hero frees the enemies it blocked and waits " .. Unit.RESPAWN_TIME .. " s")
    dead:respawn()
    check(not dead.dead and dead.health == dead.maxHealth and dead.x == 50 and dead.y == 60,
        "respawn: full health at the hold position")

    local mn = Unit.newMinion({ health = 100, damage = 5, duration = 10 }, 0, 0, { healthMult = 1.1, durationMult = 1.5 })
    checkNear(mn.maxHealth, 110, "minion health x1.1 (Shadow bonus)")
    checkNear(mn.remaining, 15, "minion duration x1.5 (passive)")

    -- Toggle cycles its modes (Dusk Shift)
    local toggleHero, toggleAb, toggleEff
    for _, fid in ipairs(FACTION_IDS) do
        for _, h in ipairs(Factions[fid].heroes) do
            for _, ab in ipairs(h.abilities) do
                for _, e in ipairs(ab.effects) do
                    if e.type == "toggle" then toggleHero, toggleAb, toggleEff = h, ab, e end
                end
            end
        end
    end
    if toggleHero then
        local th = Unit.newHero(toggleHero, Factions[toggleHero.faction], 0, 0)
        local seen = {}
        for i = 1, #toggleEff.modes + 1 do
            th:applyEffect(toggleEff, { enemies = {}, allies = {}, towers = {} }, toggleAb, {}, {})
            seen[i] = th.mode
        end
        check(seen[1] == 1 and seen[#toggleEff.modes + 1] == 1, toggleHero.name .. ": toggle cycles back to the first mode")
    end
end

------------------------------------------------------------------------
local function testTowers()
    log("== Towers")
    Tower.init()
    local hb = Tower.create("holy_bastion", 3, 4, 32)
    check(hb.damage == 20 and hb.range == 150 and hb.healAmount == 5, "Holy Bastion: damage 20, range 150, heal 5")
    check(hb:sellValue() == 70, "sell refunds 70% of 100 = 70")
    check(not hb:canBuyUpgrade(1, 149) and hb:canBuyUpgrade(1, 150), "Divine Light needs 150 gold")
    check(hb:buyUpgrade(1) == 150 and near(hb.healAmount, 7.5), "Divine Light: heal 5 -> 7.5")
    check(hb:buyUpgrade(1) == nil, "an upgrade can be bought once")
    check(hb:sellValue() == 175, "sell after upgrade refunds 70% of 250 = 175")

    local shop = Tower.create("holy_bastion", 1, 1, 32, { rangeMult = 1.05, fireRateMult = 1.08 })
    checkNear(shop.range, 157.5, "Focus Crystal: range x1.05")
    checkNear(shop.fireRate, 1.08, "Agility Shard: fire rate x1.08")

    local passive = Tower.create("holy_bastion", 1, 1, 32, { towerStat = { { tower = "holy_bastion", stat = "healAmount", mult = 1.15 } } })
    checkNear(passive.healAmount, 5.75, "hero passive changes one tower's stat (heal x1.15)")

    -- Every upgrade changes something on the tower
    local inert = {}
    for _, fid in ipairs(FACTION_IDS) do
        for _, td in ipairs(Factions[fid].towers) do
            for i = 1, 2 do
                local t = Tower.create(td.id, 1, 1, 32)
                local before = {}
                for k, v in pairs(t) do if type(v) ~= "table" then before[k] = v end end
                t:buyUpgrade(i)
                local changed = false
                for k, v in pairs(t) do
                    if type(v) ~= "table" and k ~= "spent" and k ~= "upgradeFlash" and before[k] ~= v then changed = true end
                end
                if not changed then inert[#inert + 1] = td.id .. " upgrade " .. i end
            end
        end
    end
    check(#inert == 0, "all 18 upgrades change a tower stat" .. (#inert > 0 and (" (no effect: " .. table.concat(inert, ", ") .. ")") or ""))

    -- Damage: faction bonus and crits
    local plain = Tower.create("holy_bastion", 1, 1, 32, { damageMult = 1.1 })
    plain.critChance = 0
    checkNear(plain:shotDamage(enemy("zombie")), 22, "Radiant +10% tower damage: 20 -> 22")
    local sw = Tower.create("seraphs_watch", 1, 1, 32)
    sw:buyUpgrade(2)
    local dmg, crit = sw:shotDamage(enemy("zombie"))
    check(crit and near(dmg, 160), "Holy Precision: every shot crits for 2 x 80 = 160")

    -- Hybrid: light hurts undead x1.25, dark hurts the living x1.25
    local nx = Tower.create("dawn_dusk_nexus", 1, 1, 32)
    nx.critChance = 0
    local L, D = nx.lightDamage, nx.darkDamage
    checkNear(nx:shotDamage(enemy("zombie")), L * 1.25 + D, "Dawn-Dusk Nexus vs undead: light x1.25")
    checkNear(nx:shotDamage(enemy("orc")), L + D * 1.25, "Dawn-Dusk Nexus vs living: dark x1.25")

    local boosted = Tower.create("holy_bastion", 1, 1, 32)
    boosted.critChance = 0
    Effects.apply(boosted, { type = "damageBoost", amount = 0.5, duration = 5 })
    checkNear(boosted:shotDamage(enemy("zombie")), 30, "a hero's damage boost reaches towers (20 -> 30)")
end

------------------------------------------------------------------------
local function testShop()
    log("== Shop items")
    local none = ShopItems.modsFor({}, true)
    check(none.heroDamage == 1 and none.towerRange == 1 and none.startLives == 0 and none.startGold == 0 and #none.used == 0,
        "no purchases: no changes")
    local m = ShopItems.modsFor({ heroic_sword = 1, power_core = 1, tower_crystal = 1 }, false)
    check(near(m.heroDamage, 1.15) and near(m.towerDamage, 1.10) and near(m.towerRange, 1.05),
        "sword, core, crystal: hero damage x1.15, tower damage x1.10, range x1.05")
    local kept = ShopItems.modsFor({ repair_kit = 2, gold_potion = 1 }, false)
    check(kept.startLives == 0 and #kept.used == 0, "consumables are not used unless the game starts")
    local used = ShopItems.modsFor({ repair_kit = 2, gold_potion = 1, freeze_potion = 1 }, true)
    check(used.startLives == 5 and used.startGold == 100 and used.freezeDuration == 3 and #used.used == 3,
        "game start uses one of each consumable: +5 lives, +100 gold, 3 s freeze")
    check(ShopItems.modsFor({ not_an_item = 3 }, true).heroDamage == 1, "unknown items are ignored")
end

------------------------------------------------------------------------
local function testSave()
    log("== Profile")
    love.filesystem.createDirectory("save")
    for i = 1, 5 do love.filesystem.remove("save/profile_" .. i .. ".json") end
    local Save = require('systems.save')

    check(Save.getGold() == 0, "new profile has 0 gold")
    local ok, why = Save.buyItem("heroic_sword", 200, false)
    check(not ok and why == "not enough gold", "cannot buy without gold")
    Save.addGold(500)
    check(Save.buyItem("heroic_sword", 200, false) and Save.getGold() == 300, "buy Heroic Sword: 500 -> 300 gold")
    local ok2, why2 = Save.buyItem("heroic_sword", 200, false)
    check(not ok2 and why2 == "already owned" and Save.getGold() == 300, "a permanent item is bought once")
    Save.buyItem("repair_kit", 100, true)
    Save.buyItem("repair_kit", 100, true)
    check(Save.getPurchases().repair_kit == 2 and Save.getGold() == 100, "consumables stack")
    Save.useConsumables({ "repair_kit" })
    check(Save.getPurchases().repair_kit == 1, "using a consumable removes one")
    Save.addGold(-1000)
    check(Save.getGold() == 0, "gold never goes below 0")

    Save.updateHeroProgress("sir_galahad", 4, 120)
    local p = Save.getHeroProgress("sir_galahad")
    check(p.level == 4 and p.xp == 120, "hero level and XP are kept")
    check(Save.getHeroProgress("lady_celestia").level == 1, "an unplayed hero starts at level 1")

    local disk = Save.loadProfile(1)
    check(disk and disk.heroes.sir_galahad.level == 4 and disk.purchases.heroic_sword == 1 and disk.gold == 0,
        "the profile file on disk has the hero level, purchases and gold")
end

------------------------------------------------------------------------
function love.load()
    love.math.setRandomSeed(1)
    testData()
    testEffects()
    testEnemies()
    testUnits()
    testTowers()
    testShop()
    testSave()
    log(string.format("DONE passes=%d failures=%d", passes, failures))
    os.exit(failures == 0 and 0 or 1)
end
