-- ============================================================
-- Core/SettingsPanel.lua
-- Einstellungsfenster unter ESC -> Optionen -> AddOns -> Wegweiser.
--
-- Benutzt Blizzards modernes Settings-System (geprüft im Forever-
-- UI-Quellcode: Settings.RegisterVerticalLayoutCategory,
-- Settings.RegisterAddOnSetting, Settings.CreateCheckbox).
-- Die Häkchen schreiben direkt in WegweiserDB.settings.
-- ============================================================

local ADDON_NAME, ns = ...
local L = ns.L

-- Wird von Core/Settings.lua aufgerufen, sobald WegweiserDB geladen ist.
function ns:OnDatabaseReady()
    if not Settings or not Settings.RegisterVerticalLayoutCategory then
        return  -- Settings-API fehlt: dann eben ohne Fenster (Befehle gehen trotzdem)
    end

    local category = Settings.RegisterVerticalLayoutCategory(L.SETTINGS_TITLE)

    -- Ein Häkchen anlegen. key = Name in WegweiserDB.settings
    local function addCheckbox(key, label, tooltip)
        local setting = Settings.RegisterAddOnSetting(
            category,
            ADDON_NAME .. "_" .. key,   -- eindeutiger interner Name
            key,                        -- Schlüssel in der Tabelle
            ns.db.settings,             -- Tabelle, in die gespeichert wird
            "boolean",                  -- Typ
            label,                      -- angezeigter Text
            ns.defaults.settings[key]   -- Standardwert
        )
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    -- Modul: Level-Up-Hinweise
    addCheckbox("levelUp",       L.OPT_LEVELUP,  L.OPT_LEVELUP_TT)
    addCheckbox("trainerHint",   L.OPT_TRAINER,  L.OPT_TRAINER_TT)
    addCheckbox("talentHint",    L.OPT_TALENT,   L.OPT_TALENT_TT)
    addCheckbox("loginReminder", L.OPT_LOGIN,    L.OPT_LOGIN_TT)
    addCheckbox("onScreen",      L.OPT_ONSCREEN, L.OPT_ONSCREEN_TT)
    -- Modul: Talent-Leitfaden
    addCheckbox("talentGuide",   L.OPT_GUIDE,    L.OPT_GUIDE_TT)
    addCheckbox("talentHighlight", L.OPT_HIGHLIGHT, L.OPT_HIGHLIGHT_TT)
    -- Modul: Quest-Berater
    addCheckbox("questAdvisor",    L.OPT_QUESTS,    L.OPT_QUESTS_TT)
    addCheckbox("questOfferHint",  L.OPT_QOFFER,    L.OPT_QOFFER_TT)
    addCheckbox("questLogIcons",   L.OPT_QICONS,    L.OPT_QICONS_TT)
    addCheckbox("questAcceptHint", L.OPT_QACCEPT,   L.OPT_QACCEPT_TT)
    -- Zonen
    addCheckbox("zoneMapLevels",   L.OPT_MAPLVL,    L.OPT_MAPLVL_TT)
    addCheckbox("zoneAdvice",      L.OPT_ZADVICE,   L.OPT_ZADVICE_TT)
    -- Weitere Module (Talent-Leitfaden, Zonen, Quests, ...) kommen hier dazu,
    -- sobald sie gebaut sind.

    Settings.RegisterAddOnCategory(category)
    ns.settingsCategory = category
end

-- Öffnet das Einstellungsfenster (nur außerhalb des Kampfes).
function ns:OpenSettings()
    if not self.settingsCategory then return end
    self:RunOutOfCombat(function()
        Settings.OpenToCategory(self.settingsCategory:GetID())
    end)
end
