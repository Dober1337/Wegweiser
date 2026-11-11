-- ============================================================
-- Modules/LevelUp.lua
-- Modul 1: freundliche Hinweise beim Levelaufstieg.
--
-- Was passiert:
--   * Beim Levelaufstieg: Glückwunsch + Erinnerung an den Klassenlehrer.
--   * Auf Level 10 (FIRST_TALENT_LEVEL): Erklärung, dass es jetzt Talentpunkte gibt.
--   * Wenn freie Talentpunkte vorhanden sind: Hinweis mit Tastenbelegung.
--   * Optional direkt nach dem Einloggen: Erinnerung an freie Talentpunkte.
--
-- Hinweis Klassenlehrer: Ob es auf einem Level WIRKLICH etwas Neues gibt,
-- weiß das Addon erst mit Data/Skills.lua (Skill-Berater). Bis dahin ist
-- der Hinweis bewusst allgemein formuliert ("vielleicht").
-- ============================================================

local _, ns = ...
local L = ns.L

local LevelUp = {}
ns.modules.LevelUp = LevelUp

-- Kurze Abkürzung auf die Einstellungen
local function settings()
    return ns.db and ns.db.settings or ns.defaults.settings
end

-- Prüft die freien Talentpunkte und meldet sie, falls > 0.
function LevelUp:CheckTalentPoints()
    if not settings().talentHint then return end

    local spent, unspent = ns.TalentAPI:GetPoints()
    if not spent then return end            -- API liefert (noch) nichts
    if unspent <= 0 then return end

    local key = ns.TalentAPI:GetTalentKeyText() or L.TALENT_KEY_UNKNOWN
    if unspent == 1 then
        ns:Notify(L.TALENT_UNSPENT_ONE, key)
    else
        ns:Notify(L.TALENT_UNSPENT_MANY, unspent, key)
    end
end

-- Zeigt alle Level-Up-Hinweise für ein bestimmtes Level an.
-- Wird auch von /ww test benutzt.
function LevelUp:ShowLevelUpMessages(level)
    ns:Notify(L.LEVELUP_CONGRATS, level)

    if settings().trainerHint then
        ns:Print(L.LEVELUP_TRAINER)
    end

    if level == ns:Const("FIRST_TALENT_LEVEL") then
        ns:Print(L.LEVELUP_FIRST_TALENT)
    end
end

function LevelUp:OnInitialize()
    -- Event: Levelaufstieg. Erstes Argument ist das neue Level.
    ns:RegisterEvent("PLAYER_LEVEL_UP", function(_, newLevel)
        if not settings().levelUp then return end

        -- Die Nachrichten selbst sind harmlos und dürfen auch im Kampf kommen
        -- (man levelt oft mitten im Kampf). Das Abfragen der Talentdaten
        -- verschieben wir aber auf "nach dem Kampf".
        LevelUp:ShowLevelUpMessages(newLevel)

        -- Der Server aktualisiert die Talentpunkte einen Moment NACH dem
        -- Levelaufstieg. Deshalb kurz warten (2 Sekunden).
        C_Timer.After(2, function()
            ns:RunOutOfCombat(function() LevelUp:CheckTalentPoints() end, true)
        end)
    end)

    -- Erinnerung nach dem Einloggen bzw. /reload.
    ns:RegisterEvent("PLAYER_ENTERING_WORLD", function(_, isInitialLogin, isReloadingUi)
        if not (isInitialLogin or isReloadingUi) then return end  -- nicht bei jedem Ladebildschirm
        if not settings().levelUp or not settings().loginReminder then return end
        C_Timer.After(5, function()
            ns:RunOutOfCombat(function() LevelUp:CheckTalentPoints() end, true)
        end)
    end)
end
