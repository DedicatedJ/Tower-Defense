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

return Selection
