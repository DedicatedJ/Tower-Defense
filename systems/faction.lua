local Faction = {}
Faction.__index = Faction

-- Hero presets
local HERO_PRESETS = {
    radiant = {
        sir_galahad = {
            name = "Sir Galahad",
            description = "Tank/Support hero",
            role = "tank",
            abilities = {
                {
                    name = "Aegis of Dawn",
                    description = "Absorbs 50% damage for allies in 15m",
                    cooldown = 15,
                    duration = 5,
                    effect = function(hero, targets)
                        for _, target in ipairs(targets) do
                            target.damageReduction = 0.5
                        end
                    end
                },
                {
                    name = "Divine Shield",
                    description = "Creates a protective barrier",
                    cooldown = 20,
                    duration = 3,
                    effect = function(hero, targets)
                        for _, target in ipairs(targets) do
                            target.invulnerable = true
                        end
                    end
                },
                {
                    name = "Holy Light",
                    description = "Heals and buffs nearby allies",
                    cooldown = 25,
                    duration = 4,
                    effect = function(hero, targets)
                        for _, target in ipairs(targets) do
                            target:heal(50)
                            target.damageBoost = 0.2
                        end
                    end
                }
            },
            passive = {
                name = "Tower Armor",
                description = "+20% tower armor",
                effect = function(hero)
                    for _, tower in ipairs(gameState.towers) do
                        tower.armor = tower.armor * 1.2
                    end
                end
            }
        },
        lady_celestia = {
            name = "Lady Celestia",
            description = "Healer/DPS hero",
            role = "healer",
            abilities = {
                {
                    name = "Purifying Conflagration",
                    description = "Heals 100 HP, burns enemies 30 DPS",
                    cooldown = 20,
                    duration = 5,
                    effect = function(hero, targets)
                        for _, target in ipairs(targets) do
                            if target.isEnemy then
                                target:addEffect({
                                    type = "burn",
                                    damage = 30,
                                    duration = 5
                                })
                            else
                                target:heal(100)
                            end
                        end
                    end
                },
                {
                    name = "Radiant Burst",
                    description = "Area damage and healing",
                    cooldown = 15,
                    duration = 3,
                    effect = function(hero, targets)
                        for _, target in ipairs(targets) do
                            if target.isEnemy then
                                target:takeDamage(40)
                            else
                                target:heal(30)
                            end
                        end
                    end
                },
                {
                    name = "Light's Blessing",
                    description = "Increases healing effectiveness",
                    cooldown = 30,
                    duration = 8,
                    effect = function(hero, targets)
                        for _, target in ipairs(targets) do
                            target.healingBoost = 0.5
                        end
                    end
                }
            },
            passive = {
                name = "Holy Healing",
                description = "+15% healing to holy towers",
                effect = function(hero)
                    for _, tower in ipairs(gameState.towers) do
                        if tower.type == "holy_tower" then
                            tower.healAmount = tower.healAmount * 1.15
                        end
                    end
                end
            }
        },
        archangel_michael = {
            name = "Archangel Michael",
            description = "Ranged DPS hero",
            role = "dps",
            abilities = {
                {
                    name = "Divine Judgment",
                    description = "Deals massive damage to single target",
                    cooldown = 25,
                    duration = 1,
                    effect = function(hero, targets)
                        for _, target in ipairs(targets) do
                            target:takeDamage(200)
                        end
                    end
                },
                {
                    name = "Wings of Light",
                    description = "Temporary flight and speed boost",
                    cooldown = 20,
                    duration = 8,
                    effect = function(hero, targets)
                        for _, target in ipairs(targets) do
                            target.speed = target.speed * 1.5
                            target.canFly = true
                        end
                    end
                },
                {
                    name = "Holy Shield",
                    description = "Reflects damage to attackers",
                    cooldown = 30,
                    duration = 6,
                    effect = function(hero, targets)
                        for _, target in ipairs(targets) do
                            target.damageReflection = 0.3
                        end
                    end
                }
            },
            passive = {
                name = "Critical Strike",
                description = "+15% critical hit chance",
                effect = function(hero)
                    hero.criticalChance = 0.15
                end
            }
        }
    },
    shadow = {
        malachi = {
            name = "Malachi",
            description = "Summoner/DOT hero",
            role = "summoner",
            abilities = {
                {
                    name = "Soul Harvest",
                    description = "Drains 5 HP/s from 5 enemies, heals minions",
                    cooldown = 12,
                    duration = 8,
                    effect = function(hero, targets)
                        for _, target in ipairs(targets) do
                            if target.isEnemy then
                                target:addEffect({
                                    type = "drain",
                                    damage = 5,
                                    duration = 8
                                })
                            else
                                target:heal(40)
                            end
                        end
                    end
                },
                {
                    name = "Dark Ritual",
                    description = "Sacrifices health for damage",
                    cooldown = 15,
                    duration = 1,
                    effect = function(hero, targets)
                        hero:takeDamage(50)
                        for _, target in ipairs(targets) do
                            target:takeDamage(100)
                        end
                    end
                },
                {
                    name = "Necrotic Aura",
                    description = "Damages and slows enemies",
                    cooldown = 20,
                    duration = 6,
                    effect = function(hero, targets)
                        for _, target in ipairs(targets) do
                            target:addEffect({
                                type = "slow",
                                amount = 0.3,
                                duration = 6
                            })
                            target:takeDamage(10)
                        end
                    end
                }
            },
            passive = {
                name = "Minion Mastery",
                description = "+25% minion duration",
                effect = function(hero)
                    for _, minion in ipairs(gameState.minions) do
                        minion.duration = minion.duration * 1.25
                    end
                end
            }
        },
        morgana = {
            name = "Morgana",
            description = "Crowd Control hero",
            role = "cc",
            abilities = {
                {
                    name = "Veil of Despair",
                    description = "Slows enemies 40%, reduces armor",
                    cooldown = 25,
                    duration = 6,
                    effect = function(hero, targets)
                        for _, target in ipairs(targets) do
                            target:addEffect({
                                type = "slow",
                                amount = 0.4,
                                duration = 6
                            })
                            target.armor = target.armor * 0.7
                        end
                    end
                },
                {
                    name = "Dark Binding",
                    description = "Roots and damages enemies",
                    cooldown = 15,
                    duration = 3,
                    effect = function(hero, targets)
                        for _, target in ipairs(targets) do
                            target:addEffect({
                                type = "root",
                                duration = 3
                            })
                            target:takeDamage(30)
                        end
                    end
                },
                {
                    name = "Soul Shackles",
                    description = "Chains enemies together",
                    cooldown = 30,
                    duration = 5,
                    effect = function(hero, targets)
                        for i = 1, #targets - 1 do
                            targets[i]:addEffect({
                                type = "chain",
                                target = targets[i + 1],
                                duration = 5
                            })
                        end
                    end
                }
            },
            passive = {
                name = "Curse Enhancement",
                description = "Enhances curse tower effects",
                effect = function(hero)
                    for _, tower in ipairs(gameState.towers) do
                        if tower.type == "cursed_spire" then
                            tower.curseEffectiveness = tower.curseEffectiveness * 1.3
                        end
                    end
                end
            }
        },
        dark_lord_malak = {
            name = "Dark Lord Malak",
            description = "DPS/Utility hero",
            role = "dps",
            abilities = {
                {
                    name = "Soul Drain",
                    description = "Steals health from multiple enemies",
                    cooldown = 20,
                    duration = 5,
                    effect = function(hero, targets)
                        for _, target in ipairs(targets) do
                            local damage = 30
                            target:takeDamage(damage)
                            hero:heal(damage * 0.5)
                        end
                    end
                },
                {
                    name = "Shadow Step",
                    description = "Teleport to target location",
                    cooldown = 15,
                    duration = 1,
                    effect = function(hero, targets)
                        if #targets > 0 then
                            hero.x = targets[1].x
                            hero.y = targets[1].y
                        end
                    end
                },
                {
                    name = "Death Nova",
                    description = "Area damage and slow",
                    cooldown = 25,
                    duration = 4,
                    effect = function(hero, targets)
                        for _, target in ipairs(targets) do
                            target:takeDamage(50)
                            target:addEffect({
                                type = "slow",
                                amount = 0.3,
                                duration = 4
                            })
                        end
                    end
                }
            },
            passive = {
                name = "Life Steal",
                description = "+20% lifesteal",
                effect = function(hero)
                    hero.lifeSteal = 0.2
                end
            }
        }
    },
    twilight = {
        zephyr = {
            name = "Zephyr",
            description = "Hybrid DPS hero",
            role = "dps",
            abilities = {
                {
                    name = "Dusk Shift",
                    description = "Toggle +30% damage or +30% lifesteal",
                    cooldown = 0,
                    duration = 0,
                    effect = function(hero, targets)
                        hero.damageMode = not hero.damageMode
                        if hero.damageMode then
                            hero.damageBoost = 0.3
                            hero.lifeSteal = 0
                        else
                            hero.damageBoost = 0
                            hero.lifeSteal = 0.3
                        end
                    end
                },
                {
                    name = "Elemental Burst",
                    description = "Alternates between fire/ice damage",
                    cooldown = 15,
                    duration = 1,
                    effect = function(hero, targets)
                        hero.elementalMode = not hero.elementalMode
                        for _, target in ipairs(targets) do
                            if hero.elementalMode then
                                target:addEffect({
                                    type = "burn",
                                    damage = 20,
                                    duration = 3
                                })
                            else
                                target:addEffect({
                                    type = "freeze",
                                    duration = 2
                                })
                            end
                        end
                    end
                },
                {
                    name = "Primal Storm",
                    description = "Area damage and crowd control",
                    cooldown = 30,
                    duration = 5,
                    effect = function(hero, targets)
                        for _, target in ipairs(targets) do
                            target:takeDamage(40)
                            target:addEffect({
                                type = "stun",
                                duration = 2
                            })
                        end
                    end
                }
            },
            passive = {
                name = "Hybrid Mastery",
                description = "Buffs hybrid towers",
                effect = function(hero)
                    for _, tower in ipairs(gameState.towers) do
                        if tower.hybridDamage then
                            tower.damage = tower.damage * 1.2
                        end
                    end
                end
            }
        },
        lyra = {
            name = "Lyra",
            description = "Buffer/Debuff hero",
            role = "support",
            abilities = {
                {
                    name = "Equilibrium Wave",
                    description = "Ally damage +15%, reduces enemy resistance",
                    cooldown = 18,
                    duration = 6,
                    effect = function(hero, targets)
                        for _, target in ipairs(targets) do
                            if target.isEnemy then
                                target.resistance = target.resistance * 0.8
                            else
                                target.damageBoost = 0.15
                            end
                        end
                    end
                },
                {
                    name = "Nature's Blessing",
                    description = "Heals and buffs nearby towers",
                    cooldown = 20,
                    duration = 5,
                    effect = function(hero, targets)
                        for _, target in ipairs(targets) do
                            target:heal(40)
                            target.attackSpeed = target.attackSpeed * 1.2
                        end
                    end
                },
                {
                    name = "Primal Rage",
                    description = "Temporary damage boost",
                    cooldown = 25,
                    duration = 4,
                    effect = function(hero, targets)
                        for _, target in ipairs(targets) do
                            target.damageBoost = 0.3
                        end
                    end
                }
            },
            passive = {
                name = "Fusion Mastery",
                description = "Unlocks fusion tower abilities",
                effect = function(hero)
                    for _, tower in ipairs(gameState.towers) do
                        if tower.type == "elemental_nexus" then
                            tower.fusionEnabled = true
                        end
                    end
                end
            }
        },
        elemental_sage = {
            name = "Elemental Sage",
            description = "Elemental DPS hero",
            role = "dps",
            abilities = {
                {
                    name = "Elemental Burst",
                    description = "Alternates between fire/ice damage",
                    cooldown = 15,
                    duration = 1,
                    effect = function(hero, targets)
                        hero.elementalMode = not hero.elementalMode
                        for _, target in ipairs(targets) do
                            if hero.elementalMode then
                                target:addEffect({
                                    type = "burn",
                                    damage = 25,
                                    duration = 3
                                })
                            else
                                target:addEffect({
                                    type = "freeze",
                                    duration = 2
                                })
                            end
                        end
                    end
                },
                {
                    name = "Nature's Blessing",
                    description = "Heals and buffs nearby towers",
                    cooldown = 20,
                    duration = 5,
                    effect = function(hero, targets)
                        for _, target in ipairs(targets) do
                            target:heal(40)
                            target.attackSpeed = target.attackSpeed * 1.2
                        end
                    end
                },
                {
                    name = "Primal Storm",
                    description = "Area damage and crowd control",
                    cooldown = 30,
                    duration = 5,
                    effect = function(hero, targets)
                        for _, target in ipairs(targets) do
                            target:takeDamage(40)
                            target:addEffect({
                                type = "stun",
                                duration = 2
                            })
                        end
                    end
                }
            },
            passive = {
                name = "Elemental Mastery",
                description = "+25% elemental damage",
                effect = function(hero)
                    hero.elementalDamage = 0.25
                end
            }
        }
    }
}

-- Tower presets
local TOWER_PRESETS = {
    radiant = {
        holy_bastion = {
            name = "Holy Bastion",
            description = "Healing and support tower",
            cost = 100,
            damage = 20,
            attackSpeed = 1,
            range = 150,
            healAmount = 5,
            healInterval = 1,
            upgradePaths = {
                {
                    name = "Divine Light",
                    description = "Increases heal amount by 50%",
                    cost = 150,
                    effect = function(tower)
                        tower.healAmount = tower.healAmount * 1.5
                    end
                },
                {
                    name = "Blessed Aura",
                    description = "Increases heal range by 50%",
                    cost = 200,
                    effect = function(tower)
                        tower.range = tower.range * 1.5
                    end
                }
            }
        },
        seraphim_altar = {
            name = "Seraphim Altar",
            description = "Burning damage tower",
            cost = 200,
            damage = 45,
            attackSpeed = 0.8,
            range = 180,
            burnDamage = 10,
            burnDuration = 3,
            upgradePaths = {
                {
                    name = "Divine Flame",
                    description = "Increases burn damage by 50%",
                    cost = 300,
                    effect = function(tower)
                        tower.burnDamage = tower.burnDamage * 1.5
                    end
                },
                {
                    name = "Holy Inferno",
                    description = "Increases burn duration by 50%",
                    cost = 250,
                    effect = function(tower)
                        tower.burnDuration = tower.burnDuration * 1.5
                    end
                }
            }
        },
        seraphs_watch = {
            name = "Seraph's Watch",
            description = "Long-range sniper tower",
            cost = 300,
            damage = 80,
            attackSpeed = 0.5,
            range = 300,
            criticalChance = 0.2,
            criticalMultiplier = 2,
            upgradePaths = {
                {
                    name = "Divine Mark",
                    description = "Marks enemies for increased damage",
                    cost = 400,
                    effect = function(tower)
                        tower.markDamage = 1.5
                    end
                },
                {
                    name = "Holy Precision",
                    description = "Guaranteed critical hits",
                    cost = 450,
                    effect = function(tower)
                        tower.criticalChance = 1
                    end
                }
            }
        }
    },
    shadow = {
        cursed_spire = {
            name = "Cursed Spire",
            description = "Poison damage tower",
            cost = 100,
            damage = 18,
            attackSpeed = 1,
            range = 160,
            poisonDamage = 3,
            poisonDuration = 3,
            upgradePaths = {
                {
                    name = "Venomous",
                    description = "Increases poison damage by 50%",
                    cost = 150,
                    effect = function(tower)
                        tower.poisonDamage = tower.poisonDamage * 1.5
                    end
                },
                {
                    name = "Plague",
                    description = "Increases poison duration by 50%",
                    cost = 200,
                    effect = function(tower)
                        tower.poisonDuration = tower.poisonDuration * 1.5
                    end
                }
            }
        },
        oblivion_engine = {
            name = "Oblivion Engine",
            description = "Summoning tower",
            cost = 200,
            damage = 50,
            attackSpeed = 0.7,
            range = 200,
            summonInterval = 20,
            maxMinions = 1,
            upgradePaths = {
                {
                    name = "Soul Harvester",
                    description = "Increases minion spawn rate",
                    cost = 300,
                    effect = function(tower)
                        tower.summonInterval = tower.summonInterval * 0.7
                    end
                },
                {
                    name = "Necromancer",
                    description = "Increases max minions",
                    cost = 250,
                    effect = function(tower)
                        tower.maxMinions = tower.maxMinions + 1
                    end
                }
            }
        },
        soul_forge = {
            name = "Soul Forge",
            description = "Converts dead enemies into minions",
            cost = 350,
            damage = 60,
            attackSpeed = 0.8,
            range = 140,
            minionSpawnChance = 0.2,
            minionHealth = 50,
            minionDamage = 10,
            minionSpeed = 1.5,
            upgradePaths = {
                {
                    name = "Soul Harvest",
                    description = "Increases minion spawn chance by 50%",
                    cost = 400,
                    effect = function(tower)
                        tower.minionSpawnChance = tower.minionSpawnChance * 1.5
                    end
                },
                {
                    name = "Necrotic Aura",
                    description = "Damages nearby enemies",
                    cost = 450,
                    effect = function(tower)
                        tower.auraDamage = 10
                        tower.auraRange = 100
                    end
                }
            }
        }
    },
    twilight = {
        dawn_dusk_nexus = {
            name = "Dawn-Dusk Nexus",
            description = "Hybrid damage tower",
            cost = 100,
            damage = 25,
            attackSpeed = 1,
            range = 170,
            hybridDamage = true,
            lightDamage = 15,
            darkDamage = 10,
            upgradePaths = {
                {
                    name = "Balance",
                    description = "Increases both damage types",
                    cost = 150,
                    effect = function(tower)
                        tower.lightDamage = tower.lightDamage * 1.3
                        tower.darkDamage = tower.darkDamage * 1.3
                    end
                },
                {
                    name = "Eclipse",
                    description = "Alternates between light/dark",
                    cost = 200,
                    effect = function(tower)
                        tower.alternatingDamage = true
                    end
                }
            }
        },
        eclipse_monolith = {
            name = "Eclipse Monolith",
            description = "Draining damage tower",
            cost = 200,
            damage = 40,
            attackSpeed = 0.6,
            range = 190,
            drainPercent = 0.02,
            drainInterval = 1,
            upgradePaths = {
                {
                    name = "Void Walker",
                    description = "Increases drain amount",
                    cost = 300,
                    effect = function(tower)
                        tower.drainPercent = tower.drainPercent * 1.5
                    end
                },
                {
                    name = "Cosmic Void",
                    description = "Area drain effect",
                    cost = 250,
                    effect = function(tower)
                        tower.areaDrain = true
                        tower.drainRange = 100
                    end
                }
            }
        },
        elemental_nexus = {
            name = "Elemental Nexus",
            description = "Hybrid damage tower",
            cost = 300,
            damage = 45,
            attackSpeed = 1,
            range = 160,
            hybridDamage = true,
            elementalMastery = true,
            upgradePaths = {
                {
                    name = "Elemental Mastery",
                    description = "Increases damage to matching elements",
                    cost = 400,
                    effect = function(tower)
                        tower.elementalBonus = 0.5
                    end
                },
                {
                    name = "Primal Rage",
                    description = "Temporary damage boost",
                    cost = 450,
                    effect = function(tower)
                        tower.rageDamage = 1.5
                        tower.rageDuration = 5
                    end
                }
            }
        }
    }
}

function Faction.new(factionType)
    local self = setmetatable({}, Faction)
    
    self.type = factionType
    self.heroes = {}
    self.towers = {}
    
    -- Initialize heroes and towers based on faction
    self:initializeFaction()
    
    return self
end

function Faction:initializeFaction()
    -- Initialize heroes
    for heroId, heroData in pairs(HERO_PRESETS[self.type]) do
        table.insert(self.heroes, {
            id = heroId,
            data = heroData,
            level = 1,
            experience = 0,
            abilities = table.copy(heroData.abilities),
            passive = heroData.passive
        })
    end
    
    -- Initialize towers
    for towerId, towerData in pairs(TOWER_PRESETS[self.type]) do
        table.insert(self.towers, {
            id = towerId,
            data = towerData,
            unlocked = true
        })
    end
end

function Faction:getHero(heroId)
    for _, hero in ipairs(self.heroes) do
        if hero.id == heroId then
            return hero
        end
    end
    return nil
end

function Faction:getTower(towerId)
    for _, tower in ipairs(self.towers) do
        if tower.id == towerId then
            return tower
        end
    end
    return nil
end

function Faction:unlockTower(towerId)
    local tower = self:getTower(towerId)
    if tower then
        tower.unlocked = true
        return true
    end
    return false
end

function Faction:levelUpHero(heroId)
    local hero = self:getHero(heroId)
    if not hero then return false end
    
    if hero.level >= 10 then return false end
    
    hero.level = hero.level + 1
    hero.experience = 0
    
    -- Apply level-up effects
    if hero.data.passive then
        hero.data.passive.effect(hero)
    end
    
    return true
end

function Faction:addExperience(heroId, amount)
    local hero = self:getHero(heroId)
    if not hero then return false end
    
    hero.experience = hero.experience + amount
    
    -- Check for level up
    if hero.experience >= 200 then
        self:levelUpHero(heroId)
    end
    
    return true
end

function Faction:getFactionBonus()
    local bonuses = {
        radiant = {
            towerDamage = 0.1,
            heroHealing = 0.05
        },
        shadow = {
            poisonDamage = 0.15,
            minionHealth = 0.1
        },
        twilight = {
            hybridDamage = 0.1,
            heroAbilityDuration = 0.05
        }
    }
    
    return bonuses[self.type]
end

return Faction 