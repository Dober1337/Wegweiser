-- ============================================================
-- Modules/GatherTooltip.lua
-- Maus über Kraut, Erzvorkommen oder Tier: Wegweiser zeigt im Tooltip,
-- ab welcher Fertigkeit man es sammeln / kürschnern kann und welche
-- Farbe es für die eigene Fertigkeit hat.
--
-- Daten: ns.GatherNodes (Kräuter/Erze, goldgoblin-Forever-Seiten) und
-- ns.SkinningRule (goldgoblin-Faustformel). Beide verified = false.
-- Eigene Fertigkeit: C_SkillInfo.GetSkillLineInfoByID (im Spiel bestätigt).
-- Tooltip-Haken: TooltipDataProcessor.AddTooltipPostCall mit
-- Enum.TooltipDataType.Object (Spielobjekte) und .Unit (Kreaturen),
-- geprüft im Forever-UI-Quellcode.
-- Tierart: C_CreatureInfo.GetCreatureTypeInfo(1 = Wildtier, 2 = Drachkin).
-- ============================================================

local _, ns = ...
local L = ns.L

local GT = {}
ns.modules.GatherTooltip = GT

local HERBALISM, MINING, SKINNING = 182, 186, 393

local function enabled()
    return ns.db and ns.db.settings.gatherTooltip
end

local function isSecret(v)
    return issecretvalue and issecretvalue(v)
end

local function skill(id)
    if not (C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID) then return nil end
    local ok, info = pcall(C_SkillInfo.GetSkillLineInfoByID, id)
    if ok and info and (info.maxRank or 0) > 0 then return info.rank or 0, info.name end
    return nil
end

local function profName(id)
    local _, name = skill(id)
    return name or L["PROF_NAME_" .. id]
end

-- Namensverzeichnis: "Silberblatt"/"Silverleaf" -> { prof, node }
-- Apostrophe vereinheitlichen (Quelle: ’, Spiel: ')
local function norm(s) return (s:gsub("’", "'")) end
local index
local function buildIndex()
    index = {}
    for prof, list in pairs(ns.GatherNodes or {}) do
        if type(prof) == "number" then
            for _, node in ipairs(list) do
                if node.de then index[norm(node.de)] = { prof = prof, node = node } end
                if node.en then index[norm(node.en)] = { prof = prof, node = node } end
            end
        end
    end
end

-- Farbe für eine Fertigkeit gegenüber den Schwellen
local COLOR = {
    RED    = "|cffff2020",
    ORANGE = "|cffff8040",
    YELLOW = "|cffffff00",
    GREEN  = "|cff40c040",
    GREY   = "|cff808080",
}
local function stage(rank, n)
    if rank < n.min then return "RED" end
    if not n.yellow then return nil end      -- Farben unbekannt
    if rank < n.yellow then return "ORANGE" end
    if rank < n.green then return "YELLOW" end
    if rank < n.grey then return "GREEN" end
    return "GREY"
end

local function addNodeLines(tooltip, prof, n)
    local head = n.yellow
        and string.format(L.GT_NODE_FULL, profName(prof), n.min,
            COLOR.YELLOW .. n.yellow .. "|r", COLOR.GREEN .. n.green .. "|r", COLOR.GREY .. n.grey .. "|r")
        or string.format(L.GT_NODE_MIN, profName(prof), n.min)
    tooltip:AddLine(head, 0.4, 0.8, 1.0)

    local rank = skill(prof)
    if not rank then
        tooltip:AddLine(string.format(L.GT_NOT_LEARNED, profName(prof)), 0.6, 0.6, 0.6)
        return
    end
    local st = stage(rank, n)
    if st then
        tooltip:AddLine(string.format(L.GT_YOU, rank, COLOR[st] .. L["GT_STAGE_" .. st] .. "|r"), 0.9, 0.9, 0.9)
    else
        tooltip:AddLine(string.format(L.GT_YOU_OK, rank), 0.9, 0.9, 0.9)
    end
end

-- Benötigter Kürschnerei-Skill für eine Gegnerstufe (Faustformel, siehe Data)
function GT:SkinningNeeded(level)
    if level <= 10 then return 1 end
    if level <= 20 then return (level - 10) * 10 end
    return level * 5
end

local skinTypes
local function isSkinnableType(unit)
    if not skinTypes then
        skinTypes = {}
        if C_CreatureInfo and C_CreatureInfo.GetCreatureTypeInfo then
            for _, id in ipairs({ 1, 2 }) do   -- 1 Wildtier, 2 Drachkin
                local info = C_CreatureInfo.GetCreatureTypeInfo(id)
                if info and info.name then skinTypes[info.name] = true end
            end
        end
    end
    local t = UnitCreatureType(unit)
    return t and not isSecret(t) and skinTypes[t]
end

local function onObject(tooltip, data)
    if not enabled() or not data or not data.lines or not data.lines[1] then return end
    local name = data.lines[1].leftText
    if not name or isSecret(name) then return end
    if not index then buildIndex() end
    local hit = index[norm(name)]
    if hit then addNodeLines(tooltip, hit.prof, hit.node) end
end

local function onUnit(tooltip)
    if not enabled() then return end
    local unit = select(2, tooltip:GetUnit())
    if not unit or isSecret(unit) or UnitIsPlayer(unit) then return end
    local rank = skill(SKINNING)
    if not rank then return end                 -- nur für Kürschner
    if not isSkinnableType(unit) then return end
    local level = UnitLevel(unit)
    if not level or isSecret(level) or level < 1 then return end
    local need = GT:SkinningNeeded(level)
    local color = rank >= need and COLOR.GREEN or COLOR.RED
    tooltip:AddLine(string.format(L.GT_SKIN, profName(SKINNING), color .. need .. "|r", rank), 0.4, 0.8, 1.0)
end

function GT:OnInitialize()
    if not (TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType) then
        return
    end
    if Enum.TooltipDataType.Object then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Object, onObject)
    end
    if Enum.TooltipDataType.Unit then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, onUnit)
    end
end
