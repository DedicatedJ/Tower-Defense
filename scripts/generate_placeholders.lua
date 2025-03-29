local function createPlaceholderImage(width, height, color, text)
    local imageData = love.image.newImageData(width, height)
    
    -- Fill with color
    for y = 0, height - 1 do
        for x = 0, width - 1 do
            imageData:setPixel(x, y, color[1], color[2], color[3], color[4])
        end
    end
    
    -- Create image
    local image = love.graphics.newImage(imageData)
    
    -- Create canvas for text
    local canvas = love.graphics.newCanvas(width, height)
    love.graphics.setCanvas(canvas)
    
    -- Draw text
    love.graphics.setColor(1, 1, 1, 1)
    local font = love.graphics.newFont(14)
    love.graphics.setFont(font)
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text, 
        (width - textWidth) / 2,
        (height - textHeight) / 2)
    
    -- Reset canvas
    love.graphics.setCanvas()
    
    return canvas
end

-- Create directories if they don't exist
local directories = {
    'sprites/ui/backgrounds',
    'sprites/ui/buttons',
    'sprites/ui/icons',
    'sprites/ui/panels',
    'sprites/ui/effects'
}

for _, dir in ipairs(directories) do
    os.execute('mkdir -p ' .. dir)
end

-- Generate placeholder images
local placeholders = {
    -- Backgrounds (1920x1080)
    ['sprites/ui/backgrounds/menu.png'] = {1920, 1080, {0.1, 0.1, 0.2, 1}, "Menu Background"},
    ['sprites/ui/backgrounds/game.png'] = {1920, 1080, {0.05, 0.05, 0.1, 1}, "Game Background"},
    ['sprites/ui/backgrounds/pause.png'] = {1920, 1080, {0, 0, 0, 0.7}, "Pause Background"},
    ['sprites/ui/backgrounds/faction_select.png'] = {1920, 1080, {0.15, 0.15, 0.25, 1}, "Faction Select Background"},
    
    -- Buttons (200x40)
    ['sprites/ui/buttons/normal.png'] = {200, 40, {0.2, 0.2, 0.3, 1}, "Normal Button"},
    ['sprites/ui/buttons/hover.png'] = {200, 40, {0.3, 0.3, 0.4, 1}, "Hover Button"},
    ['sprites/ui/buttons/pressed.png'] = {200, 40, {0.1, 0.1, 0.2, 1}, "Pressed Button"},
    ['sprites/ui/buttons/disabled.png'] = {200, 40, {0.1, 0.1, 0.1, 0.5}, "Disabled Button"},
    
    -- Icons (32x32)
    ['sprites/ui/icons/gold.png'] = {32, 32, {1, 0.84, 0, 1}, "Gold"},
    ['sprites/ui/icons/lives.png'] = {32, 32, {1, 0, 0, 1}, "Lives"},
    ['sprites/ui/icons/wave.png'] = {32, 32, {0, 0.8, 1, 1}, "Wave"},
    ['sprites/ui/icons/tower_arrow.png'] = {32, 32, {0.8, 0.8, 0.8, 1}, "Arrow Tower"},
    ['sprites/ui/icons/tower_cannon.png'] = {32, 32, {0.6, 0.6, 0.6, 1}, "Cannon Tower"},
    ['sprites/ui/icons/tower_magic.png'] = {32, 32, {0.8, 0, 0.8, 1}, "Magic Tower"},
    ['sprites/ui/icons/hero_radiant.png'] = {32, 32, {1, 1, 0.8, 1}, "Radiant Hero"},
    ['sprites/ui/icons/hero_shadow.png'] = {32, 32, {0.2, 0.2, 0.3, 1}, "Shadow Hero"},
    ['sprites/ui/icons/hero_twilight.png'] = {32, 32, {0.4, 0.4, 0.6, 1}, "Twilight Hero"},
    ['sprites/ui/icons/ability_1.png'] = {32, 32, {1, 0.5, 0, 1}, "Ability 1"},
    ['sprites/ui/icons/ability_2.png'] = {32, 32, {0, 0.5, 1, 1}, "Ability 2"},
    ['sprites/ui/icons/ability_3.png'] = {32, 32, {0.5, 0, 1, 1}, "Ability 3"},
    ['sprites/ui/icons/ability_4.png'] = {32, 32, {1, 0, 0.5, 1}, "Ability 4"},
    
    -- Achievement icons (64x64)
    ['sprites/ui/icons/achievement_first_win.png'] = {64, 64, {1, 0.84, 0, 1}, "First Win"},
    ['sprites/ui/icons/achievement_tower_master.png'] = {64, 64, {0.8, 0.8, 0.8, 1}, "Tower Master"},
    ['sprites/ui/icons/achievement_hero_legend.png'] = {64, 64, {1, 1, 0.8, 1}, "Hero Legend"},
    ['sprites/ui/icons/achievement_perfect_run.png'] = {64, 64, {0, 1, 0, 1}, "Perfect Run"},
    ['sprites/ui/icons/achievement_wealthy.png'] = {64, 64, {1, 0.84, 0, 1}, "Wealthy"},
    ['sprites/ui/icons/achievement_wave_master.png'] = {64, 64, {0, 0.8, 1, 1}, "Wave Master"},
    ['sprites/ui/icons/achievement_faction_master.png'] = {64, 64, {0.8, 0, 0.8, 1}, "Faction Master"},
    ['sprites/ui/icons/achievement_speed_demon.png'] = {64, 64, {1, 0, 0, 1}, "Speed Demon"},
    
    -- Panels (300x200)
    ['sprites/ui/panels/info.png'] = {300, 200, {0.1, 0.1, 0.2, 0.8}, "Info Panel"},
    ['sprites/ui/panels/stats.png'] = {300, 200, {0.1, 0.1, 0.2, 0.8}, "Stats Panel"},
    ['sprites/ui/panels/inventory.png'] = {300, 200, {0.1, 0.1, 0.2, 0.8}, "Inventory Panel"},
    ['sprites/ui/panels/shop.png'] = {300, 200, {0.1, 0.1, 0.2, 0.8}, "Shop Panel"},
    
    -- Effects (64x64)
    ['sprites/ui/effects/highlight.png'] = {64, 64, {1, 1, 1, 0.3}, "Highlight"},
    ['sprites/ui/effects/glow.png'] = {64, 64, {0.8, 0.8, 1, 0.2}, "Glow"},
    ['sprites/ui/effects/pulse.png'] = {64, 64, {1, 0.8, 0, 0.2}, "Pulse"}
}

-- Generate each placeholder
for path, data in pairs(placeholders) do
    local width, height, color, text = unpack(data)
    local image = createPlaceholderImage(width, height, color, text)
    image:encode('png', path)
    print("Generated: " .. path)
end

print("All placeholder images generated successfully!") 