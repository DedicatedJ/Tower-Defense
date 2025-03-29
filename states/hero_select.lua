local HeroSelectState = {}
HeroSelectState.__index = HeroSelectState

local Gamestate = require 'libs.hump.gamestate'
local Timer = require 'libs.hump.timer'
local Error = require 'utils.error'

function HeroSelectState.new()
    local self = setmetatable({}, HeroSelectState)
    
    self.title = "Select Your Hero"
    self.faction = nil
    self.heroes = {}
    self.selectedHero = nil
    self.buttons = {}
    self.backButton = nil
    self.background = nil
    self.timer = Timer.new()
    self.currentHeroIndex = 1 -- Track the current hero index for carousel
    self.carouselTransitioning = false -- Flag to prevent rapid transitions
    
    return self
end

function HeroSelectState:init(faction)
    if not faction then
        print("HeroSelectState init with faction:\tnil")
        faction = self:getDefaultFaction()
    else
        print("HeroSelectState init with faction:\t" .. (faction.id or "unknown"))
    end
    
    self.faction = faction
    
    if faction.heroes and type(faction.heroes) == "table" then
        print("Faction heroes table:\texists")
        print("Number of heroes:\t" .. #faction.heroes)
        for i, hero in ipairs(faction.heroes) do
            print("Hero " .. i .. ": " .. hero.name)
        end
        
        print("Loading heroes from faction data")
        self.heroes = faction.heroes
        print("Loaded " .. #self.heroes .. " heroes from faction data")
    else
        print("Using fallback heroes for faction:\t" .. (faction.id or "nil"))
        self.heroes = self:createFallbackHeroes(faction)
        print("Created " .. #self.heroes .. " fallback heroes")
    end
    
    -- Initialize carousel settings
    self.selectedIndex = 1
    self.carouselX = love.graphics.getWidth() / 2
    self.carouselY = love.graphics.getHeight() / 2 - 50
    self.carouselRadius = 180
    self.carouselRotation = 0
    
    -- Update carousel positions
    self:updateCarouselPositions()
    
    -- Initialize buttons
    self:createUI()
end

function HeroSelectState:createUI()
    -- Title (moved to center bottom)
    self.titleText = {
        text = self.title,
        x = love.graphics.getWidth() / 2,
        y = love.graphics.getHeight() - 100, -- Bottom position
        font = fonts.title
    }
    
    -- Back button (moved to top left)
    self.backButton = {
        text = "Back to Factions",
        x = 20,
        y = 20,
        width = 200,
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
    
    -- Faction info panel (moved to top right)
    self.factionPanel = {
        x = love.graphics.getWidth() - 220,
        y = 20,
        width = 200,
        height = 60
    }
    
    -- Set up carousel positions
    self:updateCarouselPositions()
    
    -- Hero details panel (appears when hovering)
    self.detailsPanel = {
        width = 300,
        height = 400,
        visible = false,
        hero = nil
    }
end

function HeroSelectState:updateCarouselPositions()
    -- Clear existing buttons
    self.buttons = {}
    
    -- Debug hero data
    print("updateCarouselPositions - Heroes count:", #self.heroes)
    
    -- If no heroes, return early
    if #self.heroes == 0 then
        print("WARNING: No heroes available to display!")
        return
    end
    
    print("Current hero index:", self.currentHeroIndex, "out of", #self.heroes)
    
    local centerX = love.graphics.getWidth() / 2
    local centerY = love.graphics.getHeight() / 2
    
    local cardWidth = 300
    local cardHeight = 450
    local sideCardScale = 0.7 -- Scale for cards on the sides
    
    -- Calculate positions for visible cards (3 at a time)
    local totalHeroes = #self.heroes
    
    for i = 1, totalHeroes do
        local relativeIndex = (i - self.currentHeroIndex) % totalHeroes
        if relativeIndex > totalHeroes / 2 then
            relativeIndex = relativeIndex - totalHeroes
        end
        
        local x, y, scale, alpha, zIndex
        
        if relativeIndex == 0 then
            -- Center card (current selection)
            x = centerX - cardWidth / 2
            y = centerY - cardHeight / 2 + 30 -- Slightly lower
            scale = 1.0
            alpha = 1.0
            zIndex = 3
        elseif relativeIndex == -1 or relativeIndex == (totalHeroes - 1) then
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
        
        -- Create hero card button
        self.buttons[i] = {
            x = x,
            y = y,
            width = cardWidth,
            height = cardHeight,
            hero = self.heroes[i],
            hovered = false,
            scale = scale,
            alpha = alpha,
            zIndex = zIndex,
            originalIndex = i
        }
    end
    
    -- Sort buttons by zIndex to ensure proper drawing order
    table.sort(self.buttons, function(a, b) return a.zIndex < b.zIndex end)
    
    -- Update selected hero
    self.selectedHero = self.heroes[self.currentHeroIndex]
end

function HeroSelectState:nextHero()
    if self.carouselTransitioning or #self.heroes == 0 then return end
    
    self.carouselTransitioning = true
    self.currentHeroIndex = self.currentHeroIndex % #self.heroes + 1
    self:updateCarouselPositions()
    
    -- Play sound
    playSound('sfx', 'buttonClick')
    
    -- Reset transition flag after a short delay
    self.timer:after(0.3, function() self.carouselTransitioning = false end)
end

function HeroSelectState:previousHero()
    if self.carouselTransitioning or #self.heroes == 0 then return end
    
    self.carouselTransitioning = true
    self.currentHeroIndex = self.currentHeroIndex - 1
    if self.currentHeroIndex < 1 then self.currentHeroIndex = #self.heroes end
    self:updateCarouselPositions()
    
    -- Play sound
    playSound('sfx', 'buttonClick')
    
    -- Reset transition flag after a short delay
    self.timer:after(0.3, function() self.carouselTransitioning = false end)
end

function HeroSelectState:enter()
    -- Play hero select music if available
    -- playSound('music', 'hero_select')
    
    -- Set initial hero index
    self.currentHeroIndex = 1
    self:updateCarouselPositions()
end

function HeroSelectState:update(dt)
    -- Update timers
    self.timer:update(dt)
    
    -- Update error notifications
    Error.update(dt)
    
    -- Update details panel
    self.detailsPanel.visible = false
    for _, button in ipairs(self.buttons) do
        if button.zIndex == 3 and button.hovered then
            self.detailsPanel.visible = true
            self.detailsPanel.hero = button.hero
            self.detailsPanel.x = love.mouse.getX() + 20
            self.detailsPanel.y = love.mouse.getY() - 50
            
            -- Keep panel on screen
            if self.detailsPanel.x + self.detailsPanel.width > love.graphics.getWidth() then
                self.detailsPanel.x = love.mouse.getX() - 20 - self.detailsPanel.width
            end
            
            if self.detailsPanel.y + self.detailsPanel.height > love.graphics.getHeight() then
                self.detailsPanel.y = love.graphics.getHeight() - self.detailsPanel.height - 20
            end
            
            if self.detailsPanel.y < 10 then
                self.detailsPanel.y = 10
            end
            
            break
        end
    end
end

function HeroSelectState:draw()
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
            {0.1, 0.1, 0.3, 1},  -- Deep blue at top
            {0.3, 0.2, 0.4, 1}   -- Purple at bottom
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
    
    -- Black shadow for title (slightly offset for depth)
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.setFont(self.titleText.font)
    love.graphics.print(
        self.titleText.text, 
        self.titleText.x - titleWidth/2 + 2, 
        self.titleText.y + 2
    )
    
    -- Draw actual title with a color matching the faction theme
    local factionColor = self.faction and self.faction.color or {0.95, 0.85, 0.5}
    love.graphics.setColor(factionColor[1], factionColor[2], factionColor[3], 1)
    love.graphics.setFont(self.titleText.font)
    love.graphics.print(
        self.titleText.text, 
        self.titleText.x - titleWidth/2, 
        self.titleText.y
    )
    
    -- Draw faction info (moved to top right)
    if self.faction then
        -- Draw faction badge/emblem
        love.graphics.setColor(factionColor[1], factionColor[2], factionColor[3], 0.8)
        love.graphics.rectangle(
            "fill", 
            self.factionPanel.x, 
            self.factionPanel.y, 
            self.factionPanel.width, 
            self.factionPanel.height,
            8, 8
        )
        
        -- Draw faction name
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.setFont(fonts.main)
        local factionText = "Faction: " .. self.faction.name
        love.graphics.print(
            factionText, 
            self.factionPanel.x + 15, 
            self.factionPanel.y + 20
        )
    end
    
    -- Show message if no heroes available
    if #self.heroes == 0 then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.setFont(fonts.title)
        local noHeroesText = "No Heroes Available for this Faction"
        local textWidth = fonts.title:getWidth(noHeroesText)
        love.graphics.print(
            noHeroesText,
            love.graphics.getWidth()/2 - textWidth/2,
            love.graphics.getHeight()/2 - 40
        )
        
        love.graphics.setFont(fonts.main)
        local helperText = "Please select another faction"
        local helperWidth = fonts.main:getWidth(helperText)
        love.graphics.print(
            helperText,
            love.graphics.getWidth()/2 - helperWidth/2,
            love.graphics.getHeight()/2 + 20
        )
    else
        -- Draw hero cards in carousel style
        for _, button in ipairs(self.buttons) do
            local hero = button.hero
            
            -- Skip if not visible
            if button.alpha <= 0 then goto continue end
            
            -- Apply alpha
            love.graphics.setColor(1, 1, 1, button.alpha)
            
            -- Card background with transparency
            love.graphics.setColor(0, 0, 0, 0.7 * button.alpha)
            love.graphics.rectangle("fill", button.x, button.y, button.width * button.scale, button.height * button.scale, 12, 12)
            
            -- Card border and highlight
            if button.zIndex == 3 then -- Center card
                -- Black outline (thicker for better visibility)
                love.graphics.setColor(0, 0, 0, 1.0 * button.alpha)
                love.graphics.setLineWidth(8)
                love.graphics.rectangle("line", button.x, button.y, button.width * button.scale, button.height * button.scale, 12, 12)
                
                -- Glowing border for center card
                local borderColor = self.faction and self.faction.color or {1, 0.8, 0.2}
                love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], 1.0 * button.alpha)
                love.graphics.setLineWidth(3)
                love.graphics.rectangle("line", button.x + 4, button.y + 4, button.width * button.scale - 8, button.height * button.scale - 8, 10, 10)
                
                -- Highlight effect
                love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], 0.2 * button.alpha)
                love.graphics.rectangle("fill", button.x, button.y, button.width * button.scale, button.height * button.scale, 12, 12)
            else
                -- Black outline for side cards (thicker)
                love.graphics.setColor(0, 0, 0, 1.0 * button.alpha)
                love.graphics.setLineWidth(5)
                love.graphics.rectangle("line", button.x, button.y, button.width * button.scale, button.height * button.scale, 12, 12)
                
                -- Colored inner border
                local borderColor = self.faction and self.faction.color or {0.7, 0.7, 0.7}
                love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], 0.7 * button.alpha)
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", button.x + 3, button.y + 3, button.width * button.scale - 6, button.height * button.scale - 6, 10, 10)
            end
            
            -- Reset line width
            love.graphics.setLineWidth(1)
            
            -- Draw hero portrait placeholder (colored rectangle)
            local portraitColor = {0.7, 0.7, 0.7}
            if hero.id:find("paladin") or hero.id:find("priest") then
                portraitColor = {0.9, 0.9, 0.4} -- Gold for holy
            elseif hero.id:find("necro") or hero.id:find("warlock") or hero.id:find("assassin") then
                portraitColor = {0.6, 0.2, 0.8} -- Purple for shadow
            elseif hero.id:find("balance") or hero.id:find("dream") or hero.id:find("star") then
                portraitColor = {0.4, 0.7, 0.9} -- Blue for twilight
            end
            
            love.graphics.setColor(portraitColor[1], portraitColor[2], portraitColor[3], 0.7 * button.alpha)
            love.graphics.rectangle(
                "fill", 
                button.x + 25 * button.scale, 
                button.y + 25 * button.scale, 
                (button.width - 50) * button.scale, 
                100 * button.scale, 
                8, 8
            )
            
            -- Draw hero class icon (placeholder)
            love.graphics.setColor(1, 1, 1, 0.9 * button.alpha)
            love.graphics.circle(
                "fill", 
                button.x + (button.width - 35) * button.scale, 
                button.y + 35 * button.scale, 
                20 * button.scale
            )
            
            -- Draw hero name
            love.graphics.setColor(1, 1, 1, button.alpha)
            love.graphics.setFont(fonts.title)
            local nameWidth = fonts.title:getWidth(hero.name) * button.scale
            if nameWidth > (button.width - 30) * button.scale then
                -- Scale down font if name is too long
                local scaleFactor = ((button.width - 30) * button.scale) / nameWidth
                love.graphics.print(
                    hero.name, 
                    button.x + (button.width * button.scale - nameWidth * scaleFactor) / 2, 
                    button.y + 140 * button.scale,
                    0, button.scale * scaleFactor, button.scale * scaleFactor
                )
            else
                love.graphics.print(
                    hero.name, 
                    button.x + (button.width * button.scale - nameWidth) / 2, 
                    button.y + 140 * button.scale,
                    0, button.scale, button.scale
                )
            end
            
            -- Only draw stat bars for center card
            if button.zIndex == 3 then
                love.graphics.setFont(fonts.main)
                
                -- Health bar
                local statBarWidth = button.width - 50
                local maxStat = 600
                
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.print("Health", button.x + 25, button.y + 185)
                
                love.graphics.setColor(0.2, 0.2, 0.2, 0.6)
                love.graphics.rectangle("fill", button.x + 25, button.y + 205, statBarWidth, 15, 4, 4)
                
                love.graphics.setColor(0.1, 0.7, 0.3, 0.9)
                love.graphics.rectangle(
                    "fill", 
                    button.x + 25, 
                    button.y + 205, 
                    math.min(statBarWidth * (hero.health / maxStat), statBarWidth), 
                    15, 4, 4
                )
                
                -- Attack bar
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.print("Attack", button.x + 25, button.y + 230)
                
                love.graphics.setColor(0.2, 0.2, 0.2, 0.6)
                love.graphics.rectangle("fill", button.x + 25, button.y + 250, statBarWidth, 15, 4, 4)
                
                love.graphics.setColor(0.9, 0.3, 0.2, 0.9)
                love.graphics.rectangle(
                    "fill", 
                    button.x + 25, 
                    button.y + 250, 
                    math.min(statBarWidth * (hero.attack / 100), statBarWidth), 
                    15, 4, 4
                )
                
                -- Speed bar
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.print("Speed", button.x + 25, button.y + 275)
                
                love.graphics.setColor(0.2, 0.2, 0.2, 0.6)
                love.graphics.rectangle("fill", button.x + 25, button.y + 295, statBarWidth, 15, 4, 4)
                
                love.graphics.setColor(0.2, 0.5, 0.9, 0.9)
                love.graphics.rectangle(
                    "fill", 
                    button.x + 25, 
                    button.y + 295, 
                    math.min(statBarWidth * (hero.speed / 150), statBarWidth), 
                    15, 4, 4
                )
                
                -- Ability indicators (simplified for center card)
                if hero.abilities then
                    local abilityY = button.y + 330
                    love.graphics.setColor(1, 1, 1, 0.8)
                    love.graphics.print("Abilities:", button.x + 25, abilityY)
                    
                    for i = 1, math.min(3, #hero.abilities) do
                        local ability = hero.abilities[i]
                        -- Ability icon placeholder
                        love.graphics.setColor(0.8, 0.8, 0.8, 0.6)
                        love.graphics.rectangle("fill", button.x + 25, abilityY + 20 + (i-1) * 30, 20, 20, 4, 4)
                        
                        -- Ability name
                        love.graphics.setColor(1, 1, 1, 0.8)
                        love.graphics.print(ability.name, button.x + 55, abilityY + 20 + (i-1) * 30)
                    end
                end
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
    end
    
    -- Draw back button (moved to top left)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", self.backButton.x, self.backButton.y, self.backButton.width, self.backButton.height, 10, 10)
    
    if self.backButton.hovered then
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.rectangle("fill", self.backButton.x, self.backButton.y, self.backButton.width, self.backButton.height, 10, 10)
    end
    
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle("line", self.backButton.x, self.backButton.y, self.backButton.width, self.backButton.height, 10, 10)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fonts.main)
    local backTextWidth = fonts.main:getWidth(self.backButton.text)
    love.graphics.print(
        self.backButton.text, 
        self.backButton.x + (self.backButton.width - backTextWidth) / 2, 
        self.backButton.y + 15
    )
    
    -- Draw details panel if visible
    if self.detailsPanel.visible and self.detailsPanel.hero then
        local hero = self.detailsPanel.hero
        local panel = self.detailsPanel
        
        -- Panel background
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", panel.x, panel.y, panel.width, panel.height, 10, 10)
        
        -- Panel border
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.rectangle("line", panel.x, panel.y, panel.width, panel.height, 10, 10)
        
        -- Hero name
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(fonts.title)
        local nameWidth = fonts.title:getWidth(hero.name)
        love.graphics.print(
            hero.name, 
            panel.x + (panel.width - nameWidth) / 2, 
            panel.y + 15
        )
        
        -- Hero description
        love.graphics.setFont(fonts.main)
        local descLines = self:wrapText(hero.description, panel.width - 30)
        for i, line in ipairs(descLines) do
            love.graphics.print(line, panel.x + 15, panel.y + 60 + (i-1) * 20)
        end
        
        -- Abilities header
        love.graphics.setColor(0.8, 0.8, 0.2, 1)
        love.graphics.print("Abilities:", panel.x + 15, panel.y + 120)
        
        -- Abilities list
        love.graphics.setColor(1, 1, 1, 0.9)
        if hero.abilities then
            for i, ability in ipairs(hero.abilities) do
                -- Ability icon (placeholder)
                love.graphics.setColor(0.6, 0.6, 0.6, 0.6)
                love.graphics.rectangle("fill", panel.x + 15, panel.y + 145 + (i-1) * 50, 30, 30, 4, 4)
                
                -- Ability details
                love.graphics.setColor(1, 1, 1, 0.9)
                love.graphics.print(
                    ability.name, 
                    panel.x + 55, 
                    panel.y + 145 + (i-1) * 50
                )
                
                love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
                love.graphics.print(
                    "Cooldown: " .. ability.cooldown .. "s", 
                    panel.x + 55, 
                    panel.y + 165 + (i-1) * 50
                )
            end
        else
            love.graphics.print("No abilities available", panel.x + 15, panel.y + 145)
        end
        
        -- Stats
        local statsY = panel.y + panel.height - 100
        
        love.graphics.setColor(0.8, 0.8, 0.2, 1)
        love.graphics.print("Stats:", panel.x + 15, statsY)
        
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print("Health: " .. hero.health, panel.x + 15, statsY + 25)
        love.graphics.print("Attack: " .. hero.attack, panel.x + 15, statsY + 45)
        love.graphics.print("Speed: " .. hero.speed, panel.x + 15, statsY + 65)
    end
    
    -- Draw error notifications
    Error.draw()
end

-- Helper function to wrap text
function HeroSelectState:wrapText(text, width)
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

function HeroSelectState:mousepressed(x, y, button)
    if button == 1 then
        -- Check hero buttons
        for _, button in ipairs(self.buttons) do
            if button.zIndex == 3 and self:isPointInButton(x, y, button) then
                -- Play click sound
                playSound('sfx', 'buttonClick')
                
                -- Select hero
                self:selectHero(button.hero)
                return
            end
        end
        
        -- Check left arrow
        if self:isPointInButton(x, y, self.leftArrow) then
            self:previousHero()
            return
        end
        
        -- Check right arrow
        if self:isPointInButton(x, y, self.rightArrow) then
            self:nextHero()
            return
        end
        
        -- Check back button
        if self:isPointInButton(x, y, self.backButton) then
            -- Play click sound
            playSound('sfx', 'buttonClick')
            
            -- Go back to faction select
            self:goBack()
            return
        end
    end
end

function HeroSelectState:mousemoved(x, y, dx, dy)
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
    
    -- Update details panel position
    if self.detailsPanel.visible then
        self.detailsPanel.x = love.mouse.getX() + 20
        self.detailsPanel.y = love.mouse.getY() - 50
    end
end

function HeroSelectState:isPointInButton(x, y, button)
    local width = button.width or button.width
    local height = button.height or button.height
    local scale = button.scale or 1
    
    return x >= button.x and x <= button.x + width * scale and
           y >= button.y and y <= button.y + height * scale
end

function HeroSelectState:goBack()
    -- Switch back to faction select
    local factionSelectState = require('states.faction_select').new()
    Gamestate.switch(factionSelectState)
end

function HeroSelectState:selectHero(hero)
    if not hero then return end
    
    self.selectedHero = hero
    print("Selected hero:", hero.name)
    
    -- Save the hero selection to player profile
    local Save = require('systems.save')
    -- Store the hero ID instead of the full object to prevent serialization issues
    Save.updateHeroSelection(hero.id or hero.name)
    
    -- Create the hub state and initialize it with faction and hero
    local hubState = require('states.hub').new()
    hubState:init(self.faction, self.selectedHero)
    
    -- Switch to the hub state
    Gamestate.switch(hubState)
end

function HeroSelectState:keypressed(key)
    if key == "escape" then
        -- Go back to faction select
        self:goBack()
    elseif key == "left" then
        self:previousHero()
    elseif key == "right" then
        self:nextHero()
    elseif key == "return" or key == "space" then
        if self.selectedHero then
            self:selectHero(self.selectedHero)
        end
    end
end

function HeroSelectState:getDefaultFaction()
    -- Create a default faction if none is provided
    return {
        id = "default",
        name = "Default Faction",
        description = "Default faction for new players",
        heroes = self:createDefaultHeroes()
    }
end

function HeroSelectState:createDefaultHeroes()
    -- Create a set of default heroes that will work for any faction
    local heroes = {
        {
            id = "default_warrior",
            name = "Warrior",
            description = "A balanced fighter with strong defensive capabilities",
            health = 500,
            attack = 50,
            speed = 90,
            abilities = {
                { name = "Shield Bash", cooldown = 10 },
                { name = "Defensive Stance", cooldown = 20 },
                { name = "Battle Cry", cooldown = 30 }
            }
        },
        {
            id = "default_mage",
            name = "Mage",
            description = "A spellcaster with powerful area attacks",
            health = 350,
            attack = 70,
            speed = 85,
            abilities = {
                { name = "Fireball", cooldown = 8 },
                { name = "Ice Barrier", cooldown = 15 },
                { name = "Arcane Explosion", cooldown = 25 }
            }
        }
    }
    
    return heroes
end

function HeroSelectState:createFallbackHeroes(faction)
    if not faction then
        return self:createDefaultHeroes()
    end
    
    local heroes = {}
    
    -- Create faction-specific fallback heroes
    if faction.id == "radiant" then
        -- Radiant heroes
        table.insert(heroes, {
            id = "paladin",
            name = "Paladin",
            description = "A holy warrior who protects and heals allies",
            health = 500,
            attack = 45,
            speed = 100,
            abilities = {
                { name = "Holy Light", cooldown = 20 },
                { name = "Divine Shield", cooldown = 30 },
                { name = "Judgment", cooldown = 45 }
            }
        })
    elseif faction.id == "shadow" then
        -- Shadow heroes
        table.insert(heroes, {
            id = "necromancer",
            name = "Necromancer",
            description = "A dark mage who commands the forces of death",
            health = 420,
            attack = 55,
            speed = 85,
            abilities = {
                { name = "Death Bolt", cooldown = 15 },
                { name = "Soul Harvest", cooldown = 25 },
                { name = "Death Wave", cooldown = 40 }
            }
        })
    elseif faction.id == "twilight" then
        -- Twilight heroes
        table.insert(heroes, {
            id = "balance_mage",
            name = "Balance Mage",
            description = "A spellcaster who harnesses both light and dark energies",
            health = 450,
            attack = 60,
            speed = 95,
            abilities = {
                { name = "Twilight Bolt", cooldown = 15 },
                { name = "Equilibrium", cooldown = 25 },
                { name = "Cosmic Balance", cooldown = 40 }
            }
        })
        
        table.insert(heroes, {
            id = "dream_walker",
            name = "Dream Walker",
            description = "A mystic who travels between realities",
            health = 400,
            attack = 50,
            speed = 100,
            abilities = {
                { name = "Dream Shift", cooldown = 12 },
                { name = "Astral Projection", cooldown = 25 },
                { name = "Reality Warp", cooldown = 40 }
            }
        })
    else
        -- Unknown faction, use default heroes
        return self:createDefaultHeroes()
    end
    
    return heroes
end

return HeroSelectState 