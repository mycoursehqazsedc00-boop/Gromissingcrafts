setfenv(1, Gromissingcrafts)

---@shape CharacterProfession
---@field localizedName string
---@field rank number
---@field knownLocalizedSkillNamesSet table<string, boolean>

---@class Character
---@field name string
---@field professionLocalizedNameToProfession table<string, CharacterProfession>
Character = {}

---@param dbCharacter DatabaseCharacter
---@return self
function Character:Create(dbCharacter)
    ---@type table<string, CharacterProfession>
    local nameToProfession = {}

    for professionName, profession in pairs(dbCharacter.professionsByLocalizedName) do
        ---@type table<string, boolean>
        local skillSet = {}
        for _, skillName in ipairs(profession.knownLocalizedSkillNames) do
            skillSet[skillName] = true
        end

        nameToProfession[professionName] = {
            localizedName = professionName,
            rank = profession.rank,
            knownLocalizedSkillNamesSet = skillSet,
        }
    end

    local specializationsSet = {}
    for _, specName in ipairs(dbCharacter.specializations or {}) do
        specializationsSet[specName] = true
    end

    local object = --[[---@type self]] {}
    setmetatable(object, {__index = Character})
    object.name = dbCharacter.name
    object.professionLocalizedNameToProfession = nameToProfession
    object.specializationsSet = specializationsSet
    return object
end

local SPEC_GROUPS = {
    ["Gnomish Engineer"] = "Engineering",
    ["Goblin Engineer"] = "Engineering",
    ["Dragonscale Leatherworking"] = "Leatherworking",
    ["Elemental Leatherworking"] = "Leatherworking",
    ["Tribal Leatherworking"] = "Leatherworking",
    ["Gemology"] = "Jewelcrafting",
    ["Goldsmith"] = "Jewelcrafting",
    ["Armorsmith"] = "Blacksmithing",
    ["Weaponsmith"] = "Blacksmithing",
    ["Master Axesmith"] = "Blacksmithing",
    ["Master Hammersmith"] = "Blacksmithing",
    ["Master Swordsmith"] = "Blacksmithing",
}

local GROUP_MEMBERS = {
    Engineering = {"Gnomish Engineer", "Goblin Engineer"},
    Leatherworking = {"Dragonscale Leatherworking", "Elemental Leatherworking", "Tribal Leatherworking"},
    Jewelcrafting = {"Gemology", "Goldsmith"},
}

---@param craft Craft
---@return boolean
function Character:CanUseSpecialization(craft)
    local req = craft.specialization
    if req == nil then
        return true
    end

    local specs = self.specializationsSet
    if specs == nil then
        return true
    end

    local group = SPEC_GROUPS[req]
    if group == nil then
        return true
    end

    if group == "Blacksmithing" then
        local hasArmor = specs["Armorsmith"] == true
        local hasWeapon = specs["Weaponsmith"] == true
        local hasAxe = specs["Master Axesmith"] == true
        local hasHammer = specs["Master Hammersmith"] == true
        local hasSword = specs["Master Swordsmith"] == true
        local hasSubWeapon = hasAxe or hasHammer or hasSword

        if hasArmor then
            return req == "Armorsmith"
        end
        if hasWeapon or hasSubWeapon then
            if req == "Armorsmith" then
                return false
            end
            if req == "Weaponsmith" then
                return true
            end
            if hasSubWeapon then
                return specs[req] == true
            end
            -- Weaponsmith without a Master sub-spec yet: show all 3 Master branches
            return true
        end
        -- No Blacksmithing specialization yet: show all branches
        return true
    end

    local members = GROUP_MEMBERS[group]
    if members == nil then
        return true
    end

    local hasAnyInGroup = false
    for _, member in ipairs(members) do
        if specs[member] == true then
            hasAnyInGroup = true
            break
        end
    end

    if not hasAnyInGroup then
        -- No specialization chosen yet for this profession: show all branches
        return true
    end

    return specs[req] == true
end

---@param localizedName string
---@return number
function Character:GetProfessionRank(localizedName)
    local profession = self.professionLocalizedNameToProfession[localizedName]
    if profession == nil then
        return 0
    end
    return profession.rank
end

---@param craft Craft
---@return boolean
function Character:Knows(craft)
    local profession = self.professionLocalizedNameToProfession[craft.localizedProfessionName]
    if profession == nil then
        return false
    end
    return profession.knownLocalizedSkillNamesSet[craft.localizedName] == true
end

---@param craft Craft
---@return boolean
function Character:CanLearnNow(craft)
    local profession = self.professionLocalizedNameToProfession[craft.localizedProfessionName]
    if profession == nil then
        return false
    end
    if not self:CanUseSpecialization(craft) then
        return false
    end
    return not self:Knows(craft) and profession.rank >= craft.skillLevel
end
