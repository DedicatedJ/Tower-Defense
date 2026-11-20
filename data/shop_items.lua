-- Shop items: sold by states/shop.lua, applied by states/game.lua.
-- Permanent items are bought once and always apply. Consumables stack and
-- one of each is used up at the start of the next game.

local ShopItems = {
    list = {
        { id = "heroic_sword", name = "Heroic Sword", description = "Increases hero damage by 15%",
          cost = 200, category = "Heroes", icon = "hero_sword.png", effect = "hero_damage", effectValue = 0.15 },
        { id = "heavy_armor", name = "Heavy Armor", description = "Increases hero health by 20%",
          cost = 250, category = "Heroes", icon = "hero_armor.png", effect = "hero_health", effectValue = 0.20 },
        { id = "swiftness_boots", name = "Swiftness Boots", description = "Increases hero movement speed by 10%",
          cost = 180, category = "Heroes", icon = "hero_boots.png", effect = "hero_speed", effectValue = 0.10 },

        { id = "tower_crystal", name = "Focus Crystal", description = "Increases all tower range by 5%",
          cost = 300, category = "Towers", icon = "tower_crystal.png", effect = "tower_range", effectValue = 0.05 },
        { id = "power_core", name = "Power Core", description = "Increases all tower damage by 10%",
          cost = 350, category = "Towers", icon = "tower_core.png", effect = "tower_damage", effectValue = 0.10 },
        { id = "agility_shard", name = "Agility Shard", description = "Increases all tower attack speed by 8%",
          cost = 320, category = "Towers", icon = "tower_shard.png", effect = "tower_fire_rate", effectValue = 0.08 },

        { id = "repair_kit", name = "Repair Kit", description = "Start your next game with 5 extra lives",
          cost = 150, category = "Consumables", icon = "consumable_repair.png", effect = "start_lives",
          effectValue = 5, consumable = true },
        { id = "gold_potion", name = "Gold Potion", description = "Start your next game with 100 extra gold",
          cost = 200, category = "Consumables", icon = "consumable_gold.png", effect = "start_gold",
          effectValue = 100, consumable = true },
        { id = "freeze_potion", name = "Freeze Potion", description = "Press F once in your next game to freeze every enemy for 3 s",
          cost = 250, category = "Consumables", icon = "consumable_freeze.png", effect = "freeze_charge",
          effectValue = 3, consumable = true },
    },
}

ShopItems.byId = {}
for _, item in ipairs(ShopItems.list) do ShopItems.byId[item.id] = item end

-- Multipliers and start-of-game extras from what the player owns.
-- purchases: { [itemId] = count }
-- useConsumables: when true, one of each consumable is included (the game
-- then removes them from the profile).
function ShopItems.modsFor(purchases, useConsumables)
    local m = {
        heroDamage = 1, heroHealth = 1, heroSpeed = 1,
        towerRange = 1, towerDamage = 1, towerFireRate = 1,
        startLives = 0, startGold = 0, freezeDuration = nil,
        used = {},
    }
    for id, count in pairs(purchases or {}) do
        local item = ShopItems.byId[id]
        if item and count and count > 0 then
            local v = item.effectValue
            if not item.consumable then
                if item.effect == "hero_damage" then m.heroDamage = m.heroDamage + v end
                if item.effect == "hero_health" then m.heroHealth = m.heroHealth + v end
                if item.effect == "hero_speed" then m.heroSpeed = m.heroSpeed + v end
                if item.effect == "tower_range" then m.towerRange = m.towerRange + v end
                if item.effect == "tower_damage" then m.towerDamage = m.towerDamage + v end
                if item.effect == "tower_fire_rate" then m.towerFireRate = m.towerFireRate + v end
            elseif useConsumables then
                if item.effect == "start_lives" then m.startLives = m.startLives + v end
                if item.effect == "start_gold" then m.startGold = m.startGold + v end
                if item.effect == "freeze_charge" then m.freezeDuration = v end
                m.used[#m.used + 1] = id
            end
        end
    end
    return m
end

return ShopItems
