local Test = {}

function Test.assert(condition, message)
    if not condition then
        error("Test failed: " .. message)
    end
end

function Test.assert_equals(actual, expected, message)
    if actual ~= expected then
        error(string.format("Test failed: %s (expected %s, got %s)", 
            message, tostring(expected), tostring(actual)))
    end
end

function Test.assert_almost_equals(actual, expected, tolerance, message)
    tolerance = tolerance or 0.0001
    if math.abs(actual - expected) > tolerance then
        error(string.format("Test failed: %s (expected %s, got %s, tolerance %s)", 
            message, tostring(expected), tostring(actual), tostring(tolerance)))
    end
end

function Test.assert_table_equals(actual, expected, message)
    if type(actual) ~= "table" or type(expected) ~= "table" then
        error(string.format("Test failed: %s (expected table, got %s)", 
            message, type(actual)))
    end
    
    for k, v in pairs(expected) do
        if actual[k] ~= v then
            error(string.format("Test failed: %s (key %s: expected %s, got %s)", 
                message, tostring(k), tostring(v), tostring(actual[k])))
        end
    end
    
    for k, v in pairs(actual) do
        if expected[k] == nil then
            error(string.format("Test failed: %s (unexpected key %s with value %s)", 
                message, tostring(k), tostring(v)))
        end
    end
end

function Test.assert_nil(value, message)
    if value ~= nil then
        error(string.format("Test failed: %s (expected nil, got %s)", 
            message, tostring(value)))
    end
end

function Test.assert_not_nil(value, message)
    if value == nil then
        error(string.format("Test failed: %s (expected non-nil value)", message))
    end
end

function Test.assert_type(value, expected_type, message)
    if type(value) ~= expected_type then
        error(string.format("Test failed: %s (expected type %s, got %s)", 
            message, expected_type, type(value)))
    end
end

function Test.assert_throws(func, expected_error, message)
    local success, error = pcall(func)
    if success then
        error(string.format("Test failed: %s (expected error, got success)", message))
    end
    if expected_error and not string.match(error, expected_error) then
        error(string.format("Test failed: %s (expected error '%s', got '%s')", 
            message, expected_error, error))
    end
end

function Test.assert_in_range(value, min, max, message)
    if value < min or value > max then
        error(string.format("Test failed: %s (value %s not in range [%s, %s])", 
            message, tostring(value), tostring(min), tostring(max)))
    end
end

function Test.assert_contains(table, value, message)
    for _, v in ipairs(table) do
        if v == value then
            return
        end
    end
    error(string.format("Test failed: %s (value %s not found in table)", 
        message, tostring(value)))
end

function Test.assert_not_contains(table, value, message)
    for _, v in ipairs(table) do
        if v == value then
            error(string.format("Test failed: %s (value %s found in table when it shouldn't be)", 
                message, tostring(value)))
        end
    end
end

return Test 