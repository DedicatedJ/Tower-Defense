-- Sound and music. Every game event has a name; each name lists the files
-- that can voice it, best first, and the first one that exists is used. So
-- a new file (for example sounds/sfx/shot_holy.wav from the art pack) takes
-- over from its stand-in just by being added, with no code change.
--
--   Audio.init()                 load everything (main.lua, once)
--   Audio.play(name, opts)       play an event; opts.pitch, opts.volume
--   Audio.shot(projectileType)   a tower shot
--   Audio.playMusic(name)        loop a track (stops the one playing)
--   Audio.setVolumes(music, sfx) 0..1 each
--
-- Rapid events are thinned out: each name has a minimum gap between plays
-- and a cap on copies playing at once, so ten towers firing together
-- sound like a volley, not a wall of noise.

local Audio = {}

local SFX_DIR = "sounds/sfx/"

-- name -> { files (best first), gap = min seconds between plays,
--           max = copies at once, vol = relative volume, vary = pitch spread }
Audio.EVENTS = {
    click      = { files = { "button_click" }, gap = 0.05, max = 2 },
    place      = { files = { "tower_place" }, gap = 0.05, max = 2 },
    sell       = { files = { "tower_sell" }, gap = 0.05, max = 2 },
    upgrade    = { files = { "tower_upgrade" }, gap = 0.05, max = 2 },
    wave_start = { files = { "wave_start" }, gap = 0.5, max = 1 },
    enemy_hit  = { files = { "enemy_hit" }, gap = 0.06, max = 3, vol = 0.45, vary = 0.12 },
    enemy_die  = { files = { "enemy_die", "enemy_death" }, gap = 0.05, max = 4, vol = 0.7, vary = 0.1 },
    life_lost  = { files = { "player_damage", "enemy_hit" }, gap = 0.25, max = 2 },
    ability    = { files = { "hero_ability", "shot_magic" }, gap = 0.1, max = 2 },
    level_up   = { files = { "level_up", "tower_upgrade" }, gap = 0.3, max = 1 },
    purchase   = { files = { "purchase", "tower_place" }, gap = 0.1, max = 1 },
    victory    = { files = { "victory" }, gap = 1, max = 1 },
    defeat     = { files = { "game_over" }, gap = 1, max = 1 },
}

-- Tower shots by projectileType (data/factions.lua). Each falls back to the
-- closest of the four shot sounds that exist today.
Audio.SHOT_FALLBACK = {
    holy = "shot_magic", fire = "shot_cannon", bolt = "shot_sniper", poison = "shot_magic",
    void = "shot_magic", soul = "shot_magic", hybrid = "shot_magic", frost = "shot_magic",
}
local SHOT = { gap = 0.07, max = 4, vol = 0.5, vary = 0.08 }

Audio.MUSIC = { menu = "menu", game = "game", victory = "victory", defeat = "defeat" }

Audio.sources = {}      -- file stem -> static Source (nil if missing)
Audio.music = {}        -- track -> stream Source
Audio.lastPlayed = {}   -- event name -> time
Audio.playing = {}      -- event name -> list of clones
Audio.counts = {}       -- event name -> plays (read by tests)
Audio.volumes = { music = 1, sfx = 1 }
Audio.enabled = true    -- false: count plays but make no sound (tests)

local function now() return love.timer.getTime() end

local function loadStatic(stem)
    if Audio.sources[stem] ~= nil then return Audio.sources[stem] or nil end
    local path = SFX_DIR .. stem .. ".wav"
    local src = false
    if love.filesystem.getInfo(path) then
        local ok, s = pcall(love.audio.newSource, path, "static")
        if ok then src = s else print("WARNING: could not load " .. path) end
    end
    Audio.sources[stem] = src
    return src or nil
end

-- The music folder is "sounds/Music" in the repo; look it up either way so
-- it also works on case-sensitive systems and inside a .love file
local function musicPath(track)
    for _, dir in ipairs({ "sounds/music/", "sounds/Music/" }) do
        local p = dir .. track .. ".mp3"
        if love.filesystem.getInfo(p) then return p end
    end
end

function Audio.init()
    if Audio.initialized then return end
    Audio.initialized = true
    if not love.audio then Audio.enabled = false; return end
    for _, ev in pairs(Audio.EVENTS) do
        for _, stem in ipairs(ev.files) do loadStatic(stem) end
    end
    for _, stem in pairs(Audio.SHOT_FALLBACK) do loadStatic(stem) end
    loadStatic("shot_basic")
    for name, track in pairs(Audio.MUSIC) do
        local p = musicPath(track)
        if p then
            local ok, s = pcall(love.audio.newSource, p, "stream")
            if ok then
                s:setLooping(name == "menu" or name == "game")
                Audio.music[name] = s
            end
        end
    end
end

-- Which file voices an event (nil if none exists)
function Audio.resolve(name)
    local ev = Audio.EVENTS[name]
    if not ev then return nil end
    for _, stem in ipairs(ev.files) do
        if loadStatic(stem) then return stem end
    end
end

function Audio.resolveShot(projectileType)
    local own = "shot_" .. tostring(projectileType)
    if loadStatic(own) then return own end
    local fb = Audio.SHOT_FALLBACK[projectileType]
    if fb and loadStatic(fb) then return fb end
    if loadStatic("shot_basic") then return "shot_basic" end
end

-- Play `stem` under event key `key` with rules `rule`. Returns true if it
-- played (or would have, with sound disabled).
local function fire(key, stem, rule, opts)
    if not stem then return false end
    local t = now()
    if Audio.lastPlayed[key] and t - Audio.lastPlayed[key] < (rule.gap or 0) then return false end
    local list = Audio.playing[key] or {}
    for i = #list, 1, -1 do
        if not list[i]:isPlaying() then table.remove(list, i) end
    end
    Audio.playing[key] = list
    if #list >= (rule.max or 3) then return false end
    Audio.lastPlayed[key] = t
    Audio.counts[key] = (Audio.counts[key] or 0) + 1
    if not Audio.enabled then return true end

    local s = Audio.sources[stem]:clone()
    opts = opts or {}
    s:setVolume(Audio.volumes.sfx * (rule.vol or 1) * (opts.volume or 1))
    local vary = rule.vary or 0
    s:setPitch((opts.pitch or 1) * (1 + (love.math.random() * 2 - 1) * vary))
    s:play()
    list[#list + 1] = s
    return true
end

function Audio.play(name, opts)
    local ev = Audio.EVENTS[name]
    if not ev then return false end
    return fire(name, Audio.resolve(name), ev, opts)
end

function Audio.shot(projectileType)
    return fire("shot_" .. tostring(projectileType), Audio.resolveShot(projectileType), SHOT)
end

function Audio.playMusic(name)
    if Audio.currentMusic == name then return end
    Audio.stopMusic()
    local s = Audio.music[name]
    Audio.currentMusic = name
    Audio.counts["music:" .. name] = (Audio.counts["music:" .. name] or 0) + 1
    if not s or not Audio.enabled then return end
    s:setVolume(Audio.volumes.music)
    s:play()
end

function Audio.stopMusic()
    local s = Audio.currentMusic and Audio.music[Audio.currentMusic]
    if s then s:stop() end
    Audio.currentMusic = nil
end

function Audio.setVolumes(music, sfx)
    if music then Audio.volumes.music = math.max(0, math.min(1, music)) end
    if sfx then Audio.volumes.sfx = math.max(0, math.min(1, sfx)) end
    local s = Audio.currentMusic and Audio.music[Audio.currentMusic]
    if s then s:setVolume(Audio.volumes.music) end
end

return Audio
