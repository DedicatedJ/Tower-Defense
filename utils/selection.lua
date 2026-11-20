-- Turns faction/hero selections into the table shapes the hub, level select
-- and game states expect. Saved profiles store ids (strings); the selection
-- screens pass tables. Both are accepted here.

local Factions = require('data.factions')

local Selection = {}

-- Returns a faction table {id, name, description, color, heroes}, or nil
-- when the selection is missing or unknown (callers apply their defaults).
function Selection.resolveFaction(faction)
    if type(faction) == 'table' then
        return faction
    end
    if type(faction) == 'string' and Factions[faction] then
        local data = Factions[faction]
        return {
            id = faction,
            name = data.name,
            description = data.description,
            color = data.color,
            heroes = data.heroes
        }
    end
    return nil
end

-- Returns a hero table from the faction's hero list, or nil.
function Selection.resolveHero(faction, hero)
    if type(hero) == 'table' then
        return hero
    end
    if type(hero) == 'string' and type(faction) == 'table' and faction.heroes then
        for _, h in ipairs(faction.heroes) do
            if h.id == hero or h.name == hero then
                return h
            end
        end
    end
    return nil
end

-- The canonical records from data/factions.lua for whatever a screen
-- passed along (a table from the selection screens, an id from a saved
-- profile, or nothing). Unknown or missing selections fall back to the
-- first faction and its first hero, so the game always has real data.
function Selection.canonical(faction, hero)
    local fid = faction
    if type(faction) == 'table' then fid = faction.id or faction.name end
    if type(fid) == 'string' then fid = fid:lower() end
    local data = Factions[fid]
    if not data then
        for _, f in pairs(Factions) do
            if f.order == 1 then data = f end
        end
    end

    local hid = hero
    if type(hero) == 'table' then hid = hero.id or hero.name end
    local heroData
    for _, h in ipairs(data.heroes) do
        if h.id == hid or h.name == hid then heroData = h end
    end
    return data, heroData or data.heroes[1]
end

-- Factions in display order
function Selection.orderedFactions()
    local list = {}
    for _, f in pairs(Factions) do list[#list + 1] = f end
    table.sort(list, function(a, b) return a.order < b.order end)
    return list
end

return Selection
