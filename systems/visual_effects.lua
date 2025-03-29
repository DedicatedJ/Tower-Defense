local VisualEffects = {}
VisualEffects.__index = VisualEffects

-- Particle presets
local PARTICLE_PRESETS = {
    weather = {
        rain = {
            image = "particles/rain.png",
            buffer = 100,
            lifetime = {1, 2},
            emissionRate = 100,
            speed = {100, 200},
            acceleration = {0, 100},
            rotation = {0, 360},
            size = {0.5, 1},
            color = {0.7, 0.7, 0.7, 0.5}
        },
        snow = {
            image = "particles/snow.png",
            buffer = 50,
            lifetime = {2, 4},
            emissionRate = 30,
            speed = {20, 50},
            acceleration = {0, 0},
            rotation = {0, 360},
            size = {0.3, 0.8},
            color = {1, 1, 1, 0.8}
        },
        fog = {
            image = "particles/fog.png",
            buffer = 20,
            lifetime = {5, 8},
            emissionRate = 5,
            speed = {10, 20},
            acceleration = {0, 0},
            rotation = {0, 0},
            size = {2, 4},
            color = {0.8, 0.8, 0.8, 0.3}
        }
    },
    faction = {
        radiant = {
            attack = {
                image = "particles/holy_light.png",
                buffer = 20,
                lifetime = {0.5, 1},
                emissionRate = 50,
                speed = {100, 200},
                acceleration = {0, 0},
                rotation = {0, 360},
                size = {0.5, 1.5},
                color = {1, 1, 0.8, 0.8}
            },
            idle = {
                image = "particles/holy_aura.png",
                buffer = 10,
                lifetime = {1, 2},
                emissionRate = 10,
                speed = {0, 0},
                acceleration = {0, 0},
                rotation = {0, 360},
                size = {1, 2},
                color = {1, 1, 0.8, 0.3}
            }
        },
        shadow = {
            attack = {
                image = "particles/shadow_bolt.png",
                buffer = 20,
                lifetime = {0.5, 1},
                emissionRate = 50,
                speed = {100, 200},
                acceleration = {0, 0},
                rotation = {0, 360},
                size = {0.5, 1.5},
                color = {0.2, 0.2, 0.2, 0.8}
            },
            idle = {
                image = "particles/shadow_aura.png",
                buffer = 10,
                lifetime = {1, 2},
                emissionRate = 10,
                speed = {0, 0},
                acceleration = {0, 0},
                rotation = {0, 360},
                size = {1, 2},
                color = {0.2, 0.2, 0.2, 0.3}
            }
        },
        twilight = {
            attack = {
                image = "particles/elemental_blast.png",
                buffer = 20,
                lifetime = {0.5, 1},
                emissionRate = 50,
                speed = {100, 200},
                acceleration = {0, 0},
                rotation = {0, 360},
                size = {0.5, 1.5},
                color = {0.5, 0.5, 0.5, 0.8}
            },
            idle = {
                image = "particles/elemental_aura.png",
                buffer = 10,
                lifetime = {1, 2},
                emissionRate = 10,
                speed = {0, 0},
                acceleration = {0, 0},
                rotation = {0, 360},
                size = {1, 2},
                color = {0.5, 0.5, 0.5, 0.3}
            }
        }
    },
    enemy = {
        death = {
            image = "particles/death.png",
            buffer = 30,
            lifetime = {0.5, 1},
            emissionRate = 100,
            speed = {50, 150},
            acceleration = {0, -100},
            rotation = {0, 360},
            size = {0.5, 1.5},
            color = {0.8, 0.2, 0.2, 0.8}
        },
        hit = {
            image = "particles/hit.png",
            buffer = 10,
            lifetime = {0.2, 0.5},
            emissionRate = 20,
            speed = {20, 50},
            acceleration = {0, 0},
            rotation = {0, 360},
            size = {0.3, 0.8},
            color = {1, 1, 1, 0.8}
        }
    }
}

-- Animation presets
local ANIMATION_PRESETS = {
    tower = {
        placement = {
            duration = 0.5,
            scale = {0, 1},
            rotation = {0, 0},
            alpha = {0, 1}
        },
        upgrade = {
            duration = 0.3,
            scale = {1, 1.2, 1},
            rotation = {0, 0},
            alpha = {1, 1}
        },
        attack = {
            duration = 0.2,
            scale = {1, 1.1, 1},
            rotation = {0, 0},
            alpha = {1, 1}
        }
    },
    enemy = {
        death = {
            duration = 0.5,
            scale = {1, 0},
            rotation = {0, 360},
            alpha = {1, 0}
        },
        hit = {
            duration = 0.1,
            scale = {1, 0.9, 1},
            rotation = {0, 0},
            alpha = {1, 1}
        }
    }
}

function VisualEffects.new()
    local self = setmetatable({}, VisualEffects)
    
    self.particles = {}
    self.animations = {}
    self.flashEffects = {}
    self.trails = {}
    self.lights = {}
    self.weather = nil
    
    return self
end

function VisualEffects:createParticleSystem(preset, x, y)
    local system = {
        x = x,
        y = y,
        preset = preset,
        particles = {},
        active = true,
        time = 0
    }
    
    table.insert(self.particles, system)
    return system
end

function VisualEffects:createAnimation(preset, target, properties)
    local animation = {
        preset = preset,
        target = target,
        properties = properties,
        time = 0,
        active = true
    }
    
    table.insert(self.animations, animation)
    return animation
end

function VisualEffects:createFlashEffect(x, y, color, duration)
    local flash = {
        x = x,
        y = y,
        color = color,
        duration = duration,
        time = 0,
        alpha = 1
    }
    
    table.insert(self.flashEffects, flash)
    return flash
end

function VisualEffects:createTrail(x, y, color, duration)
    local trail = {
        points = {{x = x, y = y}},
        color = color,
        duration = duration,
        time = 0,
        maxPoints = 10
    }
    
    table.insert(self.trails, trail)
    return trail
end

function VisualEffects:createLight(x, y, radius, color, intensity)
    local light = {
        x = x,
        y = y,
        radius = radius,
        color = color,
        intensity = intensity,
        active = true
    }
    
    table.insert(self.lights, light)
    return light
end

function VisualEffects:setWeather(weatherType)
    if self.weather then
        self.weather.active = false
    end
    
    if weatherType then
        self.weather = self:createParticleSystem(PARTICLE_PRESETS.weather[weatherType], 0, 0)
    end
end

function VisualEffects:update(dt)
    -- Update particles
    for i = #self.particles, 1, -1 do
        local system = self.particles[i]
        if not system.active then
            table.remove(self.particles, i)
        else
            system.time = system.time + dt
            self:updateParticleSystem(system, dt)
        end
    end
    
    -- Update animations
    for i = #self.animations, 1, -1 do
        local animation = self.animations[i]
        if not animation.active then
            table.remove(self.animations, i)
        else
            animation.time = animation.time + dt
            self:updateAnimation(animation, dt)
        end
    end
    
    -- Update flash effects
    for i = #self.flashEffects, 1, -1 do
        local flash = self.flashEffects[i]
        flash.time = flash.time + dt
        flash.alpha = 1 - (flash.time / flash.duration)
        
        if flash.time >= flash.duration then
            table.remove(self.flashEffects, i)
        end
    end
    
    -- Update trails
    for i = #self.trails, 1, -1 do
        local trail = self.trails[i]
        trail.time = trail.time + dt
        
        if trail.time >= trail.duration then
            table.remove(self.trails, i)
        end
    end
end

function VisualEffects:updateParticleSystem(system, dt)
    local preset = system.preset
    
    -- Emit new particles
    local emissionCount = math.floor(preset.emissionRate * dt)
    for i = 1, emissionCount do
        local particle = {
            x = system.x,
            y = system.y,
            lifetime = love.math.random(preset.lifetime[1], preset.lifetime[2]),
            time = 0,
            speed = love.math.random(preset.speed[1], preset.speed[2]),
            angle = love.math.random(0, 360),
            rotation = love.math.random(preset.rotation[1], preset.rotation[2]),
            size = love.math.random(preset.size[1], preset.size[2]),
            color = {unpack(preset.color)}
        }
        
        table.insert(system.particles, particle)
    end
    
    -- Update existing particles
    for i = #system.particles, 1, -1 do
        local particle = system.particles[i]
        particle.time = particle.time + dt
        
        -- Update position
        particle.x = particle.x + math.cos(math.rad(particle.angle)) * particle.speed * dt
        particle.y = particle.y + math.sin(math.rad(particle.angle)) * particle.speed * dt
        
        -- Update rotation
        particle.rotation = particle.rotation + preset.rotation[2] * dt
        
        -- Update size
        particle.size = particle.size * (1 - (particle.time / particle.lifetime))
        
        -- Update alpha
        particle.color[4] = preset.color[4] * (1 - (particle.time / particle.lifetime))
        
        -- Remove dead particles
        if particle.time >= particle.lifetime then
            table.remove(system.particles, i)
        end
    end
end

function VisualEffects:updateAnimation(animation, dt)
    local preset = animation.preset
    local progress = animation.time / preset.duration
    
    if progress >= 1 then
        animation.active = false
        return
    end
    
    -- Update scale
    if preset.scale then
        local scale = self:interpolate(preset.scale, progress)
        animation.target.scale = scale
    end
    
    -- Update rotation
    if preset.rotation then
        local rotation = self:interpolate(preset.rotation, progress)
        animation.target.rotation = rotation
    end
    
    -- Update alpha
    if preset.alpha then
        local alpha = self:interpolate(preset.alpha, progress)
        animation.target.alpha = alpha
    end
end

function VisualEffects:interpolate(values, progress)
    if #values == 1 then return values[1] end
    
    local segment = progress * (#values - 1)
    local index = math.floor(segment)
    local t = segment - index
    
    if index >= #values - 1 then
        return values[#values]
    end
    
    return values[index + 1] * (1 - t) + values[index + 2] * t
end

function VisualEffects:draw()
    -- Draw weather particles
    if self.weather then
        self:drawParticleSystem(self.weather)
    end
    
    -- Draw regular particles
    for _, system in ipairs(self.particles) do
        if system ~= self.weather then
            self:drawParticleSystem(system)
        end
    end
    
    -- Draw trails
    for _, trail in ipairs(self.trails) do
        love.graphics.setColor(trail.color)
        love.graphics.setLineWidth(2)
        for i = 1, #trail.points - 1 do
            love.graphics.line(trail.points[i].x, trail.points[i].y,
                             trail.points[i + 1].x, trail.points[i + 1].y)
        end
    end
    
    -- Draw flash effects
    for _, flash in ipairs(self.flashEffects) do
        love.graphics.setColor(flash.color[1], flash.color[2], flash.color[3], flash.alpha)
        love.graphics.circle("fill", flash.x, flash.y, 50)
    end
    
    -- Draw lights
    for _, light in ipairs(self.lights) do
        if light.active then
            love.graphics.setColor(light.color[1], light.color[2], light.color[3], light.intensity)
            love.graphics.circle("fill", light.x, light.y, light.radius)
        end
    end
end

function VisualEffects:drawParticleSystem(system)
    for _, particle in ipairs(system.particles) do
        love.graphics.setColor(particle.color)
        love.graphics.draw(system.preset.image, particle.x, particle.y,
                          math.rad(particle.rotation), particle.size, particle.size)
    end
end

function VisualEffects:createParticle(x, y, color, size, speed, angle, life)
    table.insert(self.particles, {
        x = x,
        y = y,
        color = color,
        size = size,
        vx = math.cos(angle) * speed,
        vy = math.sin(angle) * speed,
        life = life,
        maxLife = life,
        alpha = 1
    })
end

function VisualEffects:createExplosion(x, y, color, size, particleCount)
    for i = 1, particleCount do
        local angle = (i / particleCount) * math.pi * 2
        local speed = size * (0.5 + math.random() * 0.5)
        local life = 0.5 + math.random() * 0.5
        self:createParticle(x, y, color, size * 0.5, speed, angle, life)
    end
end

function VisualEffects:createTowerPlacementEffect(x, y, color)
    local particleCount = 20
    for i = 1, particleCount do
        local angle = (i / particleCount) * math.pi * 2
        local speed = 50
        local life = 0.3 + math.random() * 0.2
        self:createParticle(x, y, color, 2, speed, angle, life)
    end
end

function VisualEffects:createTowerUpgradeEffect(x, y, color)
    local particleCount = 30
    for i = 1, particleCount do
        local angle = (i / particleCount) * math.pi * 2
        local speed = 100
        local life = 0.5 + math.random() * 0.3
        self:createParticle(x, y, color, 3, speed, angle, life)
    end
end

function VisualEffects:createEnemyDeathEffect(x, y, color)
    local particleCount = 15
    for i = 1, particleCount do
        local angle = (i / particleCount) * math.pi * 2
        local speed = 75
        local life = 0.4 + math.random() * 0.2
        self:createParticle(x, y, color, 2, speed, angle, life)
    end
end

function VisualEffects:startScreenShake(intensity, duration)
    self.screenShake.active = true
    self.screenShake.intensity = intensity
    self.screenShake.duration = duration
    self.screenShake.timer = 0
end

function VisualEffects:startFlash(color, duration)
    self.flash.active = true
    self.flash.color = color
    self.flash.duration = duration
    self.flash.timer = 0
end

function VisualEffects:startTrail(color, maxPoints)
    self.trail.active = true
    self.trail.color = color
    self.trail.maxPoints = maxPoints or 50
    self.trail.points = {}
end

function VisualEffects:stopTrail()
    self.trail.active = false
    self.trail.points = {}
end

function VisualEffects:createDamageNumber(x, y, damage, color)
    local text = tostring(math.floor(damage))
    local font = love.graphics.getFont()
    local width = font:getWidth(text)
    local height = font:getHeight()
    
    table.insert(self.particles, {
        x = x - width/2,
        y = y - height/2,
        text = text,
        color = color,
        life = 1,
        maxLife = 1,
        alpha = 1,
        vy = -50 -- Float upward
    })
end

function VisualEffects:createHealEffect(x, y, amount, color)
    local text = "+" .. tostring(math.floor(amount))
    local font = love.graphics.getFont()
    local width = font:getWidth(text)
    local height = font:getHeight()
    
    table.insert(self.particles, {
        x = x - width/2,
        y = y - height/2,
        text = text,
        color = color,
        life = 1,
        maxLife = 1,
        alpha = 1,
        vy = -50 -- Float upward
    })
end

function VisualEffects:createAbilityEffect(x, y, radius, color, duration)
    local particleCount = 40
    for i = 1, particleCount do
        local angle = (i / particleCount) * math.pi * 2
        local speed = radius * 2
        local life = duration
        self:createParticle(x, y, color, 4, speed, angle, life)
    end
end

return VisualEffects 