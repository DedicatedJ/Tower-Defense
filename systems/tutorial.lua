local Tutorial = {}
Tutorial.__index = Tutorial

-- Tutorial step definitions
local TUTORIAL_STEPS = {
    {
        id = "welcome",
        title = "Welcome to Tower Defense!",
        description = "Let's learn the basics of defending your realm.",
        duration = 5,
        highlight = nil,
        action = function(gameState)
            -- Show welcome message
            gameState:showTutorialMessage("Welcome to Tower Defense!")
        end
    },
    {
        id = "select_faction",
        title = "Choose Your Faction",
        description = "Select a faction to begin your journey.",
        duration = 0, -- Until action is completed
        highlight = {x = 400, y = 200, width = 200, height = 400},
        action = function(gameState)
            -- Wait for faction selection
            return gameState.selectedFaction ~= nil
        end
    },
    {
        id = "select_hero",
        title = "Select Your Hero",
        description = "Choose a hero to lead your forces.",
        duration = 0,
        highlight = {x = 400, y = 200, width = 200, height = 400},
        action = function(gameState)
            -- Wait for hero selection
            return gameState.selectedHero ~= nil
        end
    },
    {
        id = "place_tower",
        title = "Place Your First Tower",
        description = "Click on a tower spot to place your first tower.",
        duration = 0,
        highlight = function(gameState)
            -- Highlight first available tower spot
            return gameState.map:getFirstTowerSpot()
        end,
        action = function(gameState)
            -- Wait for tower placement
            return #gameState.towers > 0
        end
    },
    {
        id = "upgrade_tower",
        title = "Upgrade Your Tower",
        description = "Click on your tower and select an upgrade path.",
        duration = 0,
        highlight = function(gameState)
            -- Highlight first placed tower
            if #gameState.towers > 0 then
                return {
                    x = gameState.towers[1].x - 30,
                    y = gameState.towers[1].y - 30,
                    width = 60,
                    height = 60
                }
            end
            return nil
        end,
        action = function(gameState)
            -- Wait for tower upgrade
            if #gameState.towers > 0 then
                return gameState.towers[1].level > 1
            end
            return false
        end
    },
    {
        id = "start_wave",
        title = "Start Your First Wave",
        description = "Click the 'Start Wave' button to begin.",
        duration = 0,
        highlight = {x = 700, y = 50, width = 100, height = 40},
        action = function(gameState)
            -- Wait for wave start
            return gameState.currentWave > 1
        end
    },
    {
        id = "hero_ability",
        title = "Use Hero Ability",
        description = "Press 'Q' to use your hero's ability.",
        duration = 0,
        highlight = function(gameState)
            -- Highlight hero ability button
            return {x = 50, y = 50, width = 40, height = 40}
        end,
        action = function(gameState)
            -- Wait for ability use
            return gameState.hero.lastAbilityUse ~= nil
        end
    },
    {
        id = "complete",
        title = "Tutorial Complete!",
        description = "You're ready to defend your realm!",
        duration = 5,
        highlight = nil,
        action = function(gameState)
            -- Show completion message
            gameState:showTutorialMessage("Tutorial Complete!")
            return true
        end
    }
}

function Tutorial.new()
    local self = setmetatable({}, Tutorial)
    
    self.currentStep = 1
    self.steps = TUTORIAL_STEPS
    self.timer = 0
    self.completed = false
    
    return self
end

function Tutorial:update(dt)
    if self.completed then return end
    
    local step = self.steps[self.currentStep]
    if not step then
        self.completed = true
        return
    end
    
    -- Update timer for timed steps
    if step.duration > 0 then
        self.timer = self.timer + dt
        if self.timer >= step.duration then
            self:nextStep()
            return
        end
    end
    
    -- Check step completion
    if step.action and step.action(gameState) then
        self:nextStep()
    end
end

function Tutorial:draw()
    if self.completed then return end
    
    local step = self.steps[self.currentStep]
    if not step then return end
    
    -- Draw highlight
    if step.highlight then
        local highlight = type(step.highlight) == "function" and step.highlight(gameState) or step.highlight
        if highlight then
            love.graphics.setColor(1, 1, 0, 0.3)
            love.graphics.rectangle("fill", highlight.x, highlight.y, highlight.width, highlight.height)
            love.graphics.setColor(1, 1, 0, 1)
            love.graphics.rectangle("line", highlight.x, highlight.y, highlight.width, highlight.height)
        end
    end
    
    -- Draw tutorial message
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - 150, love.graphics.getWidth(), 150)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fonts.title)
    love.graphics.print(step.title, 20, love.graphics.getHeight() - 140)
    
    love.graphics.setFont(fonts.main)
    love.graphics.print(step.description, 20, love.graphics.getHeight() - 100)
    
    -- Draw progress
    local progress = string.format("Step %d of %d", self.currentStep, #self.steps)
    love.graphics.print(progress, 20, love.graphics.getHeight() - 60)
end

function Tutorial:nextStep()
    self.currentStep = self.currentStep + 1
    self.timer = 0
    
    if self.currentStep > #self.steps then
        self.completed = true
    end
end

function Tutorial:skip()
    self.completed = true
end

return Tutorial 