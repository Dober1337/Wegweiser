-- ============================================================
-- Core/Settings.lua
-- Gespeicherte Daten (SavedVariables).
--
-- In der .toc steht "## SavedVariables: WegweiserDB". WoW speichert
-- diese globale Tabelle beim Ausloggen bzw. bei /reload in die Datei
--   WTF\Account\<KONTONAME>\SavedVariables\Wegweiser.lua
-- und lädt sie beim nächsten Start wieder.
--
-- Hier legen wir die Standardwerte fest und füllen fehlende Werte auf.
-- ============================================================

local ADDON_NAME, ns = ...

-- Standardwerte. Neue Einstellungen einfach hier ergänzen.
ns.defaults = {
    settings = {
        -- Modul an/aus
        levelUp       = true,
        -- Unteroptionen Level-Up
        trainerHint   = true,
        talentHint    = true,
        loginReminder = true,
        onScreen      = false,
        -- Modul: Talent-Leitfaden
        talentGuide   = true,
        talentBuild   = "SHAMAN_RESTORATION_LEVELING_HYBRID", -- gewählter Build (pro Klasse passend)
    },
    talentDump = {},   -- Ergebnis von /ww talentdump, pro Klasse
}

-- Kopiert fehlende Werte aus "source" nach "target" (auch verschachtelt).
-- Vorhandene Werte des Spielers bleiben unangetastet.
local function fillDefaults(target, source)
    for key, value in pairs(source) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            fillDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

-- Wird ausgelöst, sobald WoW die SavedVariables unseres Addons geladen hat.
-- Erst DANACH dürfen wir auf WegweiserDB zugreifen.
ns:RegisterEvent("ADDON_LOADED", function(_, loadedName)
    if loadedName ~= ADDON_NAME then return end

    WegweiserDB = WegweiserDB or {}
    fillDefaults(WegweiserDB, ns.defaults)
    ns.db = WegweiserDB

    -- Andere Teile des Addons (Einstellungsfenster, Module) starten.
    if ns.OnDatabaseReady then
        ns:OnDatabaseReady()
    end
    for _, module in pairs(ns.modules) do
        if module.OnInitialize then
            securecallfunction(module.OnInitialize, module)
        end
    end
end)

ns:RegisterEvent("PLAYER_LOGIN", function()
    ns:Print(ns.L.ADDON_LOADED, ns.version)
end)
