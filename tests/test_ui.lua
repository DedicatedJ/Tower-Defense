local Test = require("tests.test_utils")
local UI = require("systems.ui")

local function test_ui_initialization()
    local ui = UI.new()
    Test.assert_not_nil(ui, "UI system should be created")
    Test.assert_not_nil(ui.elements, "UI should have elements")
    Test.assert_not_nil(ui.themes, "UI should have themes")
    Test.assert_not_nil(ui.fonts, "UI should have fonts")
end

local function test_ui_elements()
    local ui = UI.new()
    
    -- Test button creation
    local button = ui:createButton("Test Button", 100, 100, 200, 50)
    Test.assert_not_nil(button, "Button should be created")
    Test.assert_equals(button.text, "Test Button", "Button should have correct text")
    Test.assert_equals(button.x, 100, "Button should have correct x position")
    Test.assert_equals(button.y, 100, "Button should have correct y position")
    Test.assert_equals(button.width, 200, "Button should have correct width")
    Test.assert_equals(button.height, 50, "Button should have correct height")
    
    -- Test panel creation
    local panel = ui:createPanel(100, 100, 300, 200)
    Test.assert_not_nil(panel, "Panel should be created")
    Test.assert_equals(panel.x, 100, "Panel should have correct x position")
    Test.assert_equals(panel.y, 100, "Panel should have correct y position")
    Test.assert_equals(panel.width, 300, "Panel should have correct width")
    Test.assert_equals(panel.height, 200, "Panel should have correct height")
    
    -- Test label creation
    local label = ui:createLabel("Test Label", 100, 100)
    Test.assert_not_nil(label, "Label should be created")
    Test.assert_equals(label.text, "Test Label", "Label should have correct text")
    Test.assert_equals(label.x, 100, "Label should have correct x position")
    Test.assert_equals(label.y, 100, "Label should have correct y position")
end

local function test_ui_themes()
    local ui = UI.new()
    
    -- Test radiant theme
    local radiantTheme = ui:getTheme("radiant")
    Test.assert_not_nil(radiantTheme, "Radiant theme should exist")
    Test.assert_not_nil(radiantTheme.colors, "Theme should have colors")
    Test.assert_not_nil(radiantTheme.fonts, "Theme should have fonts")
    
    -- Test shadow theme
    local shadowTheme = ui:getTheme("shadow")
    Test.assert_not_nil(shadowTheme, "Shadow theme should exist")
    Test.assert_not_nil(shadowTheme.colors, "Theme should have colors")
    Test.assert_not_nil(shadowTheme.fonts, "Theme should have fonts")
    
    -- Test twilight theme
    local twilightTheme = ui:getTheme("twilight")
    Test.assert_not_nil(twilightTheme, "Twilight theme should exist")
    Test.assert_not_nil(twilightTheme.colors, "Theme should have colors")
    Test.assert_not_nil(twilightTheme.fonts, "Theme should have fonts")
end

local function test_ui_interactions()
    local ui = UI.new()
    
    -- Create a button
    local button = ui:createButton("Test Button", 100, 100, 200, 50)
    local clicked = false
    
    button.onClick = function()
        clicked = true
    end
    
    -- Test button click
    ui:handleClick(150, 125)
    Test.assert(clicked, "Button should respond to click")
    
    -- Test button hover
    ui:handleHover(150, 125)
    Test.assert(button.isHovered, "Button should respond to hover")
end

local function test_ui_layout()
    local ui = UI.new()
    
    -- Create a panel with child elements
    local panel = ui:createPanel(100, 100, 300, 200)
    local button = ui:createButton("Test Button", 0, 0, 200, 50)
    local label = ui:createLabel("Test Label", 0, 50)
    
    panel:addChild(button)
    panel:addChild(label)
    
    -- Test layout
    panel:updateLayout()
    Test.assert_equals(button.x, 100, "Button should be positioned relative to panel")
    Test.assert_equals(button.y, 100, "Button should be positioned relative to panel")
    Test.assert_equals(label.x, 100, "Label should be positioned relative to panel")
    Test.assert_equals(label.y, 150, "Label should be positioned relative to panel")
end

local function test_ui_animations()
    local ui = UI.new()
    
    -- Create an animated element
    local element = ui:createAnimatedElement(100, 100, 200, 50)
    Test.assert_not_nil(element, "Animated element should be created")
    
    -- Test animation
    element:startAnimation("fade_in")
    Test.assert(element.isAnimating, "Element should be animating")
    
    -- Update animation
    ui:update(1.0)
    Test.assert(element.alpha > 0, "Element should fade in")
end

local function test_ui_tooltips()
    local ui = UI.new()
    
    -- Create a tooltip
    local tooltip = ui:createTooltip("Test Tooltip", 100, 100)
    Test.assert_not_nil(tooltip, "Tooltip should be created")
    Test.assert_equals(tooltip.text, "Test Tooltip", "Tooltip should have correct text")
    
    -- Test tooltip visibility
    tooltip:show()
    Test.assert(tooltip.isVisible, "Tooltip should be visible")
    
    tooltip:hide()
    Test.assert(not tooltip.isVisible, "Tooltip should be hidden")
end

local function test_ui_save_load()
    local ui = UI.new()
    
    -- Create some UI elements
    local button = ui:createButton("Test Button", 100, 100, 200, 50)
    local panel = ui:createPanel(100, 100, 300, 200)
    
    -- Save UI state
    local saveData = ui:saveState()
    Test.assert_not_nil(saveData, "UI should save state")
    
    -- Create new UI and load state
    local newUI = UI.new()
    newUI:loadState(saveData)
    
    -- Check that elements were restored
    Test.assert_not_nil(newUI:getElement(button.id), "Button should be restored")
    Test.assert_not_nil(newUI:getElement(panel.id), "Panel should be restored")
end

local function run_tests()
    local tests = {
        test_ui_initialization,
        test_ui_elements,
        test_ui_themes,
        test_ui_interactions,
        test_ui_layout,
        test_ui_animations,
        test_ui_tooltips,
        test_ui_save_load
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