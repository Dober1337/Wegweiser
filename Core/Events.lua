-- ============================================================
-- Core/Events.lua
-- Zentrale Event-Verteilung.
--
-- WoW meldet alles Wichtige über "Events" (z. B. PLAYER_LEVEL_UP).
-- Statt dass jedes Modul ein eigenes Frame anlegt, gibt es hier EIN
-- Frame, das Events empfängt und an alle interessierten Funktionen
-- weiterreicht.
--
-- Benutzung in einem Modul:
--   ns:RegisterEvent("PLAYER_LEVEL_UP", function(event, level) ... end)
-- ============================================================

local _, ns = ...

local frame = CreateFrame("Frame")
local handlers = {}   -- handlers["EVENTNAME"] = { funktion1, funktion2, ... }

function ns:RegisterEvent(event, callback)
    if not handlers[event] then
        handlers[event] = {}
        frame:RegisterEvent(event)
    end
    table.insert(handlers[event], callback)
end

frame:SetScript("OnEvent", function(_, event, ...)
    local list = handlers[event]
    if not list then return end
    for _, callback in ipairs(list) do
        -- securecallfunction: Fehler in einem Modul stoppen nicht die anderen.
        securecallfunction(callback, event, ...)
    end
end)
