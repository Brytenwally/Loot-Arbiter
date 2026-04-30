local LOG_PREFIX = "[SpecArbiter] "
local COLOR_PREFIX = "|cff00ff00[SpecArbiter]|r "

-- [1] DATA MAPS
local STAT_ID_MAP = { [4]="STR", [3]="AGI", [7]="STA", [5]="INT", [6]="SPI", [38]="AP", [45]="SP", [31]="HIT", [32]="CRIT", [36]="HASTE", [37]="EXP", [12]="DEF", [13]="DODGE", [14]="PARRY", [15]="BLOCK" }

local INV_TO_SLOT = {
    [1]  = 0,  -- Head
    [2]  = 1,  -- Neck
    [3]  = 2,  -- Shoulders
    [5]  = 4,  -- Chest
    [6]  = 5,  -- Waist
    [7]  = 6,  -- Legs
    [8]  = 7,  -- Feet
    [9]  = 8,  -- Wrists
    [10] = 9,  -- Hands
    [11] = 10, -- Finger 1
    [12] = 12, -- Trinket 1
    [13] = 15, -- One-Hand (Slot 15)
    [14] = 16, -- Shield/Off-hand (Slot 16)
    [15] = 18, -- Ranged
    [16] = 14, -- Back
    [17] = 15, -- Two-Hand (Slot 15)
    [20] = 4,  -- Robe
}

-- [2] WEIGHT TABLES
local MASTER_WEIGHTS = {
    ["Warlock"]     = {STA=0.2, INT=0.2, SPI=0.15, SP=1, HIT=1.1, CRIT=0.7, HASTE=0.9, WPW=0},
    ["Shamy Ele"]   = {STA=0.2, INT=0.25, SPI=0.1, SP=1, HIT=1.1, CRIT=0.7, HASTE=0.8, WPW=0},
    ["Shamy Enh"]   = {STR=0.9, AGI=1, STA=0.3, AP=0.45, HIT=1.3, CRIT=0.8, HASTE=0.6, EXP=1.1, WPW=0.4},
    ["Shamy Resto"] = {STA=0.2, INT=0.3, SPI=0.7, SP=1, CRIT=0.6, HASTE=0.7, WPW=0},
    ["Rogue"]       = {STR=0.3, AGI=1, STA=0.3, AP=0.45, HIT=1.4, CRIT=0.9, HASTE=0.7, EXP=1.1, ARPEN=1.0, WPW=0.4},
    ["Prst Shad"]   = {STA=0.2, INT=0.2, SPI=0.5, SP=1, HIT=1.1, CRIT=0.7, HASTE=0.8, WPW=0},
    ["Prst Holy"]   = {STA=0.2, INT=0.3, SPI=0.8, SP=1, CRIT=0.5, HASTE=0.7, WPW=0},
    ["Prst Disc"]   = {STA=0.2, INT=0.4, SPI=0.6, SP=1, CRIT=0.8, HASTE=0.6, WPW=0},
    ["Mage Arcane"] = {STA=0.1, INT=0.35, SPI=0.15, SP=1, HIT=1.1, CRIT=0.6, HASTE=0.9, WPW=0},
    ["Mage Fire"]   = {STA=0.1, INT=0.2, SPI=0.15, SP=1, HIT=1.1, CRIT=0.9, HASTE=0.7, WPW=0},
    ["Mage Frost"]  = {STA=0.1, INT=0.2, SPI=0.15, SP=1, HIT=1.1, CRIT=0.5, HASTE=0.8, WPW=0},
    ["Hunter"]      = {STR=0.2, AGI=1, STA=0.3, INT=0.15, AP=0.45, HIT=1.2, CRIT=0.8, HASTE=0.7, ARPEN=0.9, WPW=0.5},
    ["Druid Cat"]   = {STR=1.35, AGI=1, STA=0.3, INT=0.1, SPI=0.05, AP=0.61, SP=0, HIT=0.59, CRIT=0.47, HASTE=0.41, EXP=0.59, WPW=0.2},
    ["Druid Bear"]  = {STR=0.41, AGI=0.47, STA=1, INT=0.1, SPI=0.05, AP=0.34, SP=0, HIT=0.16, CRIT=0.15, HASTE=0.31, DEF=0.26, DODGE=0.56, WPW=0.1},
    ["Druid Bal"]   = {STA=0.3, INT=0.38, SPI=0.34, SP=1, HIT=1.21, CRIT=0.62, HASTE=0.8, WPW=0},
    ["Druid Resto"] = {STA=0.3, INT=0.2, SPI=0.75, SP=1, CRIT=0.6, HASTE=0.8, WPW=0},
    ["Pally Ret"]   = {STR=1, AGI=0.46, STA=0.3, INT=0.24, SPI=0.05, AP=0.41, SP=0.2, HIT=0.84, CRIT=0.44, HASTE=0.35, EXP=0.52, WPW=0.3},
    ["Pally Prot"]  = {STR=0.74, AGI=0.8, STA=1, INT=0.5, SPI=0.05, AP=0.13, SP=0.4, HIT=0.78, CRIT=0.5, HASTE=0.42, EXP=0.27, DEF=0.7, DODGE=0.7, PARRY=0.6, BLOCK=0.6, WPW=0.1},
    ["Pally Holy"]  = {INT=0.2, SPI=0.5, SP=1, CRIT=0.6, HASTE=0.8, WPW=0},
    ["DK Blood"]    = {STR=1, AGI=0.48, STA=1, INT=0, SPI=0.05, AP=0.35, SP=0, HIT=0.87, CRIT=0.54, HASTE=0.52, EXP=0.86, DEF=0.05, DODGE=0.05, PARRY=0.12, BLOCK=0, WPW=0.3},
    ["DK Frost"]    = {STR=1, AGI=0.78, STA=0.3, INT=0, SPI=0.05, AP=0.37, SP=0, HIT=1.03, CRIT=0.46, HASTE=0.29, EXP=0.84, DEF=0.05, DODGE=0.05, PARRY=0.12, BLOCK=0, WPW=0.4},
    ["DK Unhol"]    = {STR=1, AGI=0.58, STA=0.3, INT=0, SPI=0.05, AP=0.66, SP=0, HIT=0.66, CRIT=0.45, HASTE=0.48, EXP=0.51, DEF=0.05, DODGE=0.05, PARRY=0.12, BLOCK=0, WPW=0.3},
    ["War Fury"]    = {STR=1, AGI=0.77, STA=0.3, AP=0.66, HIT=0.55, CRIT=0.93, HASTE=0.79, EXP=1.5, ARPEN=1.1, WPW=0.4},
    ["War Arms"]    = {STR=1, AGI=0.65, STA=0.3, AP=0.58, HIT=0.5, CRIT=0.8, HASTE=0.65, EXP=1.2, ARPEN=1.4, WPW=0.4},
    ["War Prot"]    = {STR=0.33, AGI=0.59, STA=1, AP=0.34, HIT=0.67, CRIT=0.28, HASTE=0.21, EXP=0.94, DEF=0.81, DODGE=0.7, PARRY=0.58, BLOCK=0.59, WPW=0.1},
}

-- [3] HEURISTIC SPEC IDENTIFIER
local function GetHeuristicSpec(player)
    local classId = player:GetClass()
    local mainHand = player:GetEquippedItemBySlot(15)
    local offHand = player:GetEquippedItemBySlot(16)
    local agi, int, str = player:GetStat(1), player:GetStat(3), player:GetStat(0)
    local activeSpec = player:GetActiveSpec() or 0

    if classId == 9 then return "Warlock" end
    if classId == 4 then return "Rogue" end
    if classId == 3 then return "Hunter" end

    if classId == 7 then
        if agi > player:GetStat(4) then return "Shamy Enh" end
        if player:HasTalent(16039, activeSpec) then return "Shamy Ele" end
        if player:HasTalent(16182, activeSpec) then return "Shamy Resto" end
        return "Shamy Ele"
    end

    if classId == 5 then
        if player:HasTalent(47540, activeSpec) then return "Prst Disc" end
        if player:HasTalent(15270, activeSpec) then return "Prst Shad" end
        if player:HasTalent(14913, activeSpec) then return "Prst Holy" end
        return "Prst Disc"
    end

    if classId == 8 then
        if player:HasTalent(54490, activeSpec) then return "Mage Arcane" end
        if player:HasTalent(11069, activeSpec) then return "Mage Fire" end
        if player:HasTalent(31670, activeSpec) then return "Mage Frost" end
        return "Mage Arcane"
    end

    if classId == 11 then
        if agi > int then
            if player:HasTalent(16929, activeSpec) then return "Druid Bear" end
            return "Druid Cat"
        end
        if player:HasTalent(17063, activeSpec) then return "Druid Resto" end
        return "Druid Bal"
    end

    if classId == 2 then
        if int > str then return "Pally Holy" end
        if offHand and offHand:GetInventoryType() == 14 then return "Pally Prot" end
        return "Pally Ret"
    end

    if classId == 6 then
        if player:HasTalent(52143, activeSpec) then return "DK Unhol" end
        if mainHand and offHand and offHand:GetClass() == 2 then return "DK Frost" end
        return "DK Blood"
    end

    if classId == 1 then
        if offHand and offHand:GetInventoryType() == 14 then return "War Prot" end
        if mainHand and offHand and offHand:GetClass() == 2 then return "War Fury" end
        return "War Arms"
    end

    return "Unknown"
end

-- [4] CORE SCORING ENGINE
local function GetScoreByEntry(entry, weights)
    local query = WorldDBQuery(string.format("SELECT * FROM item_template WHERE entry = %d", entry))
    if not query then return 0, nil end
    local row = query:GetRow()
    
    local score = 0
    for i = 1, 10 do
        local sType = row["stat_type"..i]
        local sVal  = row["stat_value"..i]
        local key   = STAT_ID_MAP[sType]
        if key and sVal and sVal > 0 then
            score = score + (sVal * (weights[key] or 0))
        end
    end

    if row.class == 2 then
        score = score + (row.dmg_max1 * (weights.WPW or 0))
    end

    return score, row
end

-- [5] THE DELAYED EXECUTION
local function ExecuteDelayedTransfer(wGUID, tGUID, itemEntry, improvement)
    local winner = GetPlayerByGUID(wGUID)
    local target = GetPlayerByGUID(tGUID)

    -- Safety check: ensure both players are still online
    if not winner or not target then return end

    -- Re-scan the inventory for the item (post-forging)
    local item = winner:GetItemByEntry(itemEntry)
    
    if item then
        local itemName = item:GetName()
        local group = winner:GetGroup()
        
        print(LOG_PREFIX .. "Executing delay-safe transfer: " .. itemName)

        -- Broadcast to the group
        if group then
            local announce = string.format(COLOR_PREFIX .. "Arbiter: %s (+%.2f) transferred to %s.", itemName, improvement, target:GetName())
            local members = group:GetMembers()
            for _, member in ipairs(members) do
                member:SendBroadcastMessage(announce)
            end
        end

        -- Finalize movement[cite: 2]
        winner:RemoveItem(item, 1)
        target:AddItem(itemEntry, 1)
    end
end

-- [6] REWARD HANDLER
local function OnGroupRollReward(event, winner, item, count, voteType, roll)
    local group = winner:GetGroup()
    if not group then return end

    local itemEntry = item:GetEntry()
    local _, template = GetScoreByEntry(itemEntry, MASTER_WEIGHTS["Warlock"])
    
    -- Only process Gear/Weapons[cite: 2]
    if not template or (template.class ~= 2 and template.class ~= 4) then return end

    local bestPlayer = nil
    local maxImprovement = 0
    local members = group:GetMembers()

    for _, member in ipairs(members) do
        if member and member:IsInWorld() then
            local spec = GetHeuristicSpec(member)
            local weights = MASTER_WEIGHTS[spec]

            if weights then
                local isInvalid2H = (template.InventoryType == 17 and (spec == "Pally Prot" or spec == "War Prot" or spec == "DK Frost"))
                
                if not isInvalid2H then
                    local lootedScore = GetScoreByEntry(itemEntry, weights)
                    local slot = INV_TO_SLOT[template.InventoryType]
                    local currentItem = slot and member:GetEquippedItemBySlot(slot)
                    local currentScore = currentItem and GetScoreByEntry(currentItem:GetEntry(), weights) or 0
                    local improvement = lootedScore - currentScore
                    
                    if improvement > maxImprovement then
                        maxImprovement = improvement
                        bestPlayer = member
                    end
                end
            end
        end
    end

    -- Trigger 200ms delay to avoid Forging.lua collision[cite: 2]
    if bestPlayer and bestPlayer:GetGUID() ~= winner:GetGUID() and maxImprovement > 0 then
        local wGUID = winner:GetGUID()
        local tGUID = bestPlayer:GetGUID()
        
        -- If CreateLuaEvent fails, this build likely uses 'RegisterEvent' or 'CreateEvent'[cite: 2]
        -- We use 200ms delay, 1 execution[cite: 2]
        CreateLuaEvent(function() 
            ExecuteDelayedTransfer(wGUID, tGUID, itemEntry, maxImprovement) 
        end, 200, 1)
    end
end

-- [6] SIMPLIFIED CHECK COMMAND
local function OnPlayerChat(event, player, msg, type, lang)
    if (msg:lower() == "check") then
        local spec = GetHeuristicSpec(player)
        player:SendBroadcastMessage(COLOR_PREFIX .. "Detected Spec: " .. spec)
        return false
    end
end

RegisterPlayerEvent(18, OnPlayerChat)
RegisterPlayerEvent(56, OnGroupRollReward)