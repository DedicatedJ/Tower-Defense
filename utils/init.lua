-- Utils module - combines all utility functions in one convenient package
local Utils = {}

-- Import utility modules
local MathUtils = require("utils.math")
local TableUtils = require("utils.table")
local Error = require("utils.error")

-- Copy all functions from MathUtils to Utils
for k, v in pairs(MathUtils) do
    Utils[k] = v
end

-- Copy all functions from TableUtils to Utils
for k, v in pairs(TableUtils) do
    Utils[k] = v
end

-- Add ID generator function if it doesn't exist in other modules
if not Utils.generateID then
    local ids = {}
    function Utils.generateID(prefix)
        prefix = prefix or "id"
        ids[prefix] = (ids[prefix] or 0) + 1
        return prefix .. "_" .. ids[prefix]
    end
end

-- Export Error module
Utils.Error = Error

return Utils
