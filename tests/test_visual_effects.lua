local Test = require("tests.test_utils")
local VisualEffects = require("systems.visual_effects")

local function test_effects_initialization()
    local effects = VisualEffects.new()
    Test.assert_not_nil(effects, "Visual effects system should be created")
    Test.assert_not_nil(effects.particles, "Visual effects should have particle systems")
    Test.assert_not_nil(effects.animations, "Visual effects should have animations")
    Test.assert_not_nil(effects.flashes, "Visual effects should have flash effects")
    Test.assert_not_nil(effects.trails, "Visual effects should have trails")
    Test.assert_not_nil(effects.lights, "Visual effects should have lights")
end

local function test_particle_systems()
    local effects = VisualEffects.new()
    
    -- Test weather effects
    local rain = effects:createParticleSystem("rain")
    Test.assert_not_nil(rain, "Rain particle system should be created")
    Test.assert_equals(rain:getParticleLifetime(), 2.0, "Rain particles should have correct lifetime")
    
    local snow = effects:createParticleSystem("snow")
    Test.assert_not_nil(snow, "Snow particle system should be created")
    Test.assert_equals(snow:getParticleLifetime(), 3.0, "Snow particles should have correct lifetime")
    
    -- Test faction effects
    local radiantAttack = effects:createParticleSystem("radiant_attack")
    Test.assert_not_nil(radiantAttack, "Radiant attack particles should be created")
    Test.assert_equals(radiantAttack:getParticleLifetime(), 1.5, "Radiant attack particles should have correct lifetime")
    
    local shadowAttack = effects:createParticleSystem("shadow_attack")
    Test.assert_not_nil(shadowAttack, "Shadow attack particles should be created")
    Test.assert_equals(shadowAttack:getParticleLifetime(), 1.5, "Shadow attack particles should have correct lifetime")
end

local function test_animations()
    local effects = VisualEffects.new()
    
    -- Test tower animations
    local placementAnim = effects:createAnimation("tower_placement", 100, 100)
    Test.assert_not_nil(placementAnim, "Tower placement animation should be created")
    Test.assert_equals(placementAnim.x, 100, "Animation should have correct x position")
    Test.assert_equals(placementAnim.y, 100, "Animation should have correct y position")
    
    local upgradeAnim = effects:createAnimation("tower_upgrade", 150, 150)
    Test.assert_not_nil(upgradeAnim, "Tower upgrade animation should be created")
    Test.assert_equals(upgradeAnim.x, 150, "Animation should have correct x position")
    Test.assert_equals(upgradeAnim.y, 150, "Animation should have correct y position")
    
    -- Test enemy animations
    local deathAnim = effects:createAnimation("enemy_death", 200, 200)
    Test.assert_not_nil(deathAnim, "Enemy death animation should be created")
    Test.assert_equals(deathAnim.x, 200, "Animation should have correct x position")
    Test.assert_equals(deathAnim.y, 200, "Animation should have correct y position")
end

local function test_flash_effects()
    local effects = VisualEffects.new()
    
    local flash = effects:createFlash(100, 100, 1.0, 1.0, 1.0, 0.5)
    Test.assert_not_nil(flash, "Flash effect should be created")
    Test.assert_equals(flash.x, 100, "Flash should have correct x position")
    Test.assert_equals(flash.y, 100, "Flash should have correct y position")
    Test.assert_equals(flash.r, 1.0, "Flash should have correct red component")
    Test.assert_equals(flash.g, 1.0, "Flash should have correct green component")
    Test.assert_equals(flash.b, 1.0, "Flash should have correct blue component")
    Test.assert_equals(flash.a, 0.5, "Flash should have correct alpha component")
end

local function test_trails()
    local effects = VisualEffects.new()
    
    local trail = effects:createTrail(100, 100, 1.0, 1.0, 1.0, 0.5)
    Test.assert_not_nil(trail, "Trail effect should be created")
    Test.assert_equals(trail.x, 100, "Trail should have correct x position")
    Test.assert_equals(trail.y, 100, "Trail should have correct y position")
    Test.assert_equals(trail.r, 1.0, "Trail should have correct red component")
    Test.assert_equals(trail.g, 1.0, "Trail should have correct green component")
    Test.assert_equals(trail.b, 1.0, "Trail should have correct blue component")
    Test.assert_equals(trail.a, 0.5, "Trail should have correct alpha component")
end

local function test_lights()
    local effects = VisualEffects.new()
    
    local light = effects:createLight(100, 100, 50, 1.0, 1.0, 1.0, 0.5)
    Test.assert_not_nil(light, "Light effect should be created")
    Test.assert_equals(light.x, 100, "Light should have correct x position")
    Test.assert_equals(light.y, 100, "Light should have correct y position")
    Test.assert_equals(light.radius, 50, "Light should have correct radius")
    Test.assert_equals(light.r, 1.0, "Light should have correct red component")
    Test.assert_equals(light.g, 1.0, "Light should have correct green component")
    Test.assert_equals(light.b, 1.0, "Light should have correct blue component")
    Test.assert_equals(light.a, 0.5, "Light should have correct alpha component")
end

local function test_effect_updates()
    local effects = VisualEffects.new()
    
    -- Create some effects
    local particle = effects:createParticleSystem("rain")
    local animation = effects:createAnimation("tower_placement", 100, 100)
    local flash = effects:createFlash(100, 100, 1.0, 1.0, 1.0, 0.5)
    local trail = effects:createTrail(100, 100, 1.0, 1.0, 1.0, 0.5)
    local light = effects:createLight(100, 100, 50, 1.0, 1.0, 1.0, 0.5)
    
    -- Update effects
    effects:update(1.0)
    
    -- Check that effects are still valid
    Test.assert(particle:isActive(), "Particle system should still be active")
    Test.assert(animation:isActive(), "Animation should still be active")
    Test.assert(flash:isActive(), "Flash effect should still be active")
    Test.assert(trail:isActive(), "Trail effect should still be active")
    Test.assert(light:isActive(), "Light effect should still be active")
end

local function test_effect_cleanup()
    local effects = VisualEffects.new()
    
    -- Create some effects
    local particle = effects:createParticleSystem("rain")
    local animation = effects:createAnimation("tower_placement", 100, 100)
    local flash = effects:createFlash(100, 100, 1.0, 1.0, 1.0, 0.5)
    
    -- Clean up effects
    effects:cleanup()
    
    -- Check that effects are removed
    Test.assert(not particle:isActive(), "Particle system should be cleaned up")
    Test.assert(not animation:isActive(), "Animation should be cleaned up")
    Test.assert(not flash:isActive(), "Flash effect should be cleaned up")
end

local function run_tests()
    local tests = {
        test_effects_initialization,
        test_particle_systems,
        test_animations,
        test_flash_effects,
        test_trails,
        test_lights,
        test_effect_updates,
        test_effect_cleanup
    }
    
    local passed = 0
    local failed = 0
    
    for _, test in ipairs(tests) do
        local success, error = pcall(test)
        if success then
            passed = passed + 1
            print("✓ " .. test.name .. " passed")
        else
            failed = failed + 1
            print("✗ " .. test.name .. " failed: " .. error)
        end
    end
    
    print(string.format("\nTest Summary: %d passed, %d failed", passed, failed))
end

return {
    run_tests = run_tests
} 