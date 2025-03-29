local UI_ASSETS = {}

-- Helper function to create placeholder image
local function createPlaceholder(width, height, r, g, b, a, text)
    local canvas = love.graphics.newCanvas(width, height)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(r, g, b, a or 1)
    
    -- Add border
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle("line", 0, 0, width, height)
    
    -- Add text if provided
    if text then
        love.graphics.setColor(1, 1, 1, 1)
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(text)
        local textHeight = font:getHeight()
        love.graphics.print(text, (width - textWidth) / 2, (height - textHeight) / 2)
    end
    
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
    return canvas
end

-- Helper function to safely load an image or create a placeholder if not found
local function safeImageLoad(path, width, height, r, g, b, a, text)
    local success, result = pcall(love.graphics.newImage, path)
    if success then
        return result
    else
        print("Warning: Could not load image " .. path .. ", using placeholder instead.")
        return createPlaceholder(width, height, r, g, b, a, text)
    end
end

-- Create backgrounds (using JPGs where available)
UI_ASSETS.backgrounds = {
    menu = safeImageLoad('sprites/ui/backgrounds/menu.jpg', 800, 600, 0.2, 0.3, 0.5, 1, "Menu Background"),
    game = createPlaceholder(800, 600, 0.1, 0.4, 0.2, 1, "Game Background"),
    pause = safeImageLoad('sprites/ui/backgrounds/pause.jpg', 800, 600, 0.3, 0.3, 0.3, 0.8, "Pause Background"),
    faction_select = safeImageLoad('sprites/ui/backgrounds/faction_select.jpg', 800, 600, 0.5, 0.3, 0.1, 1, "Faction Select")
}

-- Create placeholder buttons
UI_ASSETS.buttons = {
    normal = createPlaceholder(200, 50, 0.3, 0.3, 0.7, 1, "Button"),
    hover = createPlaceholder(200, 50, 0.4, 0.4, 0.8, 1, "Button (Hover)"),
    pressed = createPlaceholder(200, 50, 0.2, 0.2, 0.6, 1, "Button (Pressed)"),
    disabled = createPlaceholder(200, 50, 0.5, 0.5, 0.5, 0.7, "Button (Disabled)")
}

-- Create placeholder icons
UI_ASSETS.icons = {
    -- Resource icons
    gold = createPlaceholder(32, 32, 1, 0.8, 0, 1, "$"),
    lives = createPlaceholder(32, 32, 1, 0, 0, 1, "♥"),
    wave = createPlaceholder(32, 32, 0, 0.7, 1, 1, "~"),
    
    -- Tower icons
    tower_arrow = createPlaceholder(64, 64, 0, 0.7, 0, 1, "→"),
    tower_cannon = createPlaceholder(64, 64, 0.7, 0.5, 0, 1, "◉"),
    tower_magic = createPlaceholder(64, 64, 0.7, 0, 0.7, 1, "★"),
    
    -- Hero icons
    hero_radiant = createPlaceholder(128, 128, 1, 1, 0.8, 1, "Radiant"),
    hero_shadow = createPlaceholder(128, 128, 0.2, 0.2, 0.4, 1, "Shadow"),
    hero_twilight = createPlaceholder(128, 128, 0.6, 0.3, 0.7, 1, "Twilight"),
    
    -- Ability icons
    ability_1 = createPlaceholder(48, 48, 0.8, 0, 0, 1, "1"),
    ability_2 = createPlaceholder(48, 48, 0, 0.8, 0, 1, "2"),
    ability_3 = createPlaceholder(48, 48, 0, 0, 0.8, 1, "3"),
    ability_4 = createPlaceholder(48, 48, 0.8, 0.8, 0, 1, "4"),
    
    -- Achievement icons
    achievement_first_win = createPlaceholder(64, 64, 0.8, 0.8, 0.8, 1, "1st"),
    achievement_tower_master = createPlaceholder(64, 64, 0.8, 0.8, 0.8, 1, "TM"),
    achievement_hero_legend = createPlaceholder(64, 64, 0.8, 0.8, 0.8, 1, "HL"),
    achievement_perfect_run = createPlaceholder(64, 64, 0.8, 0.8, 0.8, 1, "PR"),
    achievement_wealthy = createPlaceholder(64, 64, 0.8, 0.8, 0.8, 1, "W"),
    achievement_wave_master = createPlaceholder(64, 64, 0.8, 0.8, 0.8, 1, "WM"),
    achievement_faction_master = createPlaceholder(64, 64, 0.8, 0.8, 0.8, 1, "FM"),
    achievement_speed_demon = createPlaceholder(64, 64, 0.8, 0.8, 0.8, 1, "SD")
}

-- Create placeholder panels
UI_ASSETS.panels = {
    info = createPlaceholder(300, 200, 0.1, 0.1, 0.3, 0.8, "Info Panel"),
    stats = createPlaceholder(250, 300, 0.1, 0.3, 0.1, 0.8, "Stats Panel"),
    inventory = createPlaceholder(400, 300, 0.3, 0.2, 0.1, 0.8, "Inventory Panel"),
    shop = createPlaceholder(350, 450, 0.2, 0.1, 0.3, 0.8, "Shop Panel")
}

-- Create placeholder effects
UI_ASSETS.effects = {
    highlight = createPlaceholder(64, 64, 1, 1, 0.5, 0.5, "!"),
    glow = createPlaceholder(64, 64, 1, 1, 1, 0.7, "*"),
    pulse = createPlaceholder(64, 64, 0.5, 0.5, 1, 0.7, "•")
}

return UI_ASSETS 