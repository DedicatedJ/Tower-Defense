local Factions = {
    radiant = {
        name = "Radiant",
        description = "The forces of light and order",
        color = {1, 1, 0.5},
        towers = {
            {
                id = "holy_guardian",
                name = "Holy Guardian",
                description = "A powerful defensive tower that protects nearby allies",
                cost = 200,
                damage = 15,
                range = 150,
                attackSpeed = 1.0,
                sprite = "sprites/towers/magic/holy_guardian.png",
                abilities = {
                    {
                        name = "Divine Shield",
                        description = "Creates a protective shield around nearby towers",
                        cooldown = 15,
                        duration = 5,
                        range = 100
                    }
                },
                upgradePaths = {
                    {
                        name = "Enhanced Protection",
                        cost = 150,
                        effects = {
                            damage = 1.2,
                            range = 1.1,
                            abilityRange = 1.2
                        }
                    },
                    {
                        name = "Divine Blessing",
                        cost = 200,
                        effects = {
                            damage = 1.1,
                            abilityDuration = 1.5
                        }
                    }
                }
            },
            {
                id = "light_bringer",
                name = "Light Bringer",
                description = "A ranged tower that deals holy damage",
                cost = 150,
                damage = 20,
                range = 200,
                attackSpeed = 0.8,
                sprite = "sprites/towers/magic/light_bringer.png",
                abilities = {
                    {
                        name = "Holy Light",
                        description = "Deals massive holy damage to a single target",
                        cooldown = 10,
                        damageMultiplier = 2.0
                    }
                },
                upgradePaths = {
                    {
                        name = "Enhanced Light",
                        cost = 120,
                        effects = {
                            damage = 1.3,
                            range = 1.1
                        }
                    },
                    {
                        name = "Divine Wrath",
                        cost = 180,
                        effects = {
                            damage = 1.2,
                            abilityDamage = 1.5
                        }
                    }
                }
            }
        },
        heroes = {
            {
                id = "paladin",
                name = "Paladin",
                description = "A holy warrior who protects and heals allies",
                cost = 500,
                sprite = "sprites/heroes/radiant/paladin.png",
                abilities = {
                    {
                        name = "Holy Light",
                        description = "Heals nearby towers and deals damage to enemies",
                        cooldown = 20,
                        range = 150,
                        damage = 30,
                        healing = 50
                    },
                    {
                        name = "Divine Shield",
                        description = "Creates a protective barrier around the hero",
                        cooldown = 30,
                        duration = 8,
                        damageReduction = 0.5
                    },
                    {
                        name = "Judgment",
                        description = "Deals massive holy damage to all enemies in range",
                        cooldown = 45,
                        range = 200,
                        damage = 100
                    }
                }
            }
        }
    },
    
    shadow = {
        name = "Shadow",
        description = "The forces of darkness and chaos",
        color = {0.5, 0.5, 1},
        towers = {
            {
                id = "soul_harvester",
                name = "Soul Harvester",
                description = "A tower that steals life from enemies",
                cost = 180,
                damage = 12,
                range = 150,
                attackSpeed = 1.2,
                sprite = "sprites/towers/magic/soul_harvester.png",
                abilities = {
                    {
                        name = "Soul Drain",
                        description = "Steals life from enemies and heals nearby towers",
                        cooldown = 12,
                        range = 100,
                        lifeSteal = 0.3
                    }
                },
                upgradePaths = {
                    {
                        name = "Enhanced Harvesting",
                        cost = 140,
                        effects = {
                            damage = 1.2,
                            lifeSteal = 1.2
                        }
                    },
                    {
                        name = "Soul Explosion",
                        cost = 160,
                        effects = {
                            damage = 1.1,
                            abilityRange = 1.5
                        }
                    }
                }
            },
            {
                id = "void_walker",
                name = "Void Walker",
                description = "A tower that creates void portals",
                cost = 250,
                damage = 25,
                range = 180,
                attackSpeed = 0.9,
                sprite = "sprites/towers/magic/void_walker.png",
                abilities = {
                    {
                        name = "Void Portal",
                        description = "Creates a portal that slows enemies",
                        cooldown = 15,
                        range = 120,
                        slowAmount = 0.5,
                        duration = 5
                    }
                },
                upgradePaths = {
                    {
                        name = "Enhanced Void",
                        cost = 200,
                        effects = {
                            damage = 1.3,
                            slowAmount = 1.2
                        }
                    },
                    {
                        name = "Void Explosion",
                        cost = 250,
                        effects = {
                            damage = 1.2,
                            abilityRange = 1.5
                        }
                    }
                }
            }
        },
        heroes = {
            {
                id = "necromancer",
                name = "Necromancer",
                description = "A dark mage who commands the forces of death",
                cost = 500,
                sprite = "sprites/heroes/shadow/necromancer.png",
                abilities = {
                    {
                        name = "Death Bolt",
                        description = "Fires a bolt of death energy",
                        cooldown = 15,
                        range = 200,
                        damage = 40
                    },
                    {
                        name = "Soul Harvest",
                        description = "Steals life from all enemies in range",
                        cooldown = 25,
                        range = 150,
                        lifeSteal = 0.4
                    },
                    {
                        name = "Death Wave",
                        description = "Releases a wave of death energy",
                        cooldown = 40,
                        range = 250,
                        damage = 80
                    }
                }
            }
        }
    },
    
    twilight = {
        name = "Twilight",
        description = "The forces of balance and harmony",
        color = {1, 0.5, 1},
        towers = {
            {
                id = "balance_keeper",
                name = "Balance Keeper",
                description = "A tower that maintains equilibrium",
                cost = 220,
                damage = 18,
                range = 160,
                attackSpeed = 1.0,
                sprite = "sprites/towers/magic/balance_keeper.png",
                abilities = {
                    {
                        name = "Balance Field",
                        description = "Creates a field that balances damage",
                        cooldown = 18,
                        range = 130,
                        duration = 6,
                        damageReduction = 0.3
                    }
                },
                upgradePaths = {
                    {
                        name = "Enhanced Balance",
                        cost = 170,
                        effects = {
                            damage = 1.2,
                            abilityDuration = 1.3
                        }
                    },
                    {
                        name = "Harmony Field",
                        cost = 220,
                        effects = {
                            damage = 1.1,
                            abilityRange = 1.4
                        }
                    }
                }
            },
            {
                id = "harmony_weaver",
                name = "Harmony Weaver",
                description = "A tower that weaves magical harmony",
                cost = 280,
                damage = 22,
                range = 170,
                attackSpeed = 0.9,
                sprite = "sprites/towers/magic/harmony_weaver.png",
                abilities = {
                    {
                        name = "Harmony Wave",
                        description = "Creates a wave of harmony that buffs allies",
                        cooldown = 20,
                        range = 140,
                        duration = 8,
                        damageBoost = 1.3
                    }
                },
                upgradePaths = {
                    {
                        name = "Enhanced Harmony",
                        cost = 220,
                        effects = {
                            damage = 1.3,
                            abilityDuration = 1.2
                        }
                    },
                    {
                        name = "Harmony Burst",
                        cost = 280,
                        effects = {
                            damage = 1.2,
                            abilityRange = 1.5
                        }
                    }
                }
            }
        },
        heroes = {
            {
                id = "balance_mage",
                name = "Balance Mage",
                description = "A spellcaster who harnesses both light and dark energies",
                cost = 500,
                sprite = "sprites/heroes/twilight/balance_mage.png",
                abilities = {
                    {
                        name = "Twilight Bolt",
                        description = "Fires a bolt of balanced energy",
                        cooldown = 15,
                        range = 200,
                        damage = 35
                    },
                    {
                        name = "Equilibrium",
                        description = "Creates a field of balance that affects all units",
                        cooldown = 25,
                        range = 180,
                        duration = 8
                    },
                    {
                        name = "Cosmic Balance",
                        description = "Unleashes the power of perfect harmony",
                        cooldown = 40,
                        range = 220,
                        damage = 90
                    }
                }
            },
            {
                id = "dream_walker",
                name = "Dream Walker",
                description = "A mystic who travels between realities",
                cost = 550,
                sprite = "sprites/heroes/twilight/dream_walker.png",
                abilities = {
                    {
                        name = "Dream Shift",
                        description = "Phase shifts through reality",
                        cooldown = 12,
                        range = 150,
                        duration = 3
                    },
                    {
                        name = "Astral Projection",
                        description = "Creates an astral copy that attacks enemies",
                        cooldown = 25,
                        duration = 10,
                        damage = 15
                    },
                    {
                        name = "Reality Warp",
                        description = "Warps reality around enemies",
                        cooldown = 40,
                        range = 200,
                        effect = "confusion"
                    }
                }
            }
        }
    }
}

return Factions 