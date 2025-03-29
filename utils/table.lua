local Table = {}

-- Deep copy a table
function Table.copy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = Table.copy(v)
    end
    return copy
end

-- Check if a table contains a value
function Table.contains(t, value)
    for _, v in pairs(t) do
        if v == value then
            return true
        end
    end
    return false
end

-- Merge two tables
function Table.merge(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k]) == "table" then
            Table.merge(t1[k], v)
        else
            t1[k] = v
        end
    end
    return t1
end

-- Get table length (for both numeric and non-numeric keys)
function Table.length(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Remove a value from a table
function Table.removeValue(t, value)
    for k, v in pairs(t) do
        if v == value then
            table.remove(t, k)
            return true
        end
    end
    return false
end

-- Check if a table is empty
function Table.isEmpty(t)
    return next(t) == nil
end

-- Clear all values from a table
function Table.clear(t)
    for k in pairs(t) do
        t[k] = nil
    end
end

-- Get a random value from a table
function Table.random(t)
    local keys = {}
    for k in pairs(t) do
        keys[#keys + 1] = k
    end
    if #keys == 0 then return nil end
    return t[keys[love.math.random(#keys)]]
end

-- Shuffle a table
function Table.shuffle(t)
    local n = #t
    while n > 1 do
        local k = love.math.random(n)
        t[n], t[k] = t[k], t[n]
        n = n - 1
    end
    return t
end

-- Filter a table based on a predicate function
function Table.filter(t, predicate)
    local result = {}
    for k, v in pairs(t) do
        if predicate(v, k) then
            result[k] = v
        end
    end
    return result
end

-- Map a function over a table
function Table.map(t, f)
    local result = {}
    for k, v in pairs(t) do
        result[k] = f(v, k)
    end
    return result
end

-- Reduce a table to a single value
function Table.reduce(t, f, initial)
    local result = initial
    for k, v in pairs(t) do
        result = f(result, v, k)
    end
    return result
end

return Table 