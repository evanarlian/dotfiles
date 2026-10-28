-- Replaces word-by-word operations so they can be activated with Cmd instead of Alt/Opt.
-- Excludes Finder so native shortcuts (Cmd+Delete to Trash, Cmd+Up/Down navigation) still work.

-- Pre-compute target keycodes once at startup
local targetKeys = {
    [hs.keycodes.map["left"]]          = true,
    [hs.keycodes.map["right"]]         = true,
    [hs.keycodes.map["up"]]            = true,
    [hs.keycodes.map["down"]]          = true,
    [hs.keycodes.map["delete"]]        = true,
    [hs.keycodes.map["forwarddelete"]] = true,
}

local function handleKey(event)
    -- Re-enable the eventtap if macOS disables it due to a system timeout
    local eventType = event:getType()
    if eventType == hs.eventtap.event.types.tapDisabledByTimeout or
       eventType == hs.eventtap.event.types.tapDisabledByUserInput then
        keyTap:start()
        return false
    end

    -- Fast exit for non-target keys (runs on every keystroke)
    local keyCode = event:getKeyCode()
    if not targetKeys[keyCode] then
        return false
    end

    local flags = event:getFlags()

    -- Match Cmd (with optional Shift), but no Alt or Ctrl
    if flags.cmd and not flags.alt and not flags.ctrl then
        -- Bypass remapping in Finder so Cmd+Delete (Move to Trash) and Cmd+Up/Down work natively
        local frontApp = hs.application.frontmostApplication()
        if frontApp and frontApp:bundleID() == "com.apple.finder" then
            return false
        end

        -- Mutate the event in-place from Cmd to Alt (preserving Shift and fn)
        event:setFlags({
            alt   = true,
            shift = flags.shift,
            fn    = flags.fn,
        })
        return false
    end

    return false
end

-- Keep keyTap global so Lua's garbage collector doesn't collect it
keyTap = hs.eventtap.new({
    hs.eventtap.event.types.keyDown,
    hs.eventtap.event.types.keyUp,
    hs.eventtap.event.types.tapDisabledByTimeout,
    hs.eventtap.event.types.tapDisabledByUserInput,
}, handleKey)

keyTap:start()
