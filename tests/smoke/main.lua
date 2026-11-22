-- Smoke-test harness (run with tests/smoke/run_smoke.sh).
-- Loads the real game (game_main.lua), drives it through its own callbacks
-- and prints [SMOKE] PASS/FAIL lines. Screenshots land in the
-- "tower-defense-smoketest" save folder.

love.filesystem.setIdentity("tower-defense-smoketest")

local function log(...)
    local parts = {}
    for i = 1, select('#', ...) do parts[#parts + 1] = tostring(select(i, ...)) end
    print("[SMOKE] " .. table.concat(parts, " "))
    io.stdout:flush()
end

local failures, passes = 0, 0
local function check(cond, msg)
    if cond then passes = passes + 1; log("PASS", msg)
    else failures = failures + 1; log("FAIL", msg) end
end

function love.errorhandler(msg)
    log("CRASH", tostring(msg))
    log(debug.traceback("", 2))
    io.stdout:flush()
    os.exit(2)
end

-- Fresh profile every run
love.filesystem.createDirectory("save")
for i = 1, 5 do love.filesystem.remove("save/profile_" .. i .. ".json") end

love.filesystem.load("game_main.lua")()

-- Count sounds but make none
require('systems.audio').enabled = false

local Gamestate = require 'libs.hump.gamestate'
local gameLoad, gameUpdate, gameDraw = love.load, love.update, love.draw
local DT = 1 / 60

local function isState(mod) return getmetatable(Gamestate.current()) == require(mod) end
local function click(x, y, b) love.mousepressed(x, y, b or 1) end
local function key(k) love.keypressed(k) end
local function wait(frames) for _ = 1, frames or 1 do coroutine.yield() end end
local function shot(name)
    wait(2)
    love.graphics.captureScreenshot("smoke_" .. name .. ".png")
    wait(3)
end

-- Run the simulation fast: many updates per drawn frame
local function simulate(seconds, stopWhen)
    local steps = math.floor(seconds / DT)
    for i = 1, steps do
        gameUpdate(DT)
        if stopWhen and stopWhen() then return true, i * DT end
        if i % 120 == 0 then coroutine.yield() end
    end
    return false, seconds
end

local function offY() return require('states.game').MAP_OFFSET_Y end
local function cellScreen(gx, gy) return (gx - 0.5) * 32, (gy - 0.5) * 32 + offY() end

local Factions = require('data.factions')
local FACTION_IDS = { "radiant", "shadow", "twilight" }

-- Gameplay checks use the level 1 map (cell coordinates below are on it)
local function newGame(factionId, heroId, levelId)
    love.math.setRandomSeed(1)
    local GameState = require('states.game')
    local g = GameState.new()
    g:setup(factionId, heroId, levelId or "sunlit_meadows")
    Gamestate.switch(g)
    wait(2)
    return g
end

local function placeTower(g, id, gx, gy)
    for _, b in ipairs(g:getTowerButtons()) do
        if b.id == id then
            if g.selectedTower ~= id then click(b.x + 5, b.y + 5) end
            local before = #g.towers
            click(cellScreen(gx, gy))
            click(0, 0, 2)
            return #g.towers == before + 1
        end
    end
    return false
end

local function enemyNear(g, x, y, r)
    for _, e in ipairs(g.enemies) do
        if not e.dead and not e.reachedEnd and (e.x - x) ^ 2 + (e.y - y) ^ 2 <= r * r then return e end
    end
end

local function run()
    ------------------------------------------------------------------
    log("== Menus: faction select -> hero select -> hub -> level select -> game")
    local FactionSelect = require('states.faction_select')
    Gamestate.switch(FactionSelect.new()); wait(3)
    local fs = Gamestate.current()
    wait(20)
    shot("faction_select")
    check(#fs.factions == 3, "faction select lists 3 factions (" .. #fs.factions .. ")")
    local shadow
    for _, f in ipairs(fs.factions) do
        check(f.heroes and #f.heroes == 3, f.id .. " has 3 heroes")
        if f.id == "shadow" then shadow = f end
    end
    fs:selectFaction(shadow); wait(3)
    check(isState('states.hero_select'), "switched to hero select")
    local hs = Gamestate.current()
    check(hs.faction and hs.faction.id == "shadow", "hero select kept the faction")
    wait(20)
    shot("hero_select")
    local morgana = hs.faction.heroes[2]
    check(morgana.id == "morgana", "second Shadow hero is Morgana")
    hs:selectHero(morgana); wait(3)
    check(isState('states.hub'), "switched to hub")
    local hub = Gamestate.current()
    check(hub.selectedHero and hub.selectedHero.id == "morgana", "hub kept the hero")
    hub:goToLevelSelect(); wait(3)
    local ls = Gamestate.current()
    check(isState('states.level_select') and #ls.levels > 0, "level select has levels")
    ls:selectLevel(ls.levels[1]); ls:startLevel(); wait(3)
    check(isState('states.game'), "switched to game")
    local g0 = Gamestate.current()
    check(g0.factionData.id == "shadow" and g0.heroData.id == "morgana", "game runs Shadow with Morgana")
    local ids = {}
    for _, b in ipairs(g0:getTowerButtons()) do ids[#ids + 1] = b.id end
    check(#ids == 3, "tower panel shows 3 Shadow towers: " .. table.concat(ids, ", "))
    check(g0.hero and not g0.hero.dead, "hero spawned")

    log("== Menu Continue with the saved profile")
    Gamestate.switch(require('states.menu').new()); wait(3)
    Gamestate.current():continueGame(); wait(3)
    check(isState('states.hub'), "continue goes to hub")
    hub = Gamestate.current()
    check(type(hub.selectedHero) == "table" and hub.selectedHero.id == "morgana", "continue restores Morgana")
    hub:goToTowerUpgrades(); wait(10)
    check(isState('states.tower_upgrade') and #Gamestate.current().towers == 3, "tower screen lists 3 towers")
    Gamestate.current():selectTower(2)
    shot("tower_upgrade")

    ------------------------------------------------------------------
    local spots = { { 9, 7 }, { 13, 9 }, { 17, 11 } }
    local spare = { 15, 4 }
    for _, fid in ipairs(FACTION_IDS) do
        local faction = Factions[fid]
        local heroId = faction.heroes[1].id
        log("== " .. faction.name .. " with " .. faction.heroes[1].name)
        local g = newGame(fid, heroId)
        g.resources = 5000

        -- Build all three towers, buy both upgrades on each
        local towersById = {}
        for i, td in ipairs(faction.towers) do
            check(placeTower(g, td.id, spots[i][1], spots[i][2]), "placed " .. td.id)
            local t = g.towers[#g.towers]
            towersById[td.id] = t
            g:setFocusTower(t)
            local before = g.resources
            local spent = 0
            for _, b in ipairs(g:getFocusButtons()) do
                if b.kind == "upgrade" then
                    click(b.x + 5, b.y + 5)
                    spent = spent + b.upgrade.cost
                end
            end
            check(t.bought[1] and t.bought[2] and g.resources == before - spent,
                td.id .. ": both upgrades bought for " .. spent)
            click(0, 0, 2)
        end

        -- Sell the third tower and build it again (same spot, upgrades again)
        local t3 = g.towers[3]
        g:setFocusTower(t3)
        local before = g.resources
        local refund = t3:sellValue()
        for _, b in ipairs(g:getFocusButtons()) do
            if b.kind == "sell" then click(b.x + 5, b.y + 5) end
        end
        check(#g.towers == 2 and g.resources == before + refund and g.grid[t3.gridY][t3.gridX] == 1,
            "sold " .. t3.id .. " for " .. refund .. " (70%)")
        check(placeTower(g, t3.id, t3.gridX, t3.gridY), "rebuilt " .. t3.id)
        local rebuilt = g.towers[#g.towers]
        rebuilt:buyUpgrade(1); rebuilt:buyUpgrade(2)
        towersById[t3.id] = rebuilt

        -- Move the hero along the road, then try a grass cell
        local hero = g.hero
        click(hero.x, hero.y - 10 + offY())
        check(hero.selected, "clicking the hero selects it")
        local target = g.roadPath[20]
        click(cellScreen(target[1], target[2]))
        check(hero.path ~= nil, "clicking the road gives a path")
        local arrived = simulate(20, function() return hero.path == nil end)
        local tx, ty = g:cellCenter(target[1], target[2])
        check(arrived and math.abs(hero.x - tx) < 2 and math.abs(hero.y - ty) < 2,
            "hero walked the road to cell " .. target[1] .. "," .. target[2])
        click(hero.x, hero.y - 10 + offY())
        local hx, hy = hero.holdX, hero.holdY
        click(cellScreen(11, 4)) -- grass
        check(hero.holdX == hx and hero.holdY == hy, "clicking grass does not move the hero")
        click(0, 0, 2)

        -- Play all waves, watching what happens
        local seen = { statuses = {}, heroBlocked = false, minionBlocked = false, flyerBlocked = false,
                       heroHurt = false, heroDied = false }
        local manualCast = false
        local function observe()
            for _, e in ipairs(g.enemies) do
                for name in pairs(e.statuses or {}) do seen.statuses[name] = true end
                if e.blocker then
                    if e.blocker == hero then seen.heroBlocked = true else seen.minionBlocked = true end
                    if e.flying then seen.flyerBlocked = true end
                end
            end
            if hero.dead then seen.heroDied = true end
            if not hero.dead and hero.health < hero.maxHealth then seen.heroHurt = true end
            if not manualCast and not hero.dead and enemyNear(g, hero.x, hero.y, 120) then
                manualCast = true
                for _, s in ipairs(hero.abilities) do s.cooldown = 0 end
                key("q"); key("w"); key("e")
            end
            return (not g.waveInProgress) or g.isGameOver
        end
        local lines = {}
        for wave = 1, 10 do
            local livesBefore = g.lives
            click(g.ui.startWave.x + 5, g.ui.startWave.y + 5)
            if wave == 9 then
                simulate(26, observe)
                shot("game_" .. fid)
            end
            local done = simulate(600, observe)
            lines[#lines + 1] = string.format("w%d %s lives %d->%d", wave, done and "ok" or "TIMEOUT", livesBefore, g.lives)
            if not done or g.isGameOver then break end
        end
        log(fid .. " waves: " .. table.concat(lines, ", "))
        check(g.isGameOver, fid .. ": game ended (" .. (g.victory and "victory" or "defeat") ..
            ", lives " .. g.lives .. ")")

        local casts = {}
        for i, s in ipairs(hero.abilities) do casts[#casts + 1] = s.data.name .. "=" .. (s.casts or 0) end
        log(fid .. " hero casts: " .. table.concat(casts, ", ") .. "; level " .. hero.level)
        for i, s in ipairs(hero.abilities) do
            check((s.casts or 0) > 0, fid .. ": " .. s.data.name .. " was cast")
        end
        log(fid .. ": hero blocked an enemy: " .. tostring(seen.heroBlocked) ..
            ", took damage: " .. tostring(seen.heroHurt) .. " (checked per hero below)")
        check(not seen.flyerBlocked, fid .. ": flying enemies were never blocked")
        local st = {}
        for name in pairs(seen.statuses) do st[#st + 1] = name end
        table.sort(st)
        log(fid .. " statuses seen on enemies: " .. table.concat(st, ", "))

        local Save = require('systems.save')
        local prog = Save.getHeroProgress(heroId)
        check(prog.level == hero.level and prog.xp == hero.xp,
            fid .. ": hero level " .. hero.level .. " / xp " .. hero.xp .. " saved to profile")

        if fid == "radiant" then
            check(seen.statuses.burn, "Seraphim Altar burns")
            check((towersById.seraphs_watch.crits or 0) > 0, "Seraph's Watch crits")
        elseif fid == "shadow" then
            check(seen.statuses.poison, "Cursed Spire poisons")
            check((towersById.oblivion_engine.summoned or 0) > 0, "Oblivion Engine summoned minions (" ..
                (towersById.oblivion_engine.summoned or 0) .. ")")
            check(seen.minionBlocked, "minions blocked enemies")
        else
            check(seen.statuses.freeze or seen.statuses.burn, "Elemental Nexus burns or freezes")
            check((towersById.eclipse_monolith.hits or 0) > 0, "Eclipse Monolith fires")
            check((towersById.dawn_dusk_nexus.hits or 0) > 0, "Dawn-Dusk Nexus fires")
        end
    end

    ------------------------------------------------------------------
    log("== Every hero's abilities")
    for _, fid in ipairs(FACTION_IDS) do
        for _, hd in ipairs(Factions[fid].heroes) do
            local g = newGame(fid, hd.id)
            local hero = g.hero
            -- Meet the enemies near the start of the road
            local c = g.roadPath[6]
            hero:commandMove(c[1], c[2], g)
            simulate(20, function() return hero.path == nil end)
            click(g.ui.startWave.x + 5, g.ui.startWave.y + 5)
            simulate(40, function() return enemyNear(g, hero.x, hero.y, 100) ~= nil end)
            -- Each key on a fresh cooldown, with enemies still in reach (an
            -- earlier ability may have killed the nearest ones)
            local ok, names = true, {}
            local rooted = false
            for i, s in ipairs(hero.abilities) do
                simulate(20, function() return enemyNear(g, hero.x, hero.y, 100) ~= nil end)
                s.cooldown = 0; s.casts = 0
                key(({ "q", "w", "e" })[i])
                if (s.casts or 0) == 0 then
                    ok = false
                    local set = hero:abilityTargets(s.data, g)
                    names[#names + 1] = s.data.name .. " [enemies " .. #set.enemies .. ", dead " ..
                        tostring(hero.dead) .. ", path " .. tostring(hero.path ~= nil) .. "]"
                end
                for _, e in ipairs(g.enemies) do if e.statuses and e.statuses.root then rooted = true end end
            end
            check(ok, hd.name .. ": Q/W/E all cast" .. (ok and "" or (" (not: " .. table.concat(names, ", ") .. ")")))
            if hd.id == "morgana" then check(rooted, "Dark Binding roots enemies") end

            -- Blocking: hero deals no damage and casts nothing, minions gone,
            -- so enemies reach it
            for _, u in ipairs(g.units) do if u ~= hero then u:die() end end
            hero.damage = 0
            for _, s in ipairs(hero.abilities) do s.cooldown = 1e9 end
            if hero.dead then hero:respawn() end
            local blocked, hurt = false, false
            simulate(30, function()
                for _, e in ipairs(g.enemies) do if e.blocker == hero then blocked = true end end
                if hero.dead or hero.health < hero.maxHealth then hurt = true end
                if #g.enemies == 0 and not g.waveInProgress then
                    click(g.ui.startWave.x + 5, g.ui.startWave.y + 5)
                end
                return blocked and hurt
            end)
            check(blocked and hurt, hd.name .. ": blocks an enemy and takes hits")
            if hd.id == "malachi" then
                check((g.minionsSpawned or 0) >= 2, "Dark Ritual raised skeletons (" .. (g.minionsSpawned or 0) .. ")")
            end
        end
    end

    ------------------------------------------------------------------
    log("== Tower behaviors up close")
    do
        -- Holy Bastion heals a hurt hero in range
        local g = newGame("radiant", "sir_galahad")
        g.resources = 5000
        local c = g.roadPath[30]
        g.hero:commandMove(c[1], c[2], g)
        simulate(20, function() return g.hero.path == nil end)
        local gx, gy = c[1] + 1, c[2] + 1
        if g.grid[gy][gx] ~= 1 then gx, gy = c[1] - 1, c[2] - 1 end
        check(placeTower(g, "holy_bastion", gx, gy), "Holy Bastion placed next to the hero")
        local bastion = g.towers[#g.towers]
        g.hero.health = g.hero.maxHealth * 0.5
        local before = g.hero.health
        simulate(3)
        check((bastion.healed or 0) > 0 and g.hero.health > before,
            "Holy Bastion heals the hero (" .. math.floor(before) .. " -> " .. math.floor(g.hero.health) .. ")")

        -- Seraph's Watch with Divine Mark marks what it hits
        g = newGame("radiant", "sir_galahad")
        g.resources = 5000
        check(placeTower(g, "seraphs_watch", 9, 7), "Seraph's Watch placed")
        local watch = g.towers[#g.towers]
        watch:buyUpgrade(1)
        click(g.ui.startWave.x + 5, g.ui.startWave.y + 5)
        local marked = simulate(40, function()
            for _, e in ipairs(g.enemies) do if e.statuses and e.statuses.mark then return true end end
        end)
        check(marked, "Divine Mark marks enemies")

        -- Soul Forge raises enemies that die in range
        g = newGame("shadow", "malachi")
        g.resources = 5000
        check(placeTower(g, "soul_forge", 7, 3), "Soul Forge placed")
        local forge = g.towers[#g.towers]
        click(g.ui.startWave.x + 5, g.ui.startWave.y + 5)
        local fx, fy = forge:getCenter()
        simulate(60, function()
            for _, e in ipairs(g.enemies) do
                if not e.dead and (e.x - fx) ^ 2 + (e.y - fy) ^ 2 <= forge.range ^ 2 then
                    e:takeDamage(10000)
                end
            end
            return (forge.converted or 0) > 0
        end)
        check((forge.converted or 0) > 0, "Soul Forge raised a dead enemy as a minion")

        -- Eclipse Monolith drains a target with no shots fired
        g = newGame("twilight", "zephyr")
        g.resources = 5000
        check(placeTower(g, "eclipse_monolith", 9, 7), "Eclipse Monolith placed")
        local mono = g.towers[#g.towers]
        mono.fireRate = 0.0001 -- isolate the drain
        mono.fireCooldown = 1e9
        click(g.ui.startWave.x + 5, g.ui.startWave.y + 5)
        local drained = simulate(40, function()
            local t = mono.target
            return t and not t.dead and t.health < t.maxHealth
        end)
        check(drained, "Eclipse Monolith drains its target")
    end

    ------------------------------------------------------------------
    log("== Shop: buy with saved gold, applies in game")
    local Save = require('systems.save')
    Save.addGold(1000)
    local Shop = require('states.shop')
    local shop = Shop.new()
    shop:setup("radiant", "sir_galahad")
    Gamestate.switch(shop); wait(5)
    local goldBefore = shop.resources
    local sword
    for _, it in ipairs(shop.items) do if it.id == "heroic_sword" then sword = it end end
    shop:selectItem(sword)
    shop:purchaseItem()
    check(Save.getPurchases().heroic_sword == 1 and Save.getGold() == goldBefore - 200,
        "bought Heroic Sword for 200 (gold " .. goldBefore .. " -> " .. Save.getGold() .. ")")
    shot("shop")
    local g = newGame("radiant", "sir_galahad")
    local h = g.hero
    local expected = h.base.damage * (1 + 0.1 * (h.level - 1)) * 1.15
    check(math.abs(h.damage - expected) < 0.01, "Heroic Sword: hero damage x1.15 (" ..
        string.format("%.1f", h.damage) .. ")")

    ------------------------------------------------------------------
    log("== Levels")
    local Levels = require('data.levels')
    local LevelSys = require('systems.level')
    for _, lv in ipairs(Levels.list) do
        local f = Factions[lv.faction]
        local g = newGame(lv.faction, f.heroes[1].id, lv.id)
        local built = LevelSys.build(lv)
        local heroOnRoad = g.hero and g:isRoad(g:pixelToGrid(g.hero.x, g.hero.y + offY()))
        check(g.levelId == lv.id and #g.paths == #lv.paths and #g.roadPath == #built.roadCells
            and g.resources >= lv.startGold and g.maxWaves == lv.waves.count and heroOnRoad,
            lv.id .. ": map, " .. #lv.paths .. " road(s), " .. lv.waves.count .. " waves, hero on the road")
        shot("level_" .. lv.id)
        -- Wave 1 runs to the end on every road and pays its bonus
        g.resources = 5000
        for i, t in ipairs(f.towers) do
            local spot
            for _, c in ipairs(g.roadPath) do
                for _, d in ipairs({ { 0, 1 }, { 0, -1 }, { 1, 0 }, { -1, 0 } }) do
                    if not spot and g:canPlaceTower(c[1] + d[1], c[2] + d[2]) and (_ * 7 + i) % 5 == 0 then
                        spot = { c[1] + d[1], c[2] + d[2] }
                    end
                end
            end
            if spot then g:placeTower(spot[1], spot[2], t.id) end
        end
        local goldBefore = g.resources
        g:startNextWave()
        local done = simulate(240, function() return not g.waveInProgress end)
        check(done and g.wave == 1 and g.resources >= goldBefore + g.waves[1].bonus,
            lv.id .. ": wave 1 cleared, bonus " .. g.waves[1].bonus .. " paid (lives " .. g.lives .. ")")
    end

    -- Necromancers raise skeletons as they walk
    do
        local g = newGame("radiant", "sir_galahad")
        g.hero.dead = true
        g.hero.respawnTimer = 1e9
        g.waveInProgress = true
        g.waveEnemies = {}
        g.waves[1] = { entries = {}, healthMult = 1, bonus = 0 }
        g.wave = 1
        local n = g:addEnemy("necromancer", 1, 50)
        simulate(14, function() return (g.raisedCount or 0) >= 2 end)
        local raised = 0
        for _, e in ipairs(g.enemies) do if e.raised and e.type == "skeleton" then raised = raised + 1 end end
        check(raised >= 2 and n.currentPathIndex > 1, "a necromancer raises a skeleton every 6 s (" .. raised .. " raised)")
    end

    -- End screen: stars saved, Next Level and Level Select work
    do
        local g = newGame("shadow", "malachi", "haunted_forest")
        g.lives = 19
        g.wave = g.maxWaves
        g:gameOver(true)
        local rec = Save.getLevelResult("haunted_forest")
        check(g.stars == 3 and rec and rec.stars == 3, "a win at 19/20 lives saves 3 stars")
        shot("end_victory")
        local labels = {}
        for _, b in ipairs(g:getEndButtons()) do labels[#labels + 1] = b.label end
        check(table.concat(labels, ",") == "Next Level,Replay,Level Select", "victory offers Next Level, Replay, Level Select")
        local nb = g:getEndButtons()[1]
        click(nb.x + 5, nb.y + 5)
        wait(2)
        local cur = Gamestate.current()
        check(isState('states.game') and cur.levelId == "obsidian_caves", "Next Level starts Obsidian Caves")

        cur:gameOver(false)
        labels = {}
        for _, b in ipairs(cur:getEndButtons()) do labels[#labels + 1] = b.label end
        check(table.concat(labels, ",") == "Retry,Level Select", "defeat offers Retry, Level Select")
        check(Save.getLevelResult("obsidian_caves") == nil, "a loss records no stars")
        local lb = cur:getEndButtons()[2]
        click(lb.x + 5, lb.y + 5)
        wait(3)
        local ls = Gamestate.current()
        check(isState('states.level_select') and ls.levels[2].unlocked and not ls.levels[3].unlocked
            and ls.selectedLevel.id == "obsidian_caves",
            "Level Select: Obsidian Caves open and selected, Necropolis locked")
        wait(30) -- let the cards slide in
        shot("level_select")
    end

    ------------------------------------------------------------------
    log("== Pause and game speed")
    do
        local g = newGame("radiant", "sir_galahad")
        g:startNextWave()
        simulate(6, function() return #g.enemies > 0 and g.enemies[1].x > 40 end)
        local e = g.enemies[1]
        local x0, y0 = e.x, e.y
        local tb = g:getTowerButtons()[1]
        click(tb.x + 5, tb.y + 5)
        key("escape")
        check(isState('states.game') and not g:hasSelection(), "Esc with a tower picked drops it and does not pause")
        key("escape")
        check(isState('states.pause'), "Esc with nothing selected pauses")
        wait(30)
        check(e.x == x0 and e.y == y0, "nothing moves while paused")
        shot("pause")
        key("escape")
        check(isState('states.game') and Gamestate.current() == g, "Esc resumes the same game")
        key("p")
        check(isState('states.pause'), "P pauses")
        key("p")
        check(Gamestate.current() == g, "P resumes")

        -- Restart Level from the pause menu
        key("p")
        local pause = Gamestate.current()
        local function press(label)
            for _, b in ipairs(pause.buttons) do
                if b.text == label then click(b.x + 5, b.y + 5); return true end
            end
        end
        press("Restart Level")
        wait(2)
        local r = Gamestate.current()
        check(isState('states.game') and r ~= g and r.levelId == g.levelId and r.wave == 0,
            "Restart Level starts the same level fresh")
        key("p")
        pause = Gamestate.current()
        press("Level Select")
        wait(2)
        check(isState('states.level_select'), "Level Select leaves the game for level select")

        -- Speed: 3x runs three steps per frame, so game time runs 3x
        local a = newGame("radiant", "sir_galahad")
        local t0 = a.mapTime or 0
        for _ = 1, 60 do gameUpdate(DT) end
        local slow = (a.mapTime or 0) - t0
        local b = newGame("radiant", "sir_galahad")
        key("tab"); key("tab")
        check(b.speed == 3, "Tab cycles the speed 1x -> 2x -> 3x")
        local t1 = b.mapTime or 0
        for _ = 1, 60 do gameUpdate(DT) end
        local fast = (b.mapTime or 0) - t1
        check(math.abs(fast - 3 * slow) < 1e-6, string.format("3x runs three times the game time (%.2f s vs %.2f s)", fast, slow))
        click(b.ui.speed.x + 5, b.ui.speed.y + 5)
        check(b.speed == 1, "the speed button wraps 3x back to 1x")
    end

    ------------------------------------------------------------------
    log("== Tower button tooltips")
    for _, fid in ipairs(FACTION_IDS) do
        local g = newGame(fid, Factions[fid].heroes[1].id)
        local shown = 0
        -- drawTooltip clears the tooltip after drawing it, so watch it there
        local seen
        local orig = g.drawTooltip
        g.drawTooltip = function(self) seen = self.tooltip; return orig(self) end
        for _, b in ipairs(g:getTowerButtons()) do
            love.mouse.setPosition(b.x + 10, b.y + 10)
            seen = nil
            wait(2) -- the window reports the new mouse position next frame; draw runs then
            if seen and seen.title == b.tower.name and #seen.stats == 3 then shown = shown + 1
            else log("  no tooltip over " .. b.id) end
        end
        check(shown == #Factions[fid].towers, fid .. ": hovering each tower button draws its tooltip (" .. shown .. ")")
    end
    love.mouse.setPosition(0, 0)

    ------------------------------------------------------------------
    log("== Every menu screen")
    do
        local menu = require('states.menu').new()
        Gamestate.switch(menu)
        wait(2)
        -- name, how it is opened, and what Esc should lead back to
        local screens = {
            { "settings", function() menu:openSettings() end, 'states.menu' },
            { "tutorial", function() menu:openTutorial() end, 'states.menu' },
            { "credits", function() menu:openCredits() end, 'states.menu' },
            { "load_game", function() menu:loadGame() end, 'states.menu' },
            { "achievement", function() Gamestate.push(require('states.achievement').new()) end, 'states.menu' },
        }
        for _, sc in ipairs(screens) do
            Gamestate.switch(require('states.menu').new())
            menu = Gamestate.current()
            wait(1)
            local ok, err = pcall(function()
                sc[2]()
                local st = Gamestate.current()
                for _ = 1, 30 do st:update(DT) end
                st:draw()
            end)
            check(ok and isState('states.' .. sc[1]), sc[1] .. ": opens, updates and draws" ..
                (ok and "" or (": " .. tostring(err))))
            if ok then
                shot("screen_" .. sc[1])
                if sc[3] then
                    local ok2, err2 = pcall(function() key("escape") end)
                    wait(1)
                    check(ok2 and isState(sc[3]), sc[1] .. ": Esc goes back to " .. sc[3] ..
                        (ok2 and "" or (": " .. tostring(err2))))
                end
            end
        end
    end

    ------------------------------------------------------------------
    log("== Profiles: New Game, Load Game, Continue")
    do
        local Save = require('systems.save')
        Save.useSlot(1)
        local before = Save.slotSummary(1)
        check(before and before.faction ~= nil and before.wins > 0,
            "slot 1 summary: " .. tostring(before and before.faction) .. ", " .. tostring(before and before.wins) ..
            " wins, " .. tostring(before and before.stars) .. " stars")
        for s = 2, Save.SLOT_COUNT do Save.deleteProfile(s) end

        -- New Game takes the first empty slot and starts at faction select
        Gamestate.switch(require('states.menu').new())
        wait(1)
        Gamestate.current():startNewGame()
        wait(1)
        check(isState('states.faction_select') and Save.currentSlotNumber() == 2 and Save.slotUsed(2),
            "New Game starts a fresh profile in slot 2 and opens faction select")
        check(Save.getGold() == 0 and Save.getLevelResult("sunlit_meadows") == nil,
            "the new profile starts with no gold and no stars")

        -- The profile screen lists both, and Play on slot 1 goes back to it
        local lg = require('states.load_game').new()
        Gamestate.switch(lg)
        wait(2)
        check(lg.rows[1].summary and lg.rows[2].summary and not lg.rows[3].summary,
            "Load Game shows slots 1 and 2 used, slot 3 empty")
        shot("profiles")
        local function press(row, action)
            for _, b in ipairs(row.buttons) do
                if b.action == action then click(b.x + 5, b.y + 5); return true end
            end
        end
        press(lg.rows[2], "delete")
        check(Save.slotUsed(2) and lg.confirmDelete == 2, "the first Delete click only asks")
        press(lg.rows[2], "delete")
        check(not Save.slotUsed(2) and not lg.rows[2].summary, "the second Delete click removes slot 2")
        press(lg.rows[1], "play")
        wait(2)
        check(isState('states.hub') and Save.currentSlotNumber() == 1 and Save.getGold() == before.gold,
            "Play on slot 1 opens the hub with slot 1's profile")

        -- The slot is remembered for the next launch
        Save.useSlot(1)
        check(Save.restoreLastSlot() == 1, "the last slot used is remembered for Continue")

        -- With every slot full, New Game explains instead of overwriting
        for s = 2, Save.SLOT_COUNT do Save.newProfile(s) end
        Save.useSlot(1)
        Gamestate.switch(require('states.menu').new())
        wait(1)
        Gamestate.current():startNewGame()
        wait(1)
        local screen = Gamestate.current()
        check(isState('states.load_game') and screen.message and screen.message:match("slots are in use"),
            "New Game with every slot used opens Profiles with a note, overwriting nothing")
        for s = 2, Save.SLOT_COUNT do Save.deleteProfile(s) end
        Save.useSlot(1)
    end

    ------------------------------------------------------------------
    log("== Dropped-in art is picked up by name")
    do
        -- The save folder is searched before the game folder, so files
        -- written there stand in for art batch 2 files
        local function copy(from, to)
            love.filesystem.createDirectory(to:match("^(.*)/"))
            assert(love.filesystem.write(to, love.filesystem.read(from)))
        end
        local Tower = require('systems.tower')
        local Enemy = require('systems.enemy')
        copy("sprites/towers/cannon.png", "sprites/towers/holy_bastion.png")
        copy("sprites/enemies/zombie.png", "sprites/heroes/sir_galahad.png")
        copy("sprites/enemies/zombie.lua", "sprites/heroes/sir_galahad.lua")
        Tower.initialized = false
        Tower.init()
        check(Tower.spritePath(Tower.byId.holy_bastion) == "sprites/towers/holy_bastion.png"
            and Tower.images.holy_bastion ~= nil, "a tower uses sprites/towers/<id>.png when it exists")
        check(Tower.spritePath(Tower.byId.seraphim_altar) == "sprites/towers/cannon.png",
            "a tower without its own file keeps its stand-in")
        local g = newGame("radiant", "sir_galahad")
        check(g.hero.sheetKey == "hero_sir_galahad", "a hero uses sprites/heroes/<id>.png when it exists")
        local ok, err = pcall(function() g:draw() end)
        check(ok, "a hero with a walk sheet draws" .. (ok and "" or (": " .. tostring(err))))
        g:startNextWave()
        simulate(4)
        shot("hero_walk_sheet")
        local m = newGame("radiant", "archangel_michael")
        check(m.hero.sheetKey == nil and m.hero.portraitImage == nil, "a hero with no art yet falls back to the lettered token")

        love.filesystem.remove("sprites/towers/holy_bastion.png")
        love.filesystem.remove("sprites/heroes/sir_galahad.png")
        love.filesystem.remove("sprites/heroes/sir_galahad.lua")
        Enemy.sheets.hero_sir_galahad = nil
        Tower.initialized = false
        Tower.init()
    end

    ------------------------------------------------------------------
    log("== Battle feedback")
    do
        local Fx = require('systems.fx')
        local before = { damage = Fx.counts.damage, puff = Fx.counts.puff, gold = Fx.counts.gold }
        local g = newGame("radiant", "sir_galahad")
        g.resources = 2000
        placeTower(g, "holy_bastion", 7, 3)
        placeTower(g, "seraphim_altar", 9, 6)
        g:startNextWave()
        simulate(25, function() return #Fx.items >= 6 end)
        shot("battle_feedback")
        simulate(120, function() return not g.waveInProgress end)
        check(Fx.counts.damage > before.damage and Fx.counts.puff > before.puff and Fx.counts.gold > before.gold,
            string.format("a wave shows damage numbers (%d), death puffs (%d) and gold popups (%d)",
                Fx.counts.damage - before.damage, Fx.counts.puff - before.puff, Fx.counts.gold - before.gold))
        local lostBefore = Fx.counts.life
        g.lives = 20
        local e = g:addEnemy("zombie", 1, 1)
        e.currentPathIndex = #e.path
        e.x, e.y = g:cellCenter(g.endX, g.endY)
        simulate(1)
        check(Fx.counts.life > lostBefore and g.lives < 20, "an enemy reaching the gate flashes the edge and shows the lives lost")
    end

    ------------------------------------------------------------------
    log("== Sounds over a whole run")
    do
        local Audio = require('systems.audio')
        local c = Audio.counts
        local function n(k) return c[k] or 0 end
        local shots = 0
        for k, v in pairs(c) do if k:match("^shot_") then shots = shots + v end end
        log(string.format("plays: shots %d, hits %d, deaths %d, place %d, sell %d, upgrade %d, wave %d, " ..
            "ability %d, level up %d, life lost %d, purchase %d, victory %d, defeat %d",
            shots, n("enemy_hit"), n("enemy_die"), n("place"), n("sell"), n("upgrade"), n("wave_start"),
            n("ability"), n("level_up"), n("life_lost"), n("purchase"), n("victory"), n("defeat")))
        check(shots > 0 and n("enemy_hit") > 0 and n("enemy_die") > 0, "towers fire, hit and kill with sound")
        check(n("place") > 0 and n("sell") > 0 and n("upgrade") > 0, "placing, selling and upgrading make sounds")
        check(n("wave_start") > 0 and n("ability") > 0 and n("level_up") > 0, "wave start, hero abilities and level ups make sounds")
        check(n("purchase") > 0 and n("victory") > 0 and n("defeat") > 0, "shop purchase, victory and defeat make sounds")
        check(n("music:game") > 0 and n("music:menu") > 0, "menu and game music both started")
        -- The whole run was throttled: far fewer shot sounds than shots
        local fired = 0
        for _, k in ipairs({ "shot_holy", "shot_fire", "shot_bolt", "shot_poison", "shot_void", "shot_soul", "shot_hybrid", "shot_frost" }) do
            fired = fired + n(k)
        end
        check(fired == shots, "every shot sound is filed under its projectile type")
    end

    ------------------------------------------------------------------
    log("== JSON round trip")
    local json = require('utils.json')
    local src = { a = 1, b = { 1, 2, 3 }, c = "x\"y\n\195\169", d = true, e = 1.5, f = {} }
    local back = json.decode(json.encode(src))
    check(back.a == 1 and #back.b == 3 and back.c == src.c and back.d == true and back.e == 1.5,
        "json encode/decode round trip")
end

local script
function love.load(args)
    gameLoad(args)
    script = coroutine.create(run)
end

function love.update(dt)
    gameUpdate(DT)
    local ok, err = coroutine.resume(script)
    if not ok then
        log("CRASH", tostring(err))
        log(debug.traceback(script))
        os.exit(2)
    end
    if coroutine.status(script) == "dead" then
        log(string.format("DONE passes=%d failures=%d", passes, failures))
        os.exit(failures == 0 and 0 or 1)
    end
end

function love.draw()
    gameDraw()
end
