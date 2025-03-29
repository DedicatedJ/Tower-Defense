local FactionSelectState = {}
FactionSelectState.__index = FactionSelectState

local Gamestate = require 'libs.hump.gamestate'
local Timer = require 'libs.hump.timer'
local Factions = require 'data.factions'
local Error = require 'utils.error'

function FactionSelectState.new()
    local self = setmetatable({}, FactionSelectState)
    
    self.title = "Select Your Faction"
    self.factions = {}
    self.selectedFaction = nil
    self.buttons = {}
    self.backButton = nil
    self.background = nil
    self.timer = Timer.new() -- Add timer instance
    self.currentFactionIndex = 1 -- Track the current faction index for carousel
    self.carouselTransitioning = false -- Flag to prevent rapid transitions
    
    return self
end

function FactionSelectState:init()
    -- Load background image
    local success = pcall(function()
        self.background = love.graphics.newImage("sprites/ui/backgrounds/faction_select.jpg")
    end)
    
    if not success then
        self.background = nil
    end
    
    -- Load factions directly from the Factions data
    self.factions = {}
    for id, factionData in pairs(Factions) do
        -- Create a reference to the original faction data to ensure heroes are correctly passed
        local faction = {
            id = id,
            name = factionData.name,
            description = factionData.description,
            color = factionData.color,
            heroes = factionData.heroes
        }
        
        -- Debug output
        print("Loading faction: " .. id)
        print("Number of heroes: " .. (faction.heroes and #faction.heroes or 0))
        if faction.heroes then
            for i, hero in ipairs(faction.heroes) do
                print("  Hero " .. i .. ": " .. hero.name)
            end
        end
        
        table.insert(self.factions, faction)
    end
    
    -- Create UI elements
    self:createUI()
end

function FactionSelectState:createUI()
    -- Title (moved to center bottom)
    self.titleText = {
        text = self.title,
        x = love.graphics.getWidth() / 2,
        y = love.graphics.getHeight() - 100, -- Bottom position
        font = fonts.title
    }
    
    -- Back button (moved to top left)
    self.backButton = {
        text = "Back to Menu",
        x = 20,
        y = 20,
        width = 180,
        height = 50,
        hovered = false
    }
    
    -- Carousel navigation arrows
    self.leftArrow = {
        x = love.graphics.getWidth() / 4 - 30,
        y = love.graphics.getHeight() / 2,
        width = 60,
        height = 60,
        hovered = false
    }
    
    self.rightArrow = {
        x = love.graphics.getWidth() * 3/4 - 30,
        y = love.graphics.getHeight() / 2,
        width = 60,
        height = 60,
        hovered = false
    }
    
    -- Set up carousel positions
    self:updateCarouselPositions()
end

function FactionSelectState:updateCarouselPositions()
    -- Clear existing buttons
    self.buttons = {}
    
    local centerX = love.graphics.getWidth() / 2
    local centerY = love.graphics.getHeight() / 2
    
    local cardWidth = 300
    local cardHeight = 360
    local sideCardScale = 0.7 -- Scale for cards on the sides
    
    -- Calculate positions for visible cards (3 at a time)
    local totalFactions = #self.factions
    
    for i = 1, totalFactions do
        local relativeIndex = (i - self.currentFactionIndex) % totalFactions
        if relativeIndex > totalFactions / 2 then
            relativeIndex = relativeIndex - totalFactions
        end
        
        local x, y, scale, alpha, zIndex
        
        if relativeIndex == 0 then
            -- Center card (current selection)
            x = centerX - cardWidth / 2
            y = centerY - cardHeight / 2 + 30 -- Slightly lower
            scale = 1.0
            alpha = 1.0
            zIndex = 3
        elseif relativeIndex == -1 or relativeIndex == (totalFactions - 1) then
            -- Left card - showing about 30% of the card
            x = centerX - cardWidth * 1.2
            y = centerY - cardHeight / 2 * sideCardScale
            scale = sideCardScale
            alpha = 0.7
            zIndex = 1
        elseif relativeIndex == 1 then
            -- Right card - showing about 30% of the card
            x = centerX + cardWidth * 0.5
            y = centerY - cardHeight / 2 * sideCardScale
            scale = sideCardScale
            alpha = 0.7
            zIndex = 1
        else
            -- Off-screen cards
            if relativeIndex < 0 then
                x = centerX - cardWidth * 2.0
            else
                x = centerX + cardWidth * 1.3
            end
            y = centerY - cardHeight / 2
            scale = sideCardScale * 0.8
            alpha = 0
            zIndex = 0
        end
        
        -- Create faction button
        self.buttons[i] = {
            x = x,
            y = y,
            width = cardWidth,
            height = cardHeight,
            faction = self.factions[i],
            hovered = false,
            scale = scale,
            alpha = alpha,
            zIndex = zIndex,
            originalIndex = i
        }
    end
    
    -- Sort buttons by zIndex to ensure proper drawing order
    table.sort(self.buttons, function(a, b) return a.zIndex < b.zIndex end)
    
    -- Update selected faction
    self.selectedFaction = self.factions[self.currentFactionIndex]
end

function FactionSelectState:nextFaction()
    if self.carouselTransitioning then return end
    
    self.carouselTransitioning = true
    self.currentFactionIndex = self.currentFactionIndex % #self.factions + 1
    self:updateCarouselPositions()
    
    -- Play sound
    playSound('sfx', 'buttonClick')
    
    -- Reset transition flag after a short delay
    self.timer:after(0.3, function() self.carouselTransitioning = false end)
end

function FactionSelectState:previousFaction()
    if self.carouselTransitioning then return end
    
    self.carouselTransitioning = true
    self.currentFactionIndex = self.currentFactionIndex - 1
    if self.currentFactionIndex < 1 then self.currentFactionIndex = #self.factions end
    self:updateCarouselPositions()
    
    -- Play sound
    playSound('sfx', 'buttonClick')
    
    -- Reset transition flag after a short delay
    self.timer:after(0.3, function() self.carouselTransitioning = false end)
end

function FactionSelectState:enter()
    -- Reset selected faction
    self.selectedFaction = nil
    gameState.selectedFaction = nil
    
    -- Set initial faction index
    self.currentFactionIndex = 1
    self:updateCarouselPositions()
    
    -- Play faction select music if available
    -- playSound('music', 'faction_select')
end

function FactionSelectState:update(dt)
    -- Update timers
    self.timer:update(dt)
    
    -- Update error notifications
    Error.update(dt)
end

function FactionSelectState:draw()
    -- Draw background
    love.graphics.setColor(1, 1, 1, 1)
    if self.background then
        love.graphics.draw(
            self.background, 
            0, 0, 
            0, 
            love.graphics.getWidth() / self.background:getWidth(),
            love.graphics.getHeight() / self.background:getHeight()
        )
    else
        -- Fallback gradient background
        local gradient = {
            {0, 0.1, 0.3, 1},  -- Deep blue at top
            {0.2, 0.2, 0.4, 1} -- Lighter blue at bottom
        }
        
        for i = 0, love.graphics.getHeight() do
            local t = i / love.graphics.getHeight()
            local r = gradient[1][1] * (1-t) + gradient[2][1] * t
            local g = gradient[1][2] * (1-t) + gradient[2][2] * t
            local b = gradient[1][3] * (1-t) + gradient[2][3] * t
            love.graphics.setColor(r, g, b, 1)
            love.graphics.line(0, i, love.graphics.getWidth(), i)
        end
    end
    
    -- Draw title with glow effect at bottom center
    local titleWidth = self.titleText.font:getWidth(self.titleText.text)
    
    -- Draw semi-transparent background box for title
    local padding = 20
    local titleBoxWidth = titleWidth + (padding * 2)
    local titleBoxHeight = 60
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle(
        "fill",
        self.titleText.x - titleBoxWidth/2,
        self.titleText.y - titleBoxHeight/2 + 5,
        titleBoxWidth,
        titleBoxHeight,
        10, 10
    )
    
    -- Black outline for title box
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle(
        "line",
        self.titleText.x - titleBoxWidth/2,
        self.titleText.y - titleBoxHeight/2 + 5,
        titleBoxWidth,
        titleBoxHeight,
        10, 10
    )
    
    -- Black shadow for title (slightly offset for depth)
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.setFont(self.titleText.font)
    love.graphics.print(
        self.titleText.text, 
        self.titleText.x - titleWidth/2 + 2, 
        self.titleText.y + 2
    )
    
    -- Draw actual title with a medieval gold color
    love.graphics.setColor(0.95, 0.85, 0.5, 1)
    love.graphics.setFont(self.titleText.font)
    love.graphics.print(
        self.titleText.text, 
        self.titleText.x - titleWidth/2, 
        self.titleText.y
    )
    
    -- Draw faction cards in carousel style (sorted by zIndex)
    for _, button in ipairs(self.buttons) do
        local faction = button.faction
        
        -- Skip if not visible
        if button.alpha <= 0 then goto continue end
        
        -- Apply alpha
        love.graphics.setColor(1, 1, 1, button.alpha)
        
        -- Button background with transparency
        love.graphics.setColor(0, 0, 0, 0.5 * button.alpha)
        love.graphics.rectangle("fill", button.x, button.y, button.width * button.scale, button.height * button.scale, 10, 10)
        
        -- Button border based on faction color
        local borderWidth = 3
        if button.zIndex == 3 then  -- Center card
            -- Black outline (thicker for better visibility)
            love.graphics.setColor(0, 0, 0, 1.0 * button.alpha)
            love.graphics.setLineWidth(8)
            love.graphics.rectangle("line", button.x, button.y, button.width * button.scale, button.height * button.scale, 10, 10)
            
            -- Glowing border for center card (inside the black outline)
            love.graphics.setColor(faction.color[1], faction.color[2], faction.color[3], 1.0 * button.alpha)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", button.x + 4, button.y + 4, button.width * button.scale - 8, button.height * button.scale - 8, 8, 8)
            
            -- Draw highlight glow
            love.graphics.setColor(faction.color[1], faction.color[2], faction.color[3], 0.3 * button.alpha)
            love.graphics.rectangle("fill", button.x, button.y, button.width * button.scale, button.height * button.scale, 10, 10)
        else
            -- Black outline for side cards (thicker)
            love.graphics.setColor(0, 0, 0, 1.0 * button.alpha)
            love.graphics.setLineWidth(5)
            love.graphics.rectangle("line", button.x, button.y, button.width * button.scale, button.height * button.scale, 10, 10)
            
            -- Colored inner border
            love.graphics.setColor(faction.color[1], faction.color[2], faction.color[3], 0.7 * button.alpha)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", button.x + 3, button.y + 3, button.width * button.scale - 6, button.height * button.scale - 6, 8, 8)
        end
        
        -- Reset line width
        love.graphics.setLineWidth(1)
        
        -- Draw faction emblem/banner (placeholder with faction colors)
        love.graphics.setColor(faction.color[1], faction.color[2], faction.color[3], 0.7 * button.alpha)
        love.graphics.rectangle(
            "fill", 
            button.x + 30 * button.scale, 
            button.y + 30 * button.scale, 
            (button.width - 60) * button.scale, 
            80 * button.scale, 
            5, 5
        )
        
        -- Draw faction name with elegant styling
        love.graphics.setColor(1, 1, 1, button.alpha)
        love.graphics.setFont(fonts.title)
        local nameWidth = fonts.title:getWidth(faction.name) * button.scale
        love.graphics.print(
            faction.name, 
            button.x + (button.width * button.scale - nameWidth) / 2, 
            button.y + 130 * button.scale,
            0, button.scale, button.scale
        )
        
        -- Draw faction description only for center card
        if button.zIndex == 3 then
            love.graphics.setFont(fonts.main)
            local descLines = self:wrapText(faction.description, button.width - 40)
            for i, line in ipairs(descLines) do
                local lineWidth = fonts.main:getWidth(line)
                love.graphics.print(
                    line, 
                    button.x + (button.width - lineWidth) / 2, 
                    button.y + 180 + (i-1) * 20
                )
            end
            
            -- Draw number of heroes
            local heroCount = faction.heroes and #faction.heroes or 0
            local heroText = heroCount .. " Heroes Available"
            local heroTextWidth = fonts.main:getWidth(heroText)
            
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.print(
                heroText, 
                button.x + (button.width - heroTextWidth) / 2, 
                button.y + button.height - 30
            )
        end
        
        ::continue::
    end
    
    -- Draw navigation arrows
    -- Left arrow
    love.graphics.setColor(1, 1, 1, self.leftArrow.hovered and 1 or 0.7)
    love.graphics.polygon(
        "fill",
        self.leftArrow.x + self.leftArrow.width * 0.8, self.leftArrow.y - self.leftArrow.height * 0.4,
        self.leftArrow.x + self.leftArrow.width * 0.8, self.leftArrow.y + self.leftArrow.height * 0.4,
        self.leftArrow.x + self.leftArrow.width * 0.2, self.leftArrow.y
    )
    
    -- Right arrow
    love.graphics.setColor(1, 1, 1, self.rightArrow.hovered and 1 or 0.7)
    love.graphics.polygon(
        "fill",
        self.rightArrow.x + self.rightArrow.width * 0.2, self.rightArrow.y - self.rightArrow.height * 0.4,
        self.rightArrow.x + self.rightArrow.width * 0.2, self.rightArrow.y + self.rightArrow.height * 0.4,
        self.rightArrow.x + self.rightArrow.width * 0.8, self.rightArrow.y
    )
    
    -- Draw back button with nice styling (moved to top left)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", self.backButton.x, self.backButton.y, self.backButton.width, self.backButton.height, 10, 10)
    
    if self.backButton.hovered then
        love.graphics.setColor(1, 1, 1, 0.4)
        love.graphics.rectangle("fill", self.backButton.x, self.backButton.y, self.backButton.width, self.backButton.height, 10, 10)
    end
    
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle("line", self.backButton.x, self.backButton.y, self.backButton.width, self.backButton.height, 10, 10)
    
    love.graphics.setColor(1, 1, 1, 1)
    local backTextWidth = fonts.main:getWidth(self.backButton.text)
    love.graphics.print(
        self.backButton.text, 
        self.backButton.x + (self.backButton.width - backTextWidth) / 2, 
        self.backButton.y + 15
    )
    
    -- Draw error notifications
    Error.draw()
end

-- Helper function to wrap text
function FactionSelectState:wrapText(text, width)
    local lines = {}
    local spaceWidth = fonts.main:getWidth(' ')
    local currentLine = ""
    local currentWidth = 0
    
    for word in text:gmatch("%S+") do
        local wordWidth = fonts.main:getWidth(word)
        
        if currentWidth + wordWidth <= width then
            if currentLine ~= "" then
                currentLine = currentLine .. " " 
                currentWidth = currentWidth + spaceWidth
            end
            currentLine = currentLine .. word
            currentWidth = currentWidth + wordWidth
        else
            table.insert(lines, currentLine)
            currentLine = word
            currentWidth = wordWidth
        end
    end
    
    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end
    
    return lines
end

function FactionSelectState:mousepressed(x, y, button)
    if button == 1 then
        -- Check faction buttons
        for _, button in ipairs(self.buttons) do
            if button.zIndex == 3 and self:isPointInButton(x, y, button) then
                -- Play click sound
                playSound('sfx', 'buttonClick')
                
                -- Select faction
                self:selectFaction(button.faction)
                return
            end
        end
        
        -- Check left arrow
        if self:isPointInButton(x, y, self.leftArrow) then
            self:previousFaction()
            return
        end
        
        -- Check right arrow
        if self:isPointInButton(x, y, self.rightArrow) then
            self:nextFaction()
            return
        end
        
        -- Check back button
        if self:isPointInButton(x, y, self.backButton) then
            -- Play click sound
            playSound('sfx', 'buttonClick')
            
            -- Go back to menu
            self:goBack()
            return
        end
    end
end

function FactionSelectState:mousemoved(x, y, dx, dy)
    -- Update button hover states
    self.backButton.hovered = self:isPointInButton(x, y, self.backButton)
    self.leftArrow.hovered = self:isPointInButton(x, y, self.leftArrow)
    self.rightArrow.hovered = self:isPointInButton(x, y, self.rightArrow)
    
    -- Update card hover states
    for _, button in ipairs(self.buttons) do
        if button.zIndex == 3 then -- Only center card is interactive
            button.hovered = self:isPointInButton(x, y, button)
        else
            button.hovered = false
        end
    end
end

function FactionSelectState:isPointInButton(x, y, button)
    local width = button.width or button.width
    local height = button.height or button.height
    local scale = button.scale or 1
    
    return x >= button.x and x <= button.x + width * scale and
           y >= button.y and y <= button.y + height * scale
end

function FactionSelectState:selectFaction(faction)
    print("Selecting faction:", faction.id)
    print("Heroes for faction:", faction.heroes and #faction.heroes or 0)
    
    -- Store selected faction
    self.selectedFaction = faction
    gameState.selectedFaction = faction
    
    -- Debug: list heroes in the selected faction
    if faction.heroes then
        for i, hero in ipairs(faction.heroes) do
            print("  Hero " .. i .. ": " .. hero.name)
        end
    end
    
    -- Create the hero select state and initialize it
    local heroSelectState = require('states.hero_select').new()
    
    -- Switch to the hero select state and pass the faction data during the switch
    Gamestate.switch(heroSelectState)
    
    -- Initialize after switching to ensure the state has all data
    heroSelectState:init(faction)
end

function FactionSelectState:goBack()
    -- Switch back to menu
    local menuState = require('states.menu').new()
    Gamestate.switch(menuState)
end

function FactionSelectState:keypressed(key)
    if key == "escape" then
        self:goBack()
    elseif key == "left" then
        self:previousFaction()
    elseif key == "right" then
        self:nextFaction()
    elseif key == "return" or key == "space" then
        if self.selectedFaction then
            self:selectFaction(self.selectedFaction)
        end
    end
end

return FactionSelectState 