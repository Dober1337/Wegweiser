-- ============================================================
-- Data/Constants.lua
-- Feste Spielregeln, die das Addon braucht.
-- verified = true heißt: vom Spieler im Spiel bestätigt.
-- ============================================================

local _, ns = ...

ns.Constants = {
    -- Erster Talentpunkt auf Level 10, danach 1 Punkt pro Level (51 bis Level 60).
    FIRST_TALENT_LEVEL = { value = 10, verified = true },  -- vom Spieler bestätigt, Nov 2026
    MAX_LEVEL          = { value = 60, verified = true },  -- vom Spieler bestätigt
    -- Punkte, die pro Reihe im selben Baum nötig sind: Reihe n braucht (n-1) * 5.
    POINTS_PER_TIER    = { value = 5,  verified = true },  -- vom Spieler bestätigt
}

-- Kurzform, damit Module nicht immer ".value" schreiben müssen.
function ns:Const(name)
    local entry = ns.Constants[name]
    return entry and entry.value
end
