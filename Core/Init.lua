-- ============================================================
-- Core/Init.lua
-- Erste Datei des Addons. Legt den gemeinsamen "Namensraum" an.
--
-- Jede Lua-Datei eines Addons bekommt von WoW zwei Werte mit:
--   1. den Addon-Namen ("Wegweiser")
--   2. eine Tabelle, die ALLE Dateien dieses Addons gemeinsam nutzen.
-- In dieser Tabelle ("ns" = namespace) legen wir alles ab, was die
-- Dateien untereinander teilen. So verschmutzen wir keine globalen
-- Variablen, die andere Addons stören könnten.
-- ============================================================

local ADDON_NAME, ns = ...

ns.name    = ADDON_NAME
ns.version = C_AddOns and C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "?"

-- Hier tragen sich die Module ein (LevelUp, TalentDump, ...).
ns.modules = {}

-- Übersetzungstabelle. Wird in Locales/enUS.lua befüllt und von
-- Locales/deDE.lua überschrieben, wenn der Client auf Deutsch läuft.
-- Fehlt ein Text, zeigen wir den Schlüssel selbst an (statt eines Fehlers),
-- damit man fehlende Übersetzungen sofort im Spiel sieht.
ns.L = setmetatable({}, {
    __index = function(_, key)
        return key
    end,
})

-- Farbiger Präfix für alle Chat-Ausgaben: "Wegweiser:" in Gold.
local PREFIX = "|cffffd100Wegweiser:|r "

-- Gibt eine Nachricht im Chatfenster aus.
-- Beispiel: ns:Print("Hallo %s", "Welt")
function ns:Print(text, ...)
    if select("#", ...) > 0 then
        text = string.format(text, ...)
    end
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. tostring(text))
end

-- Zeigt eine Nachricht zusätzlich groß in der Bildschirmmitte
-- (dort, wo auch "Nicht genug Mana" steht), falls in den Einstellungen aktiv.
function ns:Notify(text, ...)
    if select("#", ...) > 0 then
        text = string.format(text, ...)
    end
    self:Print(text)
    if self.db and self.db.settings.onScreen and UIErrorsFrame then
        -- Gelbe Schrift (r, g, b)
        UIErrorsFrame:AddMessage(text, 1.0, 0.82, 0.0)
    end
end

-- Hilfsfunktion: ist der Client auf Deutsch?
ns.locale = GetLocale()
