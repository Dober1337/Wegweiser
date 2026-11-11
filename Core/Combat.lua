-- ============================================================
-- Core/Combat.lua
-- Regel des Addons: Alles, was Fenster öffnet, Frames verändert oder
-- Daten abfragt, passiert nur AUSSERHALB des Kampfes.
--
-- ns:RunOutOfCombat(funktion) führt die Funktion sofort aus, wenn man
-- nicht im Kampf ist. Sonst merkt sie sich die Funktion und führt sie
-- aus, sobald der Kampf vorbei ist (Event PLAYER_REGEN_ENABLED).
-- ============================================================

local _, ns = ...

local queue = {}

function ns:InCombat()
    return InCombatLockdown() or UnitAffectingCombat("player")
end

-- silent = true: keine Chat-Meldung "wird nach dem Kampf ausgeführt"
function ns:RunOutOfCombat(func, silent)
    if not self:InCombat() then
        func()
        return
    end
    table.insert(queue, func)
    if not silent then
        self:Print(self.L.IN_COMBAT_QUEUED)
    end
end

ns:RegisterEvent("PLAYER_REGEN_ENABLED", function()
    -- Warteschlange abarbeiten. Kopie, falls währenddessen Neues dazukommt.
    local pending = queue
    queue = {}
    for _, func in ipairs(pending) do
        securecallfunction(func)
    end
end)
