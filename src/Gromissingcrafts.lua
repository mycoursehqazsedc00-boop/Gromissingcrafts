setfenv(1, Gromissingcrafts)

---@shape AddonInfo
---@field name string
---@field version string

---@type AddonInfo
local addonInfo = {
    name = ADDON_NAME,
    version = ADDON_VERSION
}

---@type LibStubDef
local LibStub = getglobal("LibStub")
assert(LibStub ~= nil, "LibStub is required to run this addon")

local LibCraftingProfessions = --[[---@type LibCraftingProfessions]] LibStub("LibCraftingProfessions-1.0")
local LibCrafts = --[[---@type LibCrafts]] LibStub("LibCrafts-1.0")
local LibItemTooltip = --[[---@type LibItemTooltip]] LibStub("LibItemTooltip-1.0")

---@shape Repositories
---@field characterRepository CharacterRepository
---@field craftRepository CraftRepository

---@class Gromissingcrafts
---@field database Database
---@field uiManager UIManager

---@type Gromissingcrafts
local addon = --[[---@type Gromissingcrafts]] {}

local SPEC_SPELLS_BY_ID = {
    [9787] = "Weaponsmith",
    [9788] = "Armorsmith",
    [17039] = "Master Swordsmith",
    [17040] = "Master Hammersmith",
    [17041] = "Master Axesmith",
    [20219] = "Gnomish Engineer",
    [20222] = "Goblin Engineer",
    [10656] = "Dragonscale Leatherworking",
    [10658] = "Elemental Leatherworking",
    [10660] = "Tribal Leatherworking",
    [57551] = "Gemology",
    [57553] = "Goldsmith",
}

local SPEC_NAME_TO_CANONICAL = {
    ["Weaponsmith"] = "Weaponsmith",
    ["Armorsmith"] = "Armorsmith",
    ["Master Swordsmith"] = "Master Swordsmith",
    ["Master Hammersmith"] = "Master Hammersmith",
    ["Master Axesmith"] = "Master Axesmith",
    ["Gnomish Engineer"] = "Gnomish Engineer",
    ["Gnomish Engineering"] = "Gnomish Engineer",
    ["Goblin Engineer"] = "Goblin Engineer",
    ["Goblin Engineering"] = "Goblin Engineer",
    ["Dragonscale Leatherworking"] = "Dragonscale Leatherworking",
    ["Elemental Leatherworking"] = "Elemental Leatherworking",
    ["Tribal Leatherworking"] = "Tribal Leatherworking",
    ["Gemology"] = "Gemology",
    ["Goldsmith"] = "Goldsmith",
    ["Goldsmithing"] = "Goldsmith",
    -- zhCN localized names
    ["武器锻造师"] = "Weaponsmith",
    ["护甲锻造师"] = "Armorsmith",
    ["铸剑大师"] = "Master Swordsmith",
    ["铸锤大师"] = "Master Hammersmith",
    ["铸斧大师"] = "Master Axesmith",
    ["侏儒工程学"] = "Gnomish Engineer",
    ["侏儒工程师"] = "Gnomish Engineer",
    ["地精工程学"] = "Goblin Engineer",
    ["地精工程师"] = "Goblin Engineer",
    ["龙鳞制皮"] = "Dragonscale Leatherworking",
    ["元素制皮"] = "Elemental Leatherworking",
    ["部族制皮"] = "Tribal Leatherworking",
    ["宝石学"] = "Gemology",
    ["金匠学"] = "Goldsmith",
}

local specLookupBuilt = false

local function ensureLocalizedSpecLookup()
    if specLookupBuilt then return end
    specLookupBuilt = true
    local getSpellInfoFn = getglobal("GetSpellInfo")
    local spellInfoFn = getglobal("SpellInfo")
    for spellId, canonical in pairs(SPEC_SPELLS_BY_ID) do
        if type(getSpellInfoFn) == "function" then
            local ok, localized = pcall(getSpellInfoFn, spellId)
            if ok and type(localized) == "string" and localized ~= "" then
                SPEC_NAME_TO_CANONICAL[localized] = canonical
            end
        elseif type(spellInfoFn) == "function" then
            local ok, localized = pcall(spellInfoFn, spellId)
            if ok and type(localized) == "string" and localized ~= "" then
                SPEC_NAME_TO_CANONICAL[localized] = canonical
            end
        end
    end
end

---@return string[]
local function detectPlayerSpecializations()
    ensureLocalizedSpecLookup()
    local foundSet = {}
    local foundList = {}

    local function record(name)
        if type(name) ~= "string" or name == "" then return end
        local canonical = SPEC_NAME_TO_CANONICAL[name]
        if canonical and not foundSet[canonical] then
            foundSet[canonical] = true
            tinsert(foundList, canonical)
        end
    end

    -- 1. Scan player spellbook (where Vanilla/Turtle specialization passives live)
    local i = 1
    while true do
        local spellName = GetSpellName(i, BOOKTYPE_SPELL)
        if not spellName then break end
        record(spellName)
        i = i + 1
    end

    -- 2. Scan skill lines as fallback
    local numSkills = GetNumSkillLines()
    if numSkills and numSkills > 0 then
        for s = 1, numSkills do
            local skillName, isHeader = GetSkillLineInfo(s)
            if not isHeader and skillName then
                record(skillName)
            end
        end
    end

    return foundList
end

function addon:RefreshPlayerSpecializations()
    if self.database == nil then return end
    self.database:SaveCurrentPlayerSpecializations(detectPlayerSpecializations())
end

function addon:OnEnable()
    self.database = Database:Create()
    self:RefreshPlayerSpecializations()

    local characterRepository = CharacterRepository:Create(self.database)
    ---@type Repositories
    local repositories = {
        characterRepository = characterRepository,
        craftRepository = CraftRepository:Create(self.database, characterRepository, LibCrafts)
    }

    -- L is the shared locale table populated by src/locale/*.lua, loaded earlier in the .toc
    self.uiManager = UIManager:Create(addonInfo, repositories, --[[---@type GromissingcraftsLocale]] L, LibItemTooltip)

    LibCraftingProfessions:RegisterEvent("LCP_SKILLS_UPDATE", function(profession, skills)
        local skillNames = {}
        for _, skill in ipairs(skills) do
            tinsert(skillNames, skill.localized_name)
        end
        self.database:SaveCurrentPlayerSkills(profession.localized_name, profession.cur_rank, skillNames)
        self:RefreshPlayerSpecializations()

        local playerProfessions = LibCraftingProfessions:GetPlayerProfessions()
        if playerProfessions ~= nil then
            local playerProfessionNames = {}
            for _, playerProfession in ipairs(playerProfessions or {}) do
                tinsert(playerProfessionNames, playerProfession.localized_name)
            end
            self.database:SaveCurrentPlayerProfessions(playerProfessionNames)
        end

        self.uiManager:OnDataUpdated(profession.localized_name)
    end)

    LibCraftingProfessions:RegisterEvent("LCP_FRAME_SHOW", function(profession, frame, frameType)
        self:RefreshPlayerSpecializations()
        self.uiManager:OnProfessionFrameOpened(profession.localized_name, frame, frameType)
    end)

    LibCraftingProfessions:RegisterEvent("LCP_FRAME_CLOSE", function(frame, frameType)
        self.uiManager:OnProfessionFrameClosed(frame, frameType)
    end)

    DevTools:Create()
end

Addon = addon

local bootstrapFrame = CreateFrame("Frame")
bootstrapFrame:RegisterEvent("ADDON_LOADED")
bootstrapFrame:RegisterEvent("PLAYER_LOGIN")
bootstrapFrame:RegisterEvent("SPELLS_CHANGED")
bootstrapFrame:RegisterEvent("SKILL_LINES_CHANGED")
bootstrapFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        bootstrapFrame:UnregisterEvent("ADDON_LOADED")
        addon:OnEnable()
    elseif event == "PLAYER_LOGIN" or event == "SPELLS_CHANGED" or event == "SKILL_LINES_CHANGED" then
        addon:RefreshPlayerSpecializations()
    end
end)
