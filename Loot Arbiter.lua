local LOG_PREFIX = "[SpecArbiter] "
local COLOR_PREFIX = "|cff00ff00[SpecArbiter]|r "

-- Minimum percentage upgrade required to trigger a transfer. Set low because a
-- 1% gain on near-BiS gear is still a real upgrade worth arbitrating; the
-- floor below keeps low-geared players from flooding the chat with redirects.
local MIN_IMPROVEMENT_PCT = 1.0

-- Floors currentScore in the % calculation at this fraction of the looted item's
-- score. Prevents an empty slot or a level-1 grey from inflating % into the
-- thousands and stealing loot from a player making a real upgrade.
local TRIVIAL_BASELINE_FLOOR = 0.10

-- [1] DATA MAPS
local STAT_ID_MAP = { [4]="STR", [3]="AGI", [7]="STA", [5]="INT", [6]="SPI", [38]="AP", [45]="SP", [31]="HIT", [32]="CRIT", [36]="HASTE", [37]="EXP", [12]="DEF", [13]="DODGE", [14]="PARRY", [15]="BLOCK" }

-- Helper to check if a spec should be compared against both weapon slots
local function CanDualWield(spec)
    local dwSpecs = {
        ["Hunter"] = true,
        ["Rogue"] = true,
        ["Shamy Enh"] = true,
        ["War Fury"] = true,
        ["DK Frost"] = true
    }
    return dwSpecs[spec] or false
end

-- Maps Weapon Subclasses to Skill IDs for HasSkill check
local WEAPON_SKILL_MAP = {
    [0]  = 44,  -- One-Handed Axes
    [1]  = 172, -- Two-Handed Axes
    [2]  = 45,  -- Bows
    [3]  = 46,  -- Guns
    [4]  = 54,  -- One-Handed Maces
    [5]  = 160, -- Two-Handed Maces
    [6]  = 229, -- Polearms
    [7]  = 55,  -- One-Handed Swords
    [8]  = 172, -- Two-Handed Swords
    [10] = 136, -- Staves
    [13] = 473, -- Fist Weapons
    [15] = 173, -- Daggers
    [18] = 226, -- Crossbows
    [19] = 166, -- Wands
}

-- Maps Player Class ID to their maximum allowed Armor Subclass
local MAX_ARMOR_MAP = {
    [1]  = 4, -- Warrior: Plate
    [2]  = 4, -- Paladin: Plate
    [3]  = 3, -- Hunter: Mail
    [4]  = 2, -- Rogue: Leather
    [5]  = 1, -- Priest: Cloth
    [6]  = 4, -- DK: Plate
    [7]  = 3, -- Shaman: Mail
    [8]  = 1, -- Mage: Cloth
    [9]  = 1, -- Warlock: Cloth
    [11] = 2, -- Druid: Leather
}

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
    [21] = 15, -- Main Hand
    [22] = 16, -- Off Hand
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
    ["DK Blood"]    = {STR=1, AGI=0.48, STA=1, INT=0, SPI=0.05, AP=0.35, SP=0, HIT=0.87, CRIT=0.54, HASTE=0.52, EXP=0.86, DEF=0.7, DODGE=0.7, PARRY=0.8, BLOCK=0, WPW=0.3},
    ["DK Frost"]    = {STR=1, AGI=0.78, STA=0.3, INT=0, SPI=0.05, AP=0.37, SP=0, HIT=1.03, CRIT=0.46, HASTE=0.29, EXP=0.84, DEF=0.05, DODGE=0.05, PARRY=0.12, BLOCK=0, WPW=0.4},
    ["DK Unhol"]    = {STR=1, AGI=0.58, STA=0.3, INT=0, SPI=0.05, AP=0.66, SP=0, HIT=0.66, CRIT=0.45, HASTE=0.48, EXP=0.51, DEF=0.05, DODGE=0.05, PARRY=0.12, BLOCK=0, WPW=0.3},
    ["War Fury"]    = {STR=1, AGI=0.77, STA=0.3, AP=0.66, HIT=0.55, CRIT=0.93, HASTE=0.79, EXP=1.5, ARPEN=1.1, WPW=0.4},
    ["War Arms"]    = {STR=1, AGI=0.65, STA=0.3, AP=0.58, HIT=0.5, CRIT=0.8, HASTE=0.65, EXP=1.2, ARPEN=1.4, WPW=0.4},
    ["War Prot"]    = {STR=0.33, AGI=0.59, STA=1, AP=0.34, HIT=0.67, CRIT=0.28, HASTE=0.21, EXP=0.94, DEF=0.81, DODGE=0.7, PARRY=0.58, BLOCK=0.59, WPW=0.1},
}

-- [3] TALENT-TREE SPEC IDENTIFIER
-- Each entry lists representative talent spell IDs heavily invested in by that spec.
-- The detector counts how many of these the player has and picks the spec with the
-- highest count. Extend these lists for sharper detection.
local SPEC_TALENT_SIGNATURES = {
    -- Warrior
    ["War Arms"]    = {12294, 12834, 46924},  -- Mortal Strike, Deep Wounds, Bladestorm
    ["War Fury"]    = {23881, 12950, 46917},  -- Bloodthirst, Unbridled Wrath, Titan's Grip
    ["War Prot"]    = {23922, 12975, 46968},  -- Shield Slam, Last Stand, Shockwave
    -- Paladin
    ["Pally Holy"]  = {20210, 31821, 53563},  -- Illumination, Aura Mastery, Beacon of Light
    ["Pally Prot"]  = {20911, 31935, 53595},  -- Blessing of Sanctuary, Avenger's Shield, Hammer of the Righteous
    ["Pally Ret"]   = {20049, 31876, 53385},  -- Vengeance, Sanctified Retribution, Divine Storm
    -- Death Knight
    ["DK Blood"]    = {48982, 49016, 49028},  -- Rune Tap, Hysteria, Dancing Rune Weapon
    ["DK Frost"]    = {51271, 49203, 51128},  -- Unbreakable Armor, Hungering Cold, Killing Machine
    ["DK Unhol"]    = {52143, 49206, 49530},  -- Master of Ghouls, Summon Gargoyle, Sudden Doom
    -- Shaman
    ["Shamy Ele"]   = {16039, 16578, 51490},  -- Convection, Elemental Focus, Thunderstorm
    ["Shamy Enh"]   = {17364, 30802, 51533},  -- Stormstrike, Unleashed Rage, Feral Spirit
    ["Shamy Resto"] = {16182, 974,   61295},  -- Improved Reincarnation, Earth Shield, Riptide
    -- Priest
    ["Prst Disc"]   = {33206, 47509, 47540},  -- Pain Suppression, Divine Aegis, Penance
    ["Prst Holy"]   = {14913, 33076, 47788},  -- Holy Specialization, Prayer of Mending, Guardian Spirit
    ["Prst Shad"]   = {15270, 15487, 47585},  -- Spirit Tap, Silence, Dispersion
    -- Mage
    ["Mage Arcane"] = {54490, 31571, 44425},  -- Incanter's Absorption, Arcane Power, Arcane Barrage
    ["Mage Fire"]   = {11069, 11129, 44457},  -- Improved Scorch, Combustion, Living Bomb
    ["Mage Frost"]  = {31670, 11958, 44572},  -- Arctic Reach, Cold Snap, Deep Freeze
    -- Druid (Cat vs Bear share Feral tree; resolve via form-specific talents)
    ["Druid Bal"]   = {24858, 33831, 48505},  -- Moonkin Form, Force of Nature, Starfall
    ["Druid Cat"]   = {48492, 16972, 50334},  -- King of the Jungle, Predatory Strikes, Berserk
    ["Druid Bear"]  = {16929, 57878, 50334},  -- Thick Hide, Natural Reaction, Berserk
    ["Druid Resto"] = {17063, 33891, 48438},  -- Naturalist, Tree of Life, Wild Growth
    -- Single-spec classes (all three trees collapse to one weight set)
    ["Hunter"]      = {53270, 53209, 53301},  -- BM, MM, Surv capstones
    ["Rogue"]       = {51662, 51690, 51713},  -- Assn, Combat, Sub capstones
    ["Warlock"]     = {48181, 47241, 50796},  -- Aff, Demo, Destro capstones
}

-- Class ID -> candidate spec names to score against
local CLASS_SPEC_CANDIDATES = {
    [1]  = {"War Arms", "War Fury", "War Prot"},
    [2]  = {"Pally Holy", "Pally Prot", "Pally Ret"},
    [3]  = {"Hunter"},
    [4]  = {"Rogue"},
    [5]  = {"Prst Disc", "Prst Holy", "Prst Shad"},
    [6]  = {"DK Blood", "DK Frost", "DK Unhol"},
    [7]  = {"Shamy Ele", "Shamy Enh", "Shamy Resto"},
    [8]  = {"Mage Arcane", "Mage Fire", "Mage Frost"},
    [9]  = {"Warlock"},
    [11] = {"Druid Bal", "Druid Cat", "Druid Bear", "Druid Resto"},
}

local function CountTalentMatches(player, talentList, activeSpec)
    local count = 0
    for _, spellId in ipairs(talentList) do
        if player:HasTalent(spellId, activeSpec) then
            count = count + 1
        end
    end
    return count
end

local function GetSpecByTalents(player)
    local classId = player:GetClass()
    local candidates = CLASS_SPEC_CANDIDATES[classId]
    if not candidates then return nil end

    local activeSpec = player:GetActiveSpec() or 0

    local bestSpec, bestCount = nil, 0
    for _, spec in ipairs(candidates) do
        local sig = SPEC_TALENT_SIGNATURES[spec]
        if sig then
            local matches = CountTalentMatches(player, sig, activeSpec)
            if matches > bestCount then
                bestCount = matches
                bestSpec = spec
            end
        end
    end

    return bestSpec
end

local function GetHeuristicSpec(player)
    -- Primary: invested talent tree wins.
    local byTalents = GetSpecByTalents(player)
    if byTalents then return byTalents end

    -- Fallback: stat/gear heuristic for fresh chars with no points yet.
    local classId = player:GetClass()
    local mainHand = player:GetEquippedItemBySlot(15)
    local offHand = player:GetEquippedItemBySlot(16)
    local agi, int, str = player:GetStat(1), player:GetStat(3), player:GetStat(0)

    if classId == 9 then return "Warlock" end
    if classId == 4 then return "Rogue" end
    if classId == 3 then return "Hunter" end

    if classId == 7 then
        if agi > player:GetStat(4) then return "Shamy Enh" end
        return "Shamy Ele"
    end

    if classId == 5 then return "Prst Disc" end
    if classId == 8 then return "Mage Arcane" end

    if classId == 11 then
        if agi > int then return "Druid Cat" end
        return "Druid Bal"
    end

    if classId == 2 then
        if int > str then return "Pally Holy" end
        if offHand and offHand:GetInventoryType() == 14 then return "Pally Prot" end
        return "Pally Ret"
    end

    if classId == 6 then
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

    if not winner or not target then return end

    local item = winner:GetItemByEntry(itemEntry)
    
    if item then
        local itemName = item:GetName()
        local group = winner:GetGroup()
        local suffixId = item:GetRandomSuffix() 
        
        print(LOG_PREFIX .. "Executing transfer: " .. itemName .. " to " .. target:GetName())

        local addedItem = target:AddItem(itemEntry, 1, suffixId)

        if not addedItem then
            SendMail("Arbiter Loot Distribution", "Your bags were full. Here is your upgrade: " .. itemName, target:GetGUIDLow(), 0, 61, 0, 0, 0, itemEntry, 1, suffixId)
            target:SendBroadcastMessage(COLOR_PREFIX .. "Your bags were full! |cff00ff00" .. itemName .. "|r has been sent to your mail.")
        end

        winner:RemoveItem(item, 1)

        if group then
            local announce = string.format(COLOR_PREFIX .. "Arbiter: %s (+%.1f%%) transferred to %s.", itemName, improvement, target:GetName())
            local members = group:GetMembers()
            for _, member in ipairs(members) do
                member:SendBroadcastMessage(announce)
            end
        end
    end
end

-- [6] REWARD HANDLER
local function OnGroupRollReward(event, winner, item, count, voteType, roll)
    local group = winner:GetGroup()
    if not group then return end

    local itemEntry = item:GetEntry()
    local _, template = GetScoreByEntry(itemEntry, MASTER_WEIGHTS["Warlock"])
    
    if not template then return end

    local candidates = {}
    local members = group:GetMembers()

    for _, member in ipairs(members) do
        if member and member:IsInWorld() then
            local spec = GetHeuristicSpec(member)
            local weights = MASTER_WEIGHTS[spec]
            local classId = member:GetClass()

            if weights then
                local isEligible = true

                -- [A] WEAPON SKILL CHECK
                if template.class == 2 then
                    local requiredSkill = WEAPON_SKILL_MAP[template.subclass]
                    if requiredSkill and not member:HasSkill(requiredSkill) then
                        isEligible = false
                    end
                end

                -- [B] ARMOR TYPE CHECK
                if template.class == 4 then
                    local maxArmor = MAX_ARMOR_MAP[classId] or 1
                    if template.subclass > maxArmor then
                        isEligible = false
                    end
                end

                -- [C] SPELL POWER SANITY CHECK
                local hasSP = false
                for i = 1, 10 do
                    if template["stat_type"..i] == 45 then hasSP = true break end
                end
                if hasSP and (weights.SP or 0) <= 0 then
                    isEligible = false
                end

                -- [D] SPEC OPTIMIZATION (Hardcoded Exclusions)
                local isBadOpt = (template.InventoryType == 17 and
                    (spec == "Pally Prot" or spec == "War Prot" or spec == "DK Frost" or spec == "Shamy Enh"))

                if isEligible and not isBadOpt then
                    local lootedScore = GetScoreByEntry(itemEntry, weights)
                    local currentScore = 0

                    if (template.InventoryType == 13 or template.InventoryType == 21 or template.InventoryType == 22) and CanDualWield(spec) then
                        local mhItem = member:GetEquippedItemBySlot(15)
                        local ohItem = member:GetEquippedItemBySlot(16)

                        local mhScore = mhItem and GetScoreByEntry(mhItem:GetEntry(), weights) or 0
                        local ohScore = ohItem and GetScoreByEntry(ohItem:GetEntry(), weights) or 0

                        if template.InventoryType == 21 then
                            currentScore = mhScore
                        elseif template.InventoryType == 22 then
                            currentScore = ohScore
                        else
                            currentScore = math.min(mhScore, ohScore)
                        end
                    else
                        local slot = INV_TO_SLOT[template.InventoryType]
                        local currentItem = slot and member:GetEquippedItemBySlot(slot)
                        currentScore = currentItem and GetScoreByEntry(currentItem:GetEntry(), weights) or 0
                    end

                    local denom = math.max(currentScore, lootedScore * TRIVIAL_BASELINE_FLOOR)
                    local pctImprovement = 0
                    if denom > 0 then
                        pctImprovement = ((lootedScore - currentScore) / denom) * 100
                    end

                    if pctImprovement > 0 then
                        table.insert(candidates, {member = member, spec = spec, pct = pctImprovement})
                    end
                end
            end
        end
    end

    -- BiS override pass: if the item is on any candidate's BiS/Alt list, only
    -- BiS-eligible candidates compete (best % among them wins). Falls through
    -- to normal % scoring if nobody in the group has it as BiS.
    local bisList = (_G.LootArbiter_BIS_OVERRIDES or {})[itemEntry]
    local bisLookup = nil
    if bisList then
        bisLookup = {}
        for _, s in ipairs(bisList) do bisLookup[s] = true end
    end

    local bestPlayer, bestPct, bisWin = nil, 0, false
    if bisLookup then
        for _, c in ipairs(candidates) do
            if bisLookup[c.spec] and c.pct > bestPct then
                bestPct = c.pct
                bestPlayer = c.member
                bisWin = true
            end
        end
    end
    if not bestPlayer then
        for _, c in ipairs(candidates) do
            if c.pct > bestPct then
                bestPct = c.pct
                bestPlayer = c.member
            end
        end
    end

    -- BiS matches bypass the min-% threshold; even a tiny upgrade on a known
    -- BiS piece is worth routing.
    local meetsThreshold = bisWin or bestPct >= MIN_IMPROVEMENT_PCT

    if bestPlayer and bestPlayer:GetGUID() ~= winner:GetGUID() and meetsThreshold then
        local wGUID = winner:GetGUID()
        local tGUID = bestPlayer:GetGUID()
        print(LOG_PREFIX .. "Queuing transfer for " .. item:GetName() .. (bisWin and " [BiS]" or ""))
        CreateLuaEvent(function()
            ExecuteDelayedTransfer(wGUID, tGUID, itemEntry, bestPct)
        end, 200, 1)
    else
        print(LOG_PREFIX .. "No transfer needed for " .. item:GetName())
    end
end

-- [7] SIMPLIFIED CHECK COMMAND
local function OnPlayerChat(event, player, msg, type, lang)
    if (msg:lower() == "check") then
        local spec = GetHeuristicSpec(player)
        player:SendBroadcastMessage(COLOR_PREFIX .. "Detected Spec: " .. spec)
        return false
    end
end

RegisterPlayerEvent(18, OnPlayerChat)
RegisterPlayerEvent(56, OnGroupRollReward)
