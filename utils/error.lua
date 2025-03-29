local Error = {}

-- Error types
Error.TYPES = {
    SYSTEM = "SYSTEM",
    GAME = "GAME",
    UI = "UI",
    SAVE = "SAVE",
    LOAD = "LOAD",
    NETWORK = "NETWORK"
}

-- Error messages
Error.MESSAGES = {
    -- System errors
    [Error.TYPES.SYSTEM] = {
        INIT_FAILED = "Failed to initialize system: %s",
        RESOURCE_MISSING = "Required resource missing: %s",
        INVALID_STATE = "Invalid game state: %s",
        INVALID_OPERATION = "Invalid operation: %s"
    },
    
    -- Game errors
    [Error.TYPES.GAME] = {
        INVALID_TOWER = "Invalid tower type: %s",
        INVALID_ENEMY = "Invalid enemy type: %s",
        INVALID_WAVE = "Invalid wave configuration: %s",
        INVALID_MAP = "Invalid map configuration: %s",
        INSUFFICIENT_RESOURCES = "Insufficient resources for %s",
        INVALID_PLACEMENT = "Invalid tower placement at (%d, %d)"
    },
    
    -- UI errors
    [Error.TYPES.UI] = {
        ELEMENT_NOT_FOUND = "UI element not found: %s",
        INVALID_INPUT = "Invalid input: %s",
        RENDER_FAILED = "Failed to render UI element: %s"
    },
    
    -- Save errors
    [Error.TYPES.SAVE] = {
        SAVE_FAILED = "Failed to save game: %s",
        INVALID_SAVE_DATA = "Invalid save data: %s",
        SAVE_CORRUPTED = "Save file corrupted: %s"
    },
    
    -- Load errors
    [Error.TYPES.LOAD] = {
        LOAD_FAILED = "Failed to load game: %s",
        FILE_NOT_FOUND = "Save file not found: %s",
        VERSION_MISMATCH = "Save file version mismatch: %s"
    },
    
    -- Network errors
    [Error.TYPES.NETWORK] = {
        CONNECTION_FAILED = "Failed to connect: %s",
        TIMEOUT = "Operation timed out: %s",
        INVALID_RESPONSE = "Invalid server response: %s"
    }
}

-- Error handling function
function Error.handle(errorType, message, ...)
    local formattedMessage = string.format(Error.MESSAGES[errorType][message] or message, ...)
    
    -- Log error
    print(string.format("[%s] %s", errorType, formattedMessage))
    
    -- Show error to user
    if love.graphics then
        -- Create error notification
        if not Error.notifications then
            Error.notifications = {}
        end
        
        table.insert(Error.notifications, {
            message = formattedMessage,
            type = errorType,
            time = 0,
            duration = 5 -- seconds
        })
    end
end

-- Assert function with error handling
function Error.assert(condition, errorType, message, ...)
    if not condition then
        Error.handle(errorType, message, ...)
        return false
    end
    return true
end

-- Safe function call with error handling
function Error.pcall(f, ...)
    local success, result = pcall(f, ...)
    if not success then
        Error.handle(Error.TYPES.SYSTEM, "INVALID_OPERATION", result)
        return false, result
    end
    return true, result
end

-- Update error notifications
function Error.update(dt)
    if not Error.notifications then return end
    
    for i = #Error.notifications, 1, -1 do
        local notification = Error.notifications[i]
        notification.time = notification.time + dt
        
        if notification.time >= notification.duration then
            table.remove(Error.notifications, i)
        end
    end
end

-- Draw error notifications
function Error.draw()
    if not Error.notifications then return end
    
    local y = 20
    for _, notification in ipairs(Error.notifications) do
        -- Calculate alpha based on time
        local alpha = 1 - (notification.time / notification.duration)
        
        -- Set color based on error type
        local r, g, b = 1, 0, 0 -- Default red
        if notification.type == Error.TYPES.SYSTEM then
            r, g, b = 1, 0, 0 -- Red
        elseif notification.type == Error.TYPES.GAME then
            r, g, b = 1, 1, 0 -- Yellow
        elseif notification.type == Error.TYPES.UI then
            r, g, b = 0, 1, 0 -- Green
        elseif notification.type == Error.TYPES.SAVE or notification.type == Error.TYPES.LOAD then
            r, g, b = 0, 0, 1 -- Blue
        elseif notification.type == Error.TYPES.NETWORK then
            r, g, b = 1, 0, 1 -- Purple
        end
        
        -- Draw notification background
        love.graphics.setColor(r, g, b, 0.3 * alpha)
        love.graphics.rectangle("fill", 20, y, love.graphics.getWidth() - 40, 30)
        
        -- Draw notification text
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.print(notification.message, 30, y + 5)
        
        y = y + 40
    end
end

-- Show simple error message (convenience function)
function Error.show(message)
    Error.handle(Error.TYPES.SYSTEM, "INVALID_OPERATION", message)
end

return Error 