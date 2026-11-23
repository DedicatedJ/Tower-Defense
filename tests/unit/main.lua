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
-- A short straight road; enemies made here never move unless updated
local Path = require('systems.path')
local ROAD = Path.new({ { { 20, 20 }, { 100, 20 } } }, 80)
local function enemy(kind)
    local e = Enemy.create(kind or "zombie", ROAD, { offset = 0 })
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
    local pendingPortraits = {} -- paths with no file yet: must be on the art list
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
            if not h.portrait then fail(h.id .. " has no portrait path") end
            if h.portrait and not love.filesystem.getInfo(h.portrait) then pendingPortraits[#pendingPortraits + 1] = h.portrait end
        end
    end
    table.sort(orders)
    check(orders[1] == 1 and orders[2] == 2 and orders[3] == 3, "faction order is 1, 2, 3")
    for _, msg in ipairs(bad) do log("  " .. msg) end
    check(#bad == 0, "every tower, upgrade, hero, ability and passive is well formed (" .. #bad .. " problems)")

    -- Art pipeline lists every tower and hero, so missing art has a prompt
    local A = love.filesystem.load("art/assets.lua")()
    local onList = {}
    for _, p in ipairs(A.portraits or {}) do onList[p.file] = true end
    local unlisted = {}
    for _, path in ipairs(pendingPortraits) do if not onList[path] then unlisted[#unlisted + 1] = path end end
    check(#unlisted == 0, "every portrait not painted yet is on the art list (" .. #pendingPortraits .. " pending)" ..
        (#unlisted > 0 and (": " .. table.concat(unlisted, ", ")) or ""))
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

    -- Blocking is a tank trait: only tank heroes (and minions) hold enemies
    local wrong = {}
    for _, fid in ipairs(FACTION_IDS) do
        for _, h in ipairs(Factions[fid].heroes) do
            if (h.stats.blockCount > 0) ~= (h.role == "tank") then wrong[#wrong + 1] = h.id end
        end
    end
    check(#wrong == 0, "only tank heroes block" .. (#wrong > 0 and (" (not: " .. table.concat(wrong, ", ") .. ")") or ""))
    local function near40(kind) local e = enemy(kind); e:placeAt(40); return e end -- at (60, 20)
    local tank, e1 = Unit.newHero(hd, fd, 50, 20), near40()
    local tgt = tank:engage({ enemies = { e1 } })
    check(e1.blocker == tank and tgt == e1, "a tank holds an enemy near it")
    local mkd, mkf = heroData("dark_lord_malak")
    local brawler, e2 = Unit.newHero(mkd, mkf, 50, 20), near40()
    tgt = brawler:engage({ enemies = { e2 } })
    check(e2.blocker == nil and tgt == e2, "a melee dps hero goes for a passing enemy without holding it")
    brawler:attack(e2, {})
    check(e2.foe == brawler, "an enemy hit in melee by a unit not holding it marks that unit")
    e2.attackCooldown = 0
    local hp0, d0 = brawler.health, e2.distance
    e2:update(0.05)
    check(brawler.health < hp0 and e2.blocker == nil and e2.distance > d0,
        "the enemy hits back while it keeps walking")
    brawler.x = 300
    e2:update(0.05)
    check(e2.foe == nil, "an enemy drops a foe that is out of reach")
    local cld, clf = heroData("lady_celestia")
    local archer, e3 = Unit.newHero(cld, clf, 60, 20), near40()
    tgt = archer:engage({ enemies = { e3 } })
    check(e3.blocker == nil and tgt == e3, "a ranged hero shoots an enemy standing on it without holding it")
    local guard, e4 = Unit.newMinion({ health = 100, damage = 5 }, 50, 20), near40()
    guard:engage({ enemies = { e4 } })
    check(e4.blocker == guard, "minions still hold enemies")

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
    local hb = Tower.create("holy_bastion", 100, 140)
    check(hb.damage == 20 and hb.range == 110 and hb.healAmount == 5, "Holy Bastion: damage 20, range 110, heal 5")
    check(hb:sellValue() == 70, "sell refunds 70% of 100 = 70")
    check(not hb:canBuyUpgrade(1, 149) and hb:canBuyUpgrade(1, 150), "Divine Light needs 150 gold")
    check(hb:buyUpgrade(1) == 150 and near(hb.healAmount, 7.5), "Divine Light: heal 5 -> 7.5")
    check(hb:buyUpgrade(1) == nil, "an upgrade can be bought once")
    check(hb:sellValue() == 175, "sell after upgrade refunds 70% of 250 = 175")

    local shop = Tower.create("holy_bastion", 20, 20, { rangeMult = 1.05, fireRateMult = 1.08 })
    checkNear(shop.range, 115.5, "Focus Crystal: range x1.05")
    checkNear(shop.fireRate, 1.08, "Agility Shard: fire rate x1.08")

    local passive = Tower.create("holy_bastion", 20, 20, { towerStat = { { tower = "holy_bastion", stat = "healAmount", mult = 1.15 } } })
    checkNear(passive.healAmount, 5.75, "hero passive changes one tower's stat (heal x1.15)")

    -- Every upgrade changes something on the tower
    local inert = {}
    for _, fid in ipairs(FACTION_IDS) do
        for _, td in ipairs(Factions[fid].towers) do
            for i = 1, 2 do
                local t = Tower.create(td.id, 20, 20)
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
    local plain = Tower.create("holy_bastion", 20, 20, { damageMult = 1.1 })
    plain.critChance = 0
    checkNear(plain:shotDamage(enemy("zombie")), 22, "Radiant +10% tower damage: 20 -> 22")
    local sw = Tower.create("seraphs_watch", 20, 20)
    sw:buyUpgrade(2)
    local dmg, crit = sw:shotDamage(enemy("zombie"))
    check(crit and near(dmg, 160), "Holy Precision: every shot crits for 2 x 80 = 160")

    -- Hybrid: light hurts undead x1.25, dark hurts the living x1.25
    local nx = Tower.create("dawn_dusk_nexus", 20, 20)
    nx.critChance = 0
    local L, D = nx.lightDamage, nx.darkDamage
    checkNear(nx:shotDamage(enemy("zombie")), L * 1.25 + D, "Dawn-Dusk Nexus vs undead: light x1.25")
    checkNear(nx:shotDamage(enemy("orc")), L + D * 1.25, "Dawn-Dusk Nexus vs living: dark x1.25")

    local boosted = Tower.create("holy_bastion", 20, 20)
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

    check(Save.getLevelResult("sunlit_meadows") == nil, "an unplayed level has no result")
    Save.recordLevelResult("sunlit_meadows", 2)
    Save.recordLevelResult("sunlit_meadows", 1)
    check(Save.getLevelResult("sunlit_meadows").stars == 2, "a level keeps its best stars (2, not a later 1)")
    Save.recordLevelResult("sunlit_meadows", 3)
    check(Save.getLevelResult("sunlit_meadows").stars == 3, "a better result replaces it (3)")

    local disk = Save.loadProfile(1)
    check(disk and disk.heroes.sir_galahad.level == 4 and disk.purchases.heroic_sword == 1 and disk.gold == 0
        and disk.levels.sunlit_meadows.stars == 3,
        "the profile file on disk has the hero level, purchases, gold and level stars")

    -- Level select opens levels in order
    local LS = require('states.level_select')
    local function openLevels()
        local ls = LS.new()
        ls.selectedFaction = Factions.radiant
        ls:loadLevels()
        local open = {}
        for _, l in ipairs(ls.levels) do open[#open + 1] = l.unlocked and "open" or "locked" end
        return table.concat(open, ","), ls
    end
    local state, ls = openLevels()
    check(state == "open,open,locked" and ls.selectedLevel.id == "crystal_spires",
        "after winning level 1: level 2 opens and is preselected, level 3 stays locked")
    check(ls.levels[1].stars == 3 and ls.levels[1].thumbnail ~= nil, "level card shows 3 stars and a map picture")
    Save.recordLevelResult("crystal_spires", 1)
    check(openLevels() == "open,open,open", "winning level 2 opens level 3")
    local sh = LS.new()
    sh.selectedFaction = Factions.shadow
    sh:loadLevels()
    check(sh.levels[1].unlocked and not sh.levels[2].unlocked, "another faction's levels are separate")
end

------------------------------------------------------------------------
local function testLevels()
    log("== Levels")
    local Levels = require('data.levels')
    local Level = require('systems.level')

    local problems = {}
    for _, l in ipairs(Levels.list) do
        for _, p in ipairs(Level.validate(l)) do problems[#problems + 1] = p end
    end
    for _, p in ipairs(problems) do log("  " .. p) end
    check(#problems == 0, "all " .. #Levels.list .. " levels have valid roads, zones and settings (" .. #problems .. " problems)")

    for _, fid in ipairs(FACTION_IDS) do
        local list = Level.forFaction(fid)
        check(#list == 3 and list[1].order == 1 and list[2].order == 2 and list[3].order == 3,
            fid .. ": 3 levels in order 1, 2, 3")
        check(Level.nextOf(list[1].id) == list[2] and Level.nextOf(list[3].id) == nil,
            fid .. ": level 1 leads to level 2, level 3 is the last")
        check(Level.first(fid) == list[1], fid .. ": first level is " .. list[1].id)
    end

    -- Roads: straight runs with rounded corners, measured in pixels
    local Path = require('systems.path')
    local straight = Path.new({ { { 0, 0 }, { 100, 0 } } }, 80)
    local x, y, nx, ny, dx, dy = straight:pointAt(25)
    check(straight:length() == 100 and x == 25 and y == 0 and dx == 1 and dy == 0 and nx == 0 and ny == -1,
        "a straight road: length 100, 25 px along is (25, 0), heading right, normal up")
    local bend = Path.new({ { { 0, 0 }, { 200, 0 }, { 200, 200 } } }, 80)
    -- A 90 degree corner of radius 60 replaces 2 x 60 of straight with a
    -- quarter circle (60 * pi / 2)
    checkNear(bend:length(), 400 - 120 + 60 * math.pi / 2, "a right-angle corner is rounded to radius 60", 0.5)
    local cx, cy, cnx, cny = bend:pointAt(140 + 60 * math.pi / 4)
    checkNear(math.sqrt((cx - 140) ^ 2 + (cy - 60) ^ 2), 60, "halfway round the corner is 60 px from its center", 0.5)
    checkNear(cnx * cnx + cny * cny, 1, "the normal is a unit vector")
    local s1, d1 = bend:nearest(100, 30)
    check(near(s1, 100) and near(d1, 30), "nearest: 30 px off the first run, 100 px along")
    local jump = Path.new({ { { 0, 0 }, { 100, 0 } }, { { 500, 500 }, { 500, 600 } } }, 80)
    local jx, jy = jump:pointAt(150)
    check(jump:length() == 200 and #jump:portals() == 1 and jx == 500 and jy == 550 and jump:pieceAt(150) == 2,
        "a portal: the second piece starts where the first ends, with no distance between")

    -- Lanes: every size of enemy keeps clear of the road edge
    local fits = true
    for _, kind in ipairs({ "skeleton", "zombie", "orc" }) do
        for _, off in ipairs({ -100, 100 }) do
            local e = Enemy.create(kind, bend, { offset = off })
            if math.abs(e.offset) + e.radius > 40 - Enemy.LANE_MARGIN + 1e-6 then fits = false end
        end
    end
    check(fits, "enemy lanes are clamped so small, medium and large stay on an 80 px road")
    local big, small = Enemy.SIZES.large.radius, Enemy.SIZES.small.radius
    check(2 * big + 2 * small + 2 * Enemy.LANE_MARGIN <= Levels.roadWidth,
        "a large and a small enemy fit side by side on the road")

    -- Level 1: one road that enters at the left edge and ends at its gate
    local b1 = Level.build(Level.get("sunlit_meadows"))
    local r1 = b1.roads[1]
    check(#b1.roads == 1 and r1.xs[1] == -40 and r1.xs[#r1.xs] == 940 and r1.ys[#r1.ys] == 660,
        "Sunlit Meadows: one road from off the left edge to the gate at (940, 660)")

    -- Two roads that merge
    local cs = Level.build(Level.get("crystal_spires"))
    local e1, e2 = cs.roads[1], cs.roads[2]
    check(#cs.roads == 2 and e1.xs[#e1.xs] == e2.xs[#e2.xs] and e1.ys[#e1.ys] == e2.ys[#e2.ys],
        "Crystal Spires: 2 roads that end at the same gate")

    -- Placement: inside a zone, clear of the road, the HUD and other towers
    check(Level.canBuild(b1, 160, 170, {}) == true, "Sunlit Meadows: a tower fits at (160, 170) in a zone")
    local ok1, why1 = Level.canBuild(b1, 600, 500, {})
    check(not ok1 and why1 == "zone", "outside every zone: no (" .. tostring(why1) .. ")")
    local open = Level.build({ paths = { { { 0, 5 }, { 32, 5 } } }, zones = { { 0, 0, 32, 18 } } })
    local ok2, why2 = Level.canBuild(open, 300, 250, {})
    check(not ok2 and why2 == "road", "inside a zone but 50 px from the road's middle: no (" .. tostring(why2) .. ")")
    check(Level.canBuild(open, 300, 265, {}) == true, "65 px from the road's middle: yes")
    local ok4, why4 = Level.canBuild(open, 640, 40, {})
    check(not ok4 and why4 == "hud", "under the status bar: no (" .. tostring(why4) .. ")")
    local ok3, why3 = Level.canBuild(b1, 160, 170, { { x = 180, y = 180 } })
    check(not ok3 and why3 == "tower", "next to another tower: no (" .. tostring(why3) .. ")")
    check(Level.onRoad(b1, 200, 40) and not Level.onRoad(b1, 200, 140), "on the road at (200, 40), not at (200, 140)")

    -- Walk grid: a route along the road around the first corner
    local route = Level.nav(b1):route(200, 40, 400, 200)
    local onRoad = route ~= nil
    for _, p in ipairs(route or {}) do if not Level.onRoad(b1, p[1], p[2], 2) then onRoad = false end end
    check(onRoad and #route >= 3, "a hero route turns the corner and stays on the road (" .. #(route or {}) .. " points)")

    local nc = Level.build(Level.get("necropolis"))
    check(#nc.portals == 1 and nc.portals[1].from[1] == 140 and nc.portals[1].from[2] == 500
        and nc.portals[1].to[1] == 780 and nc.portals[1].to[2] == 140, "Necropolis: a portal from (140, 500) to (780, 140)")

    -- Enemies step through portals
    local walker = Enemy.create("zombie", nc.roads[1], { offset = 0 })
    local jumped = false
    for _ = 1, 60 * 200 do
        walker:update(1 / 60)
        if walker.piece == 2 and math.abs(walker.x - 780) < 40 and math.abs(walker.y - 140) < 40 then jumped = true end
        if walker.reachedEnd then break end
    end
    check(jumped and walker.reachedEnd, "a zombie walks the Necropolis road through the portal to the end")

    -- Stars for a win
    local GameState = require('states.game')
    check(GameState.starsFor(20, 20) == 3 and GameState.starsFor(18, 20) == 3 and GameState.starsFor(17, 20) == 2
        and GameState.starsFor(10, 20) == 2 and GameState.starsFor(9, 20) == 1,
        "stars: 3 at 90%+ lives, 2 at 50%+, else 1")
end

------------------------------------------------------------------------
local function testWaves()
    log("== Waves")
    local Wave = require('systems.wave')
    local Level = require('systems.level')
    local sm = Level.get("sunlit_meadows") -- difficulty 1, 10 waves

    local a, b = Wave.plan(sm), Wave.plan(sm)
    local same = #a == #b
    for n = 1, #a do
        if #a[n].entries ~= #b[n].entries then same = false end
        for i, e in ipairs(a[n].entries) do
            if b[n].entries[i].type ~= e.type then same = false end
        end
    end
    check(same and #a == 10, "a level's waves are the same every time (10 waves)")

    -- Budget (6 + d) * (1 + 0.35 n): wave 1 of difficulty 1 = 9.45 points
    local function points(w)
        local p = 0
        for _, e in ipairs(w.entries) do if e.type ~= "dragon" then p = p + Wave.COST[e.type] end end
        return p
    end
    check(points(a[1]) <= 9.45 + 1e-9 and points(a[1]) > 8.45, "wave 1 spends its 9.45-point budget (" .. points(a[1]) .. ")")
    check(points(a[10]) > points(a[5]) and points(a[5]) > points(a[1]), "later waves bring more enemies")

    local only = {}
    for _, e in ipairs(a[1].entries) do only[e.type] = true end
    check(only.zombie and not only.skeleton and not only.orc and not only.necromancer and not only.dragon,
        "wave 1 is zombies only")
    local w2 = {}
    for _, e in ipairs(a[2].entries) do w2[e.type] = true end
    check(not w2.skeleton and not w2.orc, "no skeletons or orcs in wave 2")
    local hasNecro = false
    for n = 1, 3 do for _, e in ipairs(a[n].entries) do if e.type == "necromancer" then hasNecro = true end end end
    check(not hasNecro, "no necromancers before 40% of the waves")

    local function dragons(w) local n = 0; for _, e in ipairs(w.entries) do if e.type == "dragon" then n = n + 1 end end; return n end
    check(dragons(a[10]) == 1 and dragons(a[5]) == 0, "difficulty 1: a dragon ends the last wave only")
    local cc = Wave.plan(Level.get("celestial_citadel")) -- difficulty 3, 15 waves
    check(dragons(cc[15]) == 1 and dragons(cc[8]) == 1 and dragons(cc[7]) == 0, "difficulty 3: dragons at wave 8 and 15")

    -- Health (1 + (0.10 + 0.08 d)(n - 1) + 0.008 d (n - 1)^2) * sqrt(road / 66) * HEALTH_SCALE * toughness
    local hs = Wave.DEFAULTS.HEALTH_SCALE
    checkNear(a[10].healthMult, (1 + 0.18 * 9 + 0.008 * 81) * math.sqrt(80 / 66) * hs,
        string.format("difficulty 1 wave 10 on an 80-unit road: health x%.2f", (1 + 0.18 * 9 + 0.008 * 81) * math.sqrt(80 / 66) * hs))
    checkNear(cc[15].healthMult, (1 + 0.34 * 14 + 0.024 * 196) * math.sqrt(113 / 66) * hs * 0.85,
        string.format("difficulty 3 wave 15 on a 113-unit road, toughness 0.85: health x%.2f",
            (1 + 0.34 * 14 + 0.024 * 196) * math.sqrt(113 / 66) * hs * 0.85))
    check(a[1].bonus == 24 and a[10].bonus == 60, "wave bonus 20 + 4 per wave (24 .. 60)")

    -- Two roads: groups of 6 take turns
    local ws = Wave.build(Level.get("crystal_spires"), 8)
    local ok = #ws.entries > 6
    for i, e in ipairs(ws.entries) do
        if e.type ~= "dragon" and e.path ~= (math.floor((i - 1) / 6) % 2) + 1 then ok = false end
    end
    check(ok, "Crystal Spires: groups of 6 alternate between the 2 roads")

    check(Wave.summary({ entries = { { type = "zombie" }, { type = "zombie" }, { type = "orc" } } }) == "2 Zombie, 1 Orc",
        "HUD summary reads \"2 Zombie, 1 Orc\"")
end

------------------------------------------------------------------------
local function testAudio()
    log("== Audio")
    local Audio = require('systems.audio')
    Audio.init()
    Audio.setVolumes(0, 0) -- real playback, silent

    check(Audio.resolve("place") == "tower_place" and Audio.resolve("defeat") == "game_over",
        "events use their own files (place -> tower_place, defeat -> game_over)")
    local want = love.filesystem.getInfo("sounds/sfx/enemy_die.wav") and "enemy_die" or "enemy_death"
    check(Audio.resolve("enemy_die") == want, "enemy death uses enemy_die.wav")
    local lvl = love.filesystem.getInfo("sounds/sfx/level_up.wav") and "level_up" or "tower_upgrade"
    check(Audio.resolve("level_up") == lvl, "level up falls back to tower_upgrade until level_up.wav exists (" .. lvl .. ")")
    check(Audio.resolve("no_such_event") == nil, "an unknown event resolves to nothing")

    -- Every tower projectile has a sound, its own or a stand-in
    local missing = {}
    for _, fid in ipairs(FACTION_IDS) do
        for _, t in ipairs(Factions[fid].towers) do
            if not Audio.resolveShot(t.projectileType) then missing[#missing + 1] = t.projectileType end
        end
    end
    check(#missing == 0, "every tower projectile type has a shot sound" ..
        (#missing > 0 and (" (none for " .. table.concat(missing, ", ") .. ")") or ""))
    local fire = love.filesystem.getInfo("sounds/sfx/shot_fire.wav") and "shot_fire" or "shot_cannon"
    check(Audio.resolveShot("fire") == fire, "fire shots use " .. fire)
    check(Audio.resolveShot("something_new") == "shot_basic", "an unknown projectile falls back to shot_basic")

    -- Throttling: a second play inside the gap is dropped
    Audio.lastPlayed.place = nil
    local first, second = Audio.play("place"), Audio.play("place")
    check(first and not second, "the same sound twice within its gap plays once")

    -- At most `max` copies at once (enemy_hit: 3). Stand-in sounds that
    -- report "still playing" make this independent of the audio device
    -- (a dummy driver, as in CI, finishes every sound instantly)
    local still = { isPlaying = function() return true end }
    Audio.playing.enemy_hit = { still, still }
    Audio.lastPlayed.enemy_hit = nil
    local third = Audio.play("enemy_hit")
    Audio.playing.enemy_hit = { still, still, still }
    Audio.lastPlayed.enemy_hit = nil
    local fourth = Audio.play("enemy_hit")
    local done = { isPlaying = function() return false end }
    Audio.playing.enemy_hit = { done, done, done }
    Audio.lastPlayed.enemy_hit = nil
    local afterFinish = Audio.play("enemy_hit")
    check(third and not fourth and afterFinish,
        "no more than 3 enemy hits sound at once; a finished one frees a place")
    Audio.playing.enemy_hit = nil

    Audio.setVolumes(2, -1)
    check(Audio.volumes.music == 1 and Audio.volumes.sfx == 0, "volumes are clamped to 0..1")
    Audio.setVolumes(0, 0)

    Audio.playMusic("menu")
    Audio.playMusic("menu")
    check(Audio.currentMusic == "menu" and Audio.counts["music:menu"] == 1, "asking for the track already playing does not restart it")
    Audio.playMusic("game")
    check(Audio.currentMusic == "game" and (not Audio.music.menu or not Audio.music.menu:isPlaying()),
        "switching tracks stops the old one")
    Audio.stopMusic()
    check(Audio.music.menu ~= nil and Audio.music.game ~= nil, "menu and game music load from sounds/Music")

    -- Settings round trip through the save folder
    local Save = require('systems.save')
    love.filesystem.remove("settings.json")
    local s = { musicVolume = 0.3, sfxVolume = 0.6, showTutorial = false, fullscreen = false }
    check(Save.saveSettings(s), "settings save")
    local back = { musicVolume = 1, sfxVolume = 1, showTutorial = true, fullscreen = false, other = 5 }
    check(Save.loadSettings(back) and back.musicVolume == 0.3 and back.sfxVolume == 0.6 and back.showTutorial == false
        and back.other == 5, "settings load back (music 0.3, sfx 0.6, tutorial off) and keep unknown keys")
    love.filesystem.write("settings.json", "null")
    local d = { musicVolume = 1 }
    check(not Save.loadSettings(d) and d.musicVolume == 1, "a broken settings file leaves the defaults alone")
    love.filesystem.remove("settings.json")

    -- With no table given, settings means the global gameState.settings
    -- (main.lua), never the cached profile
    local saved = _G.gameState
    _G.gameState = { settings = { musicVolume = 0.25, sfxVolume = 0.5 } }
    Save.getCurrentProfile() -- make sure a profile is cached
    check(Save:getSettings() == _G.gameState.settings, "Save:getSettings returns the global settings, not the profile")
    check(Save.saveSettings(), "saveSettings with no argument saves the global settings")
    local check2 = { musicVolume = 1, sfxVolume = 1 }
    Save.loadSettings(check2)
    check(check2.musicVolume == 0.25, "and they load back (music 0.25)")
    love.filesystem.remove("settings.json")
    _G.gameState = saved
end

------------------------------------------------------------------------
local function testFx()
    log("== Battle feedback")
    local Fx = require('systems.fx')
    Fx.clear()
    local z = { x = 100, y = 100 }
    Fx.damage(z, 20)
    Fx.damage(z, 15, true)
    check(#Fx.items == 1 and Fx.items[1].amount == 35 and Fx.items[1].crit,
        "hits on one enemy within 0.25 s merge into one number (35, marked crit)")
    Fx.update(0.3)
    Fx.damage(z, 5)
    check(#Fx.items == 2, "a hit after the merge window starts a new number")
    Fx.damage({ x = 0, y = 0 }, 0.4)
    check(#Fx.items == 2, "damage under 1 shows no number")
    Fx.update(1)
    check(#Fx.items == 0, "numbers fade out after 0.8 s")
    for i = 1, Fx.MAX + 20 do Fx.gold(i, i, 10) end
    check(#Fx.items == Fx.MAX, "live effects are capped at " .. Fx.MAX)
    Fx.clear()
    Fx.lifeLost(10, 10, 2)
    check(Fx.flash > 0 and Fx.items[1].amount == 2, "a lost life flashes the screen edge and shows -2")
    Fx.update(2)
    check(Fx.flash == 0 and #Fx.items == 0, "the flash and the -2 clear")
end

------------------------------------------------------------------------
local function testAchievements()
    log("== Achievements")
    local A = require('systems.achievements')
    local function ids(list) local t = {} for _, a in ipairs(list) do t[#t + 1] = a.id end table.sort(t) return table.concat(t, ",") end
    local p = { heroes = { sir_galahad = { level = 3 } }, levels = {} }

    local new = A.recordGame(p, { victory = false, livesLost = 4, towersBuilt = 2, wavesCleared = 5, shopGold = 40,
        towerTypes = 2, factionTowerCount = 3 })
    check(ids(new) == "first_tower", "a lost game with 2 towers unlocks only Foundation (" .. ids(new) .. ")")
    check(p.stats.towersBuilt == 2 and p.stats.wavesCleared == 5 and p.stats.shopGold == 40 and p.stats.games == 1,
        "the game adds to the profile totals")

    new = A.recordGame(p, { victory = true, livesLost = 0, towersBuilt = 6, wavesCleared = 10, shopGold = 150,
        towerTypes = 3, factionTowerCount = 3 })
    check(ids(new) == "perfect_wave,tower_synergy", "a flawless win with all 3 tower types unlocks Flawless and Combined Arms (" .. ids(new) .. ")")
    new = A.recordGame(p, { victory = true, livesLost = 0, towersBuilt = 1, wavesCleared = 10, shopGold = 0,
        towerTypes = 3, factionTowerCount = 3 })
    check(#new == 0, "an achievement unlocks once")

    p.heroes.sir_galahad.level = 10
    p.levels = { sunlit_meadows = { stars = 3 }, crystal_spires = { stars = 1 }, celestial_citadel = { stars = 2 } }
    new = A.recordGame(p, { victory = true, livesLost = 2, towersBuilt = 0, wavesCleared = 0, shopGold = 0, towerTypes = 1 })
    check(ids(new) == "faction_master,hero_legend", "a level 10 hero and a full faction unlock Hero Legend and Faction Master (" .. ids(new) .. ")")

    local rows = A.status(p)
    local byId = {}
    for _, r in ipairs(rows) do byId[r.id] = r end
    check(#rows == 8 and byId.first_tower.unlocked and byId.first_tower.date ~= nil, "the screen lists 8, with unlock dates")
    check(not byId.tower_master.unlocked and byId.tower_master.progress == 9 and byId.tower_master.maxProgress == 50,
        "Tower Master shows 9 / 50 towers")
    check(byId.wave_survivor.progress == 25 and byId.resource_king.progress == 190, "waves (25 / 100) and gold (190 / 2000) progress")
    for _, a in ipairs(A.list) do
        if not love.filesystem.getInfo("sprites/ui/achievements/" .. a.id .. ".png") then
            check(false, a.id .. " has an icon")
        end
    end
end

------------------------------------------------------------------------
local function testImages()
    log("== Images: mipmaps where the GPU allows (WebGL 1 does not for odd sizes)")
    local Image = require('utils.image')
    local npot, pot = love.image.newImageData(300, 200), love.image.newImageData(256, 128)
    check(Image.smooth(npot):getMipmapCount() > 1, "this GPU mipmaps a 300 x 200 image")
    local real = love.graphics.getSupported
    love.graphics.getSupported = function()
        local t = {}
        for k, v in pairs(real()) do t[k] = v end
        t.fullnpot = false
        return t
    end
    local okA, a = pcall(Image.smooth, npot)
    local okB, b = pcall(Image.smooth, pot)
    local can = Image.canMipmap(300, 200)
    love.graphics.getSupported = real
    check(okA and a:getMipmapCount() == 1 and a:getFilter() == "linear",
        "without full NPOT support a 300 x 200 image loads unmipmapped, linear")
    check(okB and b:getMipmapCount() > 1, "a 256 x 128 image still gets mipmaps")
    check(not can and Image.canMipmap(256, 128), "canMipmap: 300 x 200 no, 256 x 128 yes")
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
    testLevels()
    testWaves()
    testSave()
    testAudio()
    testFx()
    testAchievements()
    testImages()
    log(string.format("DONE passes=%d failures=%d", passes, failures))
    os.exit(failures == 0 and 0 or 1)
end
