-- ============================================================
-- Modules/ProfessionRoutes.lua
-- "Womit skille ich jetzt am besten?" – beim Lehrer und im Berufsfenster.
--
-- Zeigt einen Wegweiser-Kasten neben
--   * dem Lehrerfenster (ClassTrainerFrame), wenn ein BERUFSlehrer offen ist
--     (C_Trainer.GetTrainerType() == Tradeskills; welcher Beruf: über
--      GetTrainerServiceSkillLine – geprüft im Forever-UI-Quellcode)
--   * dem Berufsfenster (ProfessionsFrame, Ereignis TRADE_SKILL_SHOW)
-- Inhalt: Skill/Limit, nächster Rang (lernbar?), bester Schritt für den
-- aktuellen Skill mit Material, der Schritt danach, bei Sammelberufen die
-- Vorkommen, die gerade Punkte geben – und der Link zum ausführlichen Guide.
-- Daten: Data/ProfessionRoutes.lua, Data/Professions.lua (verified = false).
-- Nur außerhalb des Kampfes; der Kasten hängt am Blizzard-Fenster und
-- verschwindet mit ihm.
-- ============================================================

local _, ns = ...
local L = ns.L

local PR = {}
ns.modules.ProfessionRoutes = PR

local function settings()
    return ns.db and ns.db.settings or ns.defaults.settings
end

-- ------------------------------------------------------------
-- Namen aus IDs (richtige Sprache), mit deutschem Ersatz
-- ------------------------------------------------------------

local pendingRefresh   -- Funktion, die nach dem Nachladen von Gegenstandsdaten neu zeichnet
local refreshCount = 0 -- Schutz: höchstens ein paar Nachlade-Runden pro geöffnetem Fenster

local function itemName(id, fallback)
    local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)
    if not name and C_Item and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(id)   -- Name kommt kurz danach (ITEM_DATA_LOAD_RESULT)
    end
    return name or fallback or ("#" .. id)
end

local function stepName(step)
    if step.kind == "spell" then
        return (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(step.id)) or step.de
    end
    return itemName(step.id, step.de)
end

local function matsLine(step)
    if step.mats and #step.mats > 0 then
        local parts = {}
        for _, m in ipairs(step.mats) do
            local name = (m[2] == "spell") and ((C_Spell.GetSpellName and C_Spell.GetSpellName(m[3])) or m[4])
                or itemName(m[3], m[4])
            table.insert(parts, m[1] .. "× " .. name)
        end
        return table.concat(parts, ", ")
    end
    if step.matsText and ns.locale == "deDE" then return step.matsText end
    return nil
end

-- ------------------------------------------------------------
-- Bekannte Rezepte (pro Charakter gemerkt, beim Öffnen des Berufsfensters)
-- ------------------------------------------------------------

local function charKey()
    local guid = UnitGUID("player")
    if not guid or (issecretvalue and issecretvalue(guid)) then return nil end
    return guid
end

local function knownStore(profID, create)
    local key = charKey()
    if not key or not ns.db then return nil end
    ns.db.knownRecipes = ns.db.knownRecipes or {}
    local char = ns.db.knownRecipes[key]
    if not char and create then char = {}; ns.db.knownRecipes[key] = char end
    if not char then return nil end
    if create then char[profID] = { spells = {}, items = {}, names = {} } end
    return char[profID]
end

-- Liest die gelernten Rezepte des offenen Berufsfensters ein.
function PR:ScanKnownRecipes(profID)
    if not C_TradeSkillUI or not C_TradeSkillUI.GetRecipeInfo then return end
    local ids, partial
    if C_TradeSkillUI.GetAllRecipeIDs then
        ids = C_TradeSkillUI.GetAllRecipeIDs()
    elseif C_TradeSkillUI.GetFilteredRecipeIDs then
        ids = C_TradeSkillUI.GetFilteredRecipeIDs()
        partial = true   -- Filter im Berufsfenster könnten Rezepte ausblenden
    end
    if not ids or #ids == 0 then return end
    local store = knownStore(profID, true)
    if not store then return end
    store.partial = partial
    for _, recipeID in ipairs(ids) do
        local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
        if info and info.learned then
            store.spells[recipeID] = true
            if info.name then store.names[info.name:lower()] = true end
            local ok, schem = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeID, false)
            if ok and schem and schem.outputItemID then store.items[schem.outputItemID] = true end
        end
    end
end

-- true = bekannt, false = sicher nicht bekannt, nil = weiß ich nicht
function PR:IsKnown(profID, step)
    if step.src == "START" then return true end
    local store = knownStore(profID, false)
    if not store then return nil end
    if (step.kind == "spell" and store.spells[step.id]) or (step.kind == "item" and store.items[step.id]) then
        return true
    end
    local name = stepName(step)
    if name and store.names[name:lower()] then return true end
    if store.partial then return nil end
    return false
end

-- Bietet der offene Lehrer das Rezept an? "available" | "unavailable" | "used" | nil
local function trainerOffer(step)
    if not (ClassTrainerFrame and ClassTrainerFrame:IsShown() and GetNumTrainerServices) then return nil end
    local name = stepName(step)
    for i = 1, GetNumTrainerServices() do
        local serviceName, serviceType = GetTrainerServiceInfo(i)
        if serviceName and serviceName == name then return serviceType end
    end
    return nil
end

-- Status-Zeile zum Rezept des besten Schritts: Text, r, g, b – oder nil
function PR:RecipeStatus(profID, step)
    local offer = trainerOffer(step)
    local known = self:IsKnown(profID, step)
    if known or offer == "used" then
        return L.PRO_RECIPE_KNOWN, 0.3, 1, 0.3
    elseif offer == "available" then
        return L.PRO_RECIPE_HERE, 0.3, 1, 0.3
    elseif offer == "unavailable" then
        return L.PRO_RECIPE_HERE_LATER, 1, 0.82, 0
    end
    local where = step.src and L["PRO_SRC_" .. step.src]
    if where and step.srcSkill then where = where .. string.format(L.PRO_SRC_SKILL, step.srcSkill) end
    local who = step.srcWho and step.srcWho[(UnitFactionGroup("player") or ""):upper()]
    if where and who then where = where .. ": " .. who end
    if known == false then
        return L.PRO_RECIPE_MISSING .. (where and (" – " .. where) or ""), 1, 0.82, 0
    elseif where then
        return L.PRO_RECIPE_FROM .. where, 0.8, 0.8, 0.8
    end
    return nil
end

-- ------------------------------------------------------------
-- Bester Schritt für einen Skill
-- ------------------------------------------------------------

-- Erster Hauptschritt, dessen Bereich den Skill enthält, und der nächste danach
function PR:GetSteps(id, skill)
    local route = ns.ProfessionRoutes[id]
    if not route then return nil end
    local current, nextStep
    for _, s in ipairs(route) do
        if not s.alt then
            if not current and skill >= s.from and skill < s.to then
                current = s
            elseif current and not nextStep and s.from >= current.to then
                nextStep = s
            end
        end
    end
    if not current then
        -- noch unter dem ersten Schritt oder Lücke: nächsten passenden Schritt nehmen
        for _, s in ipairs(route) do
            if not s.alt and s.from > skill then nextStep = s break end
        end
    end
    return current, nextStep
end

-- Textzeilen für den Kasten bzw. den Chat
function PR:BuildLines(p)
    local lines = {}
    local PH = ns.modules.ProfessionHelper
    table.insert(lines, { L.PRO_TITLE:format(p.name, p.rank, p.maxRank), 1, 0.82, 0 })

    local idx, r = PH:NextRank(p)
    if idx then
        local ready = p.rank >= r.skill and (not r.level or UnitLevel("player") >= r.level)
        table.insert(lines, { PH:RankText(idx, r) .. (ready and L.PRO_READY or ""),
            ready and 0.3 or 0.8, ready and 1 or 0.8, ready and 0.3 or 0.8 })
        if r.note then table.insert(lines, { L[r.note], 1, 0.82, 0 }) end
    end

    local current, nextStep = self:GetSteps(p.id, p.rank)
    if current then
        table.insert(lines, { L.PRO_BEST:format(current.from, current.to, current.n or "?", stepName(current)), 1, 1, 1 })
        local status, sr, sg, sb = self:RecipeStatus(p.id, current)
        if status then table.insert(lines, { status, sr, sg, sb }) end
        local mats = matsLine(current)
        if mats then table.insert(lines, { L.PRO_MATS:format(mats), 0.8, 0.8, 0.8 }) end
    end
    if nextStep then
        table.insert(lines, { L.PRO_NEXT:format(nextStep.from, stepName(nextStep)), 0.75, 0.85, 1 })
    end

    -- Sammelberufe: Vorkommen
    local orange, yellow, green, nextNode = PH:GatherAdvice(p)
    if orange and #orange > 0 then table.insert(lines, { L.PROF_GATHER_ORANGE:format(table.concat(orange, ", ")), 1, 1, 1 }) end
    if yellow and #yellow > 0 then table.insert(lines, { L.PROF_GATHER_YELLOW:format(table.concat(yellow, ", ")), 1, 1, 1 }) end
    if nextNode and (not orange or #orange == 0) then
        table.insert(lines, { L.PROF_GATHER_NEXT:format(nextNode.name, nextNode.min), 0.75, 0.85, 1 })
    end

    if not current and not nextStep and not orange then
        table.insert(lines, { L.PRO_NO_ROUTE, 0.8, 0.8, 0.8 })
    end
    if ns.ProfessionGuideLinks[p.id] then
        table.insert(lines, { L.PRO_GUIDE_CMD:format(p.name:lower()), 0.6, 0.6, 0.6 })
    end
    return lines
end

-- ------------------------------------------------------------
-- Der Kasten
-- ------------------------------------------------------------

local boxes = {}   -- je Blizzard-Fenster ein Kasten

-- xOffset: Abstand nach rechts (im Berufsfenster Platz für Blizzards Berufs-Reiter lassen)
local function getBox(host, xOffset)
    if boxes[host] then return boxes[host] end
    local box = CreateFrame("Frame", nil, host, "BackdropTemplate")
    box:SetPoint("TOPLEFT", host, "TOPRIGHT", xOffset or 4, -24)
    box:SetWidth(300)
    box:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    box:SetBackdropColor(0, 0, 0, 0.88)
    box:EnableMouse(false)
    box.lines = {}
    boxes[host] = box
    return box
end

local function fill(box, lines)
    local y = -10
    for i, line in ipairs(lines) do
        local fs = box.lines[i]
        if not fs then
            fs = box:CreateFontString(nil, "ARTWORK", i == 1 and "GameFontNormal" or "GameFontHighlightSmall")
            fs:SetJustifyH("LEFT")
            fs:SetWordWrap(true)
            box.lines[i] = fs
        end
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", box, "TOPLEFT", 10, y)
        fs:SetPoint("RIGHT", box, "RIGHT", -10, 0)
        fs:SetText(line[1])
        fs:SetTextColor(line[2], line[3], line[4])
        fs:Show()
        y = y - (fs:GetStringHeight() or 12) - 4
    end
    for i = #lines + 1, #box.lines do box.lines[i]:Hide() end
    box:SetHeight(-y + 6)
    box:Show()
end

-- Beruf (aus GetMyProfessions) per ID
local function myProfession(id)
    for _, p in ipairs(ns.modules.ProfessionHelper:GetMyProfessions()) do
        if p.id == id then return p end
    end
    return nil
end

-- Beruf per (lokalisiertem) Namen
local function myProfessionByName(name)
    if not name then return nil end
    for _, p in ipairs(ns.modules.ProfessionHelper:GetMyProfessions()) do
        if p.name == name then return p end
    end
    return nil
end

-- ------------------------------------------------------------
-- Beim Lehrer
-- ------------------------------------------------------------

function PR:ShowAtTrainer()
    if not ClassTrainerFrame then return end
    if boxes[ClassTrainerFrame] then boxes[ClassTrainerFrame]:Hide() end
    if not settings().profHelper or not settings().profRouteBox then return end
    if not (C_Trainer and C_Trainer.GetTrainerType and Enum.TrainerType)
        or C_Trainer.GetTrainerType() ~= Enum.TrainerType.Tradeskills then return end

    -- Welcher Beruf? Über die Fertigkeitslinie der angebotenen Dienste
    local p, lineName
    local num = GetNumTrainerServices and GetNumTrainerServices() or 0
    for i = 1, num do
        lineName = lineName or (GetTrainerServiceSkillLine and GetTrainerServiceSkillLine(i))
        p = myProfessionByName(GetTrainerServiceSkillLine and GetTrainerServiceSkillLine(i))
        if p then break end
    end
    -- Lehrer-Ort merken (auch für noch nicht gelernte Berufe, über den Namen)
    local profID = p and p.id
    if not profID and lineName then
        for id in pairs(ns.Professions) do
            if L["PROF_NAME_" .. id] == lineName then profID = id break end
        end
    end
    if profID then ns.modules.ProfessionHelper:RememberTrainer(profID) end
    if not p then return end   -- Beruf (noch) nicht gelernt: Blizzard zeigt das Angebot selbst
    pendingRefresh = function() PR:ShowAtTrainer() end
    fill(getBox(ClassTrainerFrame), self:BuildLines(p))
end

-- ------------------------------------------------------------
-- Im Berufsfenster
-- ------------------------------------------------------------

function PR:ShowAtProfession()
    local host = ProfessionsFrame
    if not host then return end
    if boxes[host] then boxes[host]:Hide() end
    if not settings().profHelper or not settings().profRouteBox then return end
    local info = C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo and C_TradeSkillUI.GetBaseProfessionInfo()
    if not info then return end
    local p = myProfession(info.professionID) or myProfession(info.parentProfessionID)
        or myProfessionByName(info.professionName)
    if not p then return end
    self:ScanKnownRecipes(p.id)   -- bekannte Rezepte merken (für Lehrer und Chat)
    pendingRefresh = function() PR:ShowAtProfession() end
    fill(getBox(host, 52), self:BuildLines(p))
end

-- Chat-Variante für /ww berufe
function PR:BestLine(p)
    local current = self:GetSteps(p.id, p.rank)
    if not current then return nil end
    local text = L.PRO_BEST:format(current.from, current.to, current.n or "?", stepName(current))
    local mats = matsLine(current)
    local status = self:RecipeStatus(p.id, current)
    return text, mats, status
end

function PR:OnInitialize()
    local function later(f)
        C_Timer.After(0.2, function() ns:RunOutOfCombat(f, true) end)
    end
    ns:RegisterEvent("TRAINER_SHOW",   function() refreshCount = 0; later(function() PR:ShowAtTrainer() end) end)
    ns:RegisterEvent("TRAINER_UPDATE", function() later(function() PR:ShowAtTrainer() end) end)
    ns:RegisterEvent("TRADE_SKILL_SHOW", function() refreshCount = 0; later(function() PR:ShowAtProfession() end) end)
    -- Neues Rezept gelernt oder Berufsfenster-Daten aktualisiert
    ns:RegisterEvent("TRADE_SKILL_LIST_UPDATE", function()
        if ProfessionsFrame and ProfessionsFrame:IsShown() then later(function() PR:ShowAtProfession() end) end
    end)
    ns:RegisterEvent("SKILL_LINES_CHANGED", function()
        if ProfessionsFrame and ProfessionsFrame:IsShown() then later(function() PR:ShowAtProfession() end) end
    end)
    -- Gegenstandsnamen nachgeladen -> Kasten einmal neu zeichnen
    local refreshQueued = false
    ns:RegisterEvent("ITEM_DATA_LOAD_RESULT", function()
        if refreshQueued or not pendingRefresh or refreshCount >= 3 then return end
        refreshQueued = true
        refreshCount = refreshCount + 1
        C_Timer.After(0.3, function()
            refreshQueued = false
            if pendingRefresh then ns:RunOutOfCombat(pendingRefresh, true) end
        end)
    end)
end
