-- Replaces any word by word operations such that it can be activated by cmd too
-- Low-level event tap for faster key handling
local function handleKey(event)
    local keyCode = event:getKeyCode()
    local modifiers = event:getFlags()
    
    if modifiers.cmd and not modifiers.alt and not modifiers.shift and not modifiers.ctrl then
        if keyCode == hs.keycodes.map["left"] then
            hs.eventtap.keyStroke({"alt"}, "left", 0)
            return true -- Consume the original event
        elseif keyCode == hs.keycodes.map["right"] then
            hs.eventtap.keyStroke({"alt"}, "right", 0)
            return true
        elseif keyCode == hs.keycodes.map["up"] then
            hs.eventtap.keyStroke({"alt"}, "up", 0)
            return true
        elseif keyCode == hs.keycodes.map["down"] then
            hs.eventtap.keyStroke({"alt"}, "down", 0)
            return true
        elseif keyCode == hs.keycodes.map["delete"] then
            hs.eventtap.keyStroke({"alt"}, "delete", 0)
            return true
        elseif keyCode == hs.keycodes.map["forwarddelete"] then
            hs.eventtap.keyStroke({"alt"}, "forwarddelete", 0)
            return true
        end

    elseif modifiers.cmd and modifiers.shift and not modifiers.alt and not modifiers.ctrl then
        if keyCode == hs.keycodes.map["left"] then
            hs.eventtap.keyStroke({"alt", "shift"}, "left", 0)
            return true
        elseif keyCode == hs.keycodes.map["right"] then
            hs.eventtap.keyStroke({"alt", "shift"}, "right", 0)
            return true
        elseif keyCode == hs.keycodes.map["up"] then
            hs.eventtap.keyStroke({"alt", "shift"}, "up", 0)
            return true
        elseif keyCode == hs.keycodes.map["down"] then
            hs.eventtap.keyStroke({"alt", "shift"}, "down", 0)
            return true
        elseif keyCode == hs.keycodes.map["delete"] then
            hs.eventtap.keyStroke({"alt", "shift"}, "delete", 0)
            return true
        elseif keyCode == hs.keycodes.map["forwarddelete"] then
            hs.eventtap.keyStroke({"alt", "shift"}, "forwarddelete", 0)
            return true
        end
    end
    return false -- Pass through other events
end

keyTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, handleKey)
keyTap:start()




-- solution and todos:
-- skip wezterm during lua code,
-- integrate wezterm config
-- wezterm forward delete is incorrect
-- deleting file in Finder will not work, hence you need to remap delete file to be just ... delete
