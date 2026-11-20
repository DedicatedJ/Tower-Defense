-- Minimal JSON encoder/decoder for save files and settings.
-- encode(value) -> string; decode(string) -> value (errors on malformed input).
-- Tables with only consecutive integer keys from 1 encode as arrays; empty
-- tables encode as objects. Functions and userdata are skipped.

local json = {}

local escapes = {
    ['"'] = '\\"', ['\\'] = '\\\\', ['\b'] = '\\b', ['\f'] = '\\f',
    ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t'
}

local function escapeString(s)
    return '"' .. s:gsub('[%c"\\]', function(c)
        return escapes[c] or string.format('\\u%04x', c:byte())
    end) .. '"'
end

local function isArray(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    if n == 0 then return false end
    for i = 1, n do
        if t[i] == nil then return false end
    end
    return true
end

local encodeValue

local function encodeTable(t, stack)
    if stack[t] then error("json.encode: circular reference") end
    stack[t] = true
    local parts = {}
    if isArray(t) then
        for i = 1, #t do
            parts[#parts + 1] = encodeValue(t[i], stack)
        end
        stack[t] = nil
        return '[' .. table.concat(parts, ',') .. ']'
    end
    for k, v in pairs(t) do
        local vt = type(v)
        if vt ~= 'function' and vt ~= 'userdata' and vt ~= 'thread' then
            local kt = type(k)
            if kt ~= 'string' and kt ~= 'number' then
                error("json.encode: unsupported key type " .. kt)
            end
            parts[#parts + 1] = escapeString(tostring(k)) .. ':' .. encodeValue(v, stack)
        end
    end
    stack[t] = nil
    return '{' .. table.concat(parts, ',') .. '}'
end

encodeValue = function(v, stack)
    local t = type(v)
    if t == 'nil' then return 'null' end
    if t == 'boolean' then return tostring(v) end
    if t == 'number' then
        if v ~= v or v == math.huge or v == -math.huge then
            error("json.encode: cannot encode " .. tostring(v))
        end
        if math.floor(v) == v and math.abs(v) < 2^53 then
            return string.format('%d', v)
        end
        return string.format('%.14g', v)
    end
    if t == 'string' then return escapeString(v) end
    if t == 'table' then return encodeTable(v, stack) end
    error("json.encode: unsupported type " .. t)
end

function json.encode(v)
    return encodeValue(v, {})
end

-- Decoder ---------------------------------------------------------------

local function decodeError(str, pos, msg)
    error(string.format("json.decode: %s at position %d", msg, pos))
end

local function skipWhitespace(str, pos)
    return str:find('[^ \t\r\n]', pos) or #str + 1
end

local decodeValue

local function codepointToUtf8(n)
    if n < 0x80 then return string.char(n) end
    if n < 0x800 then
        return string.char(0xC0 + math.floor(n / 0x40), 0x80 + n % 0x40)
    end
    if n < 0x10000 then
        return string.char(0xE0 + math.floor(n / 0x1000),
            0x80 + math.floor(n / 0x40) % 0x40, 0x80 + n % 0x40)
    end
    return string.char(0xF0 + math.floor(n / 0x40000),
        0x80 + math.floor(n / 0x1000) % 0x40,
        0x80 + math.floor(n / 0x40) % 0x40, 0x80 + n % 0x40)
end

local function decodeString(str, pos)
    local buf = {}
    local i = pos + 1
    while true do
        local c = str:sub(i, i)
        if c == '' then decodeError(str, i, "unterminated string") end
        if c == '"' then return table.concat(buf), i + 1 end
        if c == '\\' then
            local e = str:sub(i + 1, i + 1)
            local map = { ['"'] = '"', ['\\'] = '\\', ['/'] = '/', b = '\b',
                          f = '\f', n = '\n', r = '\r', t = '\t' }
            if map[e] then
                buf[#buf + 1] = map[e]
                i = i + 2
            elseif e == 'u' then
                local hex = str:sub(i + 2, i + 5)
                local n = tonumber(hex, 16)
                if not n or #hex < 4 then decodeError(str, i, "bad unicode escape") end
                i = i + 6
                -- surrogate pair
                if n >= 0xD800 and n <= 0xDBFF and str:sub(i, i + 1) == '\\u' then
                    local lo = tonumber(str:sub(i + 2, i + 5), 16)
                    if lo and lo >= 0xDC00 and lo <= 0xDFFF then
                        n = 0x10000 + (n - 0xD800) * 0x400 + (lo - 0xDC00)
                        i = i + 6
                    end
                end
                buf[#buf + 1] = codepointToUtf8(n)
            else
                decodeError(str, i, "bad escape")
            end
        else
            buf[#buf + 1] = c
            i = i + 1
        end
    end
end

local function decodeArray(str, pos)
    local arr = {}
    local i = skipWhitespace(str, pos + 1)
    if str:sub(i, i) == ']' then return arr, i + 1 end
    while true do
        local v
        v, i = decodeValue(str, i)
        arr[#arr + 1] = v
        i = skipWhitespace(str, i)
        local c = str:sub(i, i)
        if c == ']' then return arr, i + 1 end
        if c ~= ',' then decodeError(str, i, "expected ',' or ']'") end
        i = skipWhitespace(str, i + 1)
    end
end

local function decodeObject(str, pos)
    local obj = {}
    local i = skipWhitespace(str, pos + 1)
    if str:sub(i, i) == '}' then return obj, i + 1 end
    while true do
        if str:sub(i, i) ~= '"' then decodeError(str, i, "expected string key") end
        local k
        k, i = decodeString(str, i)
        i = skipWhitespace(str, i)
        if str:sub(i, i) ~= ':' then decodeError(str, i, "expected ':'") end
        i = skipWhitespace(str, i + 1)
        local v
        v, i = decodeValue(str, i)
        obj[k] = v
        i = skipWhitespace(str, i)
        local c = str:sub(i, i)
        if c == '}' then return obj, i + 1 end
        if c ~= ',' then decodeError(str, i, "expected ',' or '}'") end
        i = skipWhitespace(str, i + 1)
    end
end

decodeValue = function(str, pos)
    pos = skipWhitespace(str, pos)
    local c = str:sub(pos, pos)
    if c == '{' then return decodeObject(str, pos) end
    if c == '[' then return decodeArray(str, pos) end
    if c == '"' then return decodeString(str, pos) end
    if str:sub(pos, pos + 3) == 'true' then return true, pos + 4 end
    if str:sub(pos, pos + 4) == 'false' then return false, pos + 5 end
    if str:sub(pos, pos + 3) == 'null' then return nil, pos + 4 end
    local num = str:match('^-?%d+%.?%d*[eE]?[-+]?%d*', pos)
    if num and #num > 0 then
        local n = tonumber(num)
        if not n then decodeError(str, pos, "bad number") end
        return n, pos + #num
    end
    decodeError(str, pos, "unexpected character '" .. c .. "'")
end

function json.decode(str)
    if type(str) ~= 'string' then
        error("json.decode: expected string, got " .. type(str))
    end
    local value, pos = decodeValue(str, 1)
    pos = skipWhitespace(str, pos)
    if pos <= #str then decodeError(str, pos, "trailing garbage") end
    return value
end

return json
