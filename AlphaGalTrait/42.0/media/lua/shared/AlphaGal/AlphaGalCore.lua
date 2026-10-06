require "AlphaGal/AlphaGalAPI"

AlphaGalCore = AlphaGalCore or {}
AlphaGalCore.pendingDeaths = AlphaGalCore.pendingDeaths or {}
AlphaGalCore.activeSevere = AlphaGalCore.activeSevere or {}

local function clamp(value, low, high)
    if value < low then return low end
    if value > high then return high end
    return value
end

local function getConfig(name, fallback)
    if SandboxVars and SandboxVars.AlphaGal and SandboxVars.AlphaGal[name] ~= nil then
        return tonumber(SandboxVars.AlphaGal[name]) or fallback
    end
    return fallback
end

local function getData(player)
    return player:getModData()
end

local function getStat(player, stat)
    return player:getStats():get(stat)
end

local function setStat(player, stat, value)
    player:getStats():set(stat, value)
end

local function atLeast(player, stat, value, high)
    setStat(player, stat, math.min(high, math.max(getStat(player, stat), value)))
end

local function atMost(player, stat, value, low)
    setStat(player, stat, math.max(low, math.min(getStat(player, stat), value)))
end

function AlphaGalCore.hasTrait(player)
    if not player then return false end
    if AlphaGalRegistry and AlphaGalRegistry.traits and AlphaGalRegistry.traits.alphaGal then
        return player:hasTrait(AlphaGalRegistry.traits.alphaGal)
    end
    return false
end

function AlphaGalCore.getExposure(player)
    if not player then return 0 end
    return math.max(0, tonumber(getData(player).alphaGalExposure) or 0)
end

function AlphaGalCore.getSeverity(exposure)
    if exposure >= 0.75 then return 3, "severe" end
    if exposure >= 0.35 then return 2, "moderate" end
    return 1, "mild"
end

local function chanceFor(severity)
    if severity == 3 then return getConfig("SevereReactionChance", 100) end
    if severity == 2 then return getConfig("ModerateReactionChance", 85) end
    return getConfig("MildReactionChance", 65)
end

local function rollReaction(severity)
    local chance = clamp(chanceFor(severity), 0, 100)
    if chance >= 100 then return true end
    if chance <= 0 then return false end
    return ZombRand(100) < chance
end

local function clearReaction(player)
    local data = getData(player)
    AlphaGalCore.activeSevere[player] = nil
    data.alphaGalReactionSeverity = nil
    data.alphaGalReactionElapsed = nil
    data.alphaGalStartHealth = nil
    data.alphaGalTargetHealth = nil
    data.alphaGalStartTemperature = nil
    data.alphaGalTargetTemperature = nil
    data.alphaGalStartFoodSickness = nil
    data.alphaGalStartStress = nil
    data.alphaGalStartPanic = nil
    data.alphaGalStartPain = nil
    data.alphaGalStartFatigue = nil
    data.alphaGalStartEndurance = nil
    data.alphaGalDesiredFoodSickness = nil
    data.alphaGalDesiredStress = nil
    data.alphaGalDesiredPanic = nil
    data.alphaGalDesiredPain = nil
    data.alphaGalDesiredFatigue = nil
    data.alphaGalDesiredEndurance = nil
end

local function clearPendingReaction(data)
    data.alphaGalPendingSeverity = nil
    data.alphaGalReactionDelayElapsed = nil
end

local function startMild(player)
    local data = getData(player)
    data.alphaGalReactionSeverity = 1
    data.alphaGalReactionElapsed = 0
    atLeast(player, CharacterStat.FOOD_SICKNESS, 25, 100)
    atLeast(player, CharacterStat.STRESS, 0.22, 1)
    atLeast(player, CharacterStat.PANIC, 10, 100)
    atLeast(player, CharacterStat.PAIN, 10, 100)
    atMost(player, CharacterStat.ENDURANCE, 0.72, 0)
end

local function startModerate(player)
    local data = getData(player)
    data.alphaGalReactionSeverity = 2
    data.alphaGalReactionElapsed = 0
    atLeast(player, CharacterStat.FOOD_SICKNESS, 42, 100)
    atLeast(player, CharacterStat.STRESS, 0.45, 1)
    atLeast(player, CharacterStat.PANIC, 28, 100)
    atLeast(player, CharacterStat.PAIN, 32, 100)
    atLeast(player, CharacterStat.FATIGUE, 0.28, 1)
    atMost(player, CharacterStat.ENDURANCE, 0.40, 0)
    AlphaGalAPI.triggerVomitingHandlers(player, "moderate")
end

local function startSevere(player)
    local data = getData(player)
    local body = player:getBodyDamage()
    local health = body:getOverallBodyHealth()
    data.alphaGalReactionSeverity = 3
    data.alphaGalReactionElapsed = 0
    data.alphaGalStartHealth = health
    data.alphaGalTargetHealth = math.min(health, 50)

    local currentTemperature = getStat(player, CharacterStat.TEMPERATURE)
    local maxTemperature = CharacterStat.TEMPERATURE:getMaximumValue()
    data.alphaGalStartTemperature = currentTemperature
    data.alphaGalTargetTemperature = currentTemperature + ((maxTemperature - currentTemperature) * 0.85)

    data.alphaGalStartFoodSickness = getStat(player, CharacterStat.FOOD_SICKNESS)
    data.alphaGalStartStress = getStat(player, CharacterStat.STRESS)
    data.alphaGalStartPanic = getStat(player, CharacterStat.PANIC)
    data.alphaGalStartPain = getStat(player, CharacterStat.PAIN)
    data.alphaGalStartFatigue = getStat(player, CharacterStat.FATIGUE)
    data.alphaGalStartEndurance = getStat(player, CharacterStat.ENDURANCE)

    data.alphaGalDesiredFoodSickness = data.alphaGalStartFoodSickness
    data.alphaGalDesiredStress = data.alphaGalStartStress
    data.alphaGalDesiredPanic = data.alphaGalStartPanic
    data.alphaGalDesiredPain = data.alphaGalStartPain
    data.alphaGalDesiredFatigue = data.alphaGalStartFatigue
    data.alphaGalDesiredEndurance = data.alphaGalStartEndurance

    AlphaGalCore.activeSevere[player] = true
    AlphaGalAPI.triggerVomitingHandlers(player, "severe")
end

function AlphaGalCore.startReaction(player, severity)
    if severity == 3 then
        startSevere(player)
    elseif severity == 2 then
        startModerate(player)
    else
        startMild(player)
    end
end

function AlphaGalCore.consume(player, dose)
    if not player or player:isDead() or not AlphaGalCore.hasTrait(player) then return false end
    local amount = clamp(tonumber(dose) or 0, 0, 4)
    if amount <= 0 then return false end

    local data = getData(player)
    data.alphaGalExposure = AlphaGalCore.getExposure(player) + amount
    local severity = AlphaGalCore.getSeverity(data.alphaGalExposure)
    local active = tonumber(data.alphaGalReactionSeverity) or 0
    local pending = tonumber(data.alphaGalPendingSeverity) or 0

    if severity <= math.max(active, pending) then return true end
    if not rollReaction(severity) then return true end

    data.alphaGalPendingSeverity = severity
    data.alphaGalReactionDelayElapsed = 0
    return true
end

local function tickMild(player, data)
    data.alphaGalReactionElapsed = (tonumber(data.alphaGalReactionElapsed) or 0) + (1 / 60)
    atLeast(player, CharacterStat.FOOD_SICKNESS, 25, 100)
    atLeast(player, CharacterStat.STRESS, 0.22, 1)
    atLeast(player, CharacterStat.PAIN, 8, 100)
    atMost(player, CharacterStat.ENDURANCE, 0.72, 0)
    if data.alphaGalReactionElapsed >= 1.0 then
        clearReaction(player)
    end
end

local function tickModerate(player, data)
    data.alphaGalReactionElapsed = (tonumber(data.alphaGalReactionElapsed) or 0) + (1 / 60)
    atLeast(player, CharacterStat.FOOD_SICKNESS, 45, 100)
    atLeast(player, CharacterStat.STRESS, 0.48, 1)
    atLeast(player, CharacterStat.PANIC, 30, 100)
    atLeast(player, CharacterStat.PAIN, 34, 100)
    atLeast(player, CharacterStat.FATIGUE, 0.30, 1)
    atMost(player, CharacterStat.ENDURANCE, 0.38, 0)
    if data.alphaGalReactionElapsed >= 2.0 then
        clearReaction(player)
    end
end

local function beginDeathCountdown(player, data)
    if data.alphaGalDeathAtMs and tonumber(data.alphaGalDeathAtMs) > 0 then return end
    player:addLineChatElement("I can't breathe....")
    data.alphaGalDeathAtMs = getTimestampMs() + 5000
    AlphaGalCore.pendingDeaths[player] = true
    clearReaction(player)
end

local function tickSevere(player, data)
    local duration = math.max(0.5, getConfig("SevereReactionHours", 3.0))
    data.alphaGalReactionElapsed = (tonumber(data.alphaGalReactionElapsed) or 0) + (1 / 60)
    local progress = clamp(data.alphaGalReactionElapsed / duration, 0, 1)
    local body = player:getBodyDamage()
    local startHealth = tonumber(data.alphaGalStartHealth) or body:getOverallBodyHealth()
    local targetHealth = tonumber(data.alphaGalTargetHealth) or math.min(startHealth, 50)
    local desiredHealth = startHealth - ((startHealth - targetHealth) * progress)
    local currentHealth = body:getOverallBodyHealth()
    if currentHealth > desiredHealth then
        body:ReduceGeneralHealth(currentHealth - desiredHealth)
    end

    local currentTemperature = getStat(player, CharacterStat.TEMPERATURE)
    local startTemperature = tonumber(data.alphaGalStartTemperature) or currentTemperature
    local maxTemperature = CharacterStat.TEMPERATURE:getMaximumValue()
    local targetTemperature = tonumber(data.alphaGalTargetTemperature) or (startTemperature + ((maxTemperature - startTemperature) * 0.85))
    local desiredTemperature = startTemperature + ((targetTemperature - startTemperature) * progress)
    if currentTemperature < desiredTemperature then
        setStat(player, CharacterStat.TEMPERATURE, desiredTemperature)
    end

    local startFoodSickness = tonumber(data.alphaGalStartFoodSickness) or getStat(player, CharacterStat.FOOD_SICKNESS)
    local startStress = tonumber(data.alphaGalStartStress) or getStat(player, CharacterStat.STRESS)
    local startPanic = tonumber(data.alphaGalStartPanic) or getStat(player, CharacterStat.PANIC)
    local startPain = tonumber(data.alphaGalStartPain) or getStat(player, CharacterStat.PAIN)
    local startFatigue = tonumber(data.alphaGalStartFatigue) or getStat(player, CharacterStat.FATIGUE)
    local startEndurance = tonumber(data.alphaGalStartEndurance) or getStat(player, CharacterStat.ENDURANCE)

    data.alphaGalDesiredFoodSickness = startFoodSickness + ((95 - startFoodSickness) * progress)
    data.alphaGalDesiredStress = startStress + ((0.95 - startStress) * progress)
    data.alphaGalDesiredPanic = startPanic + ((95 - startPanic) * progress)
    data.alphaGalDesiredPain = startPain + ((90 - startPain) * progress)
    data.alphaGalDesiredFatigue = startFatigue + ((0.85 - startFatigue) * progress)
    data.alphaGalDesiredEndurance = startEndurance + ((0.08 - startEndurance) * progress)

    atLeast(player, CharacterStat.FOOD_SICKNESS, data.alphaGalDesiredFoodSickness, 100)
    atLeast(player, CharacterStat.STRESS, data.alphaGalDesiredStress, 1)
    atLeast(player, CharacterStat.PANIC, data.alphaGalDesiredPanic, 100)
    atLeast(player, CharacterStat.PAIN, data.alphaGalDesiredPain, 100)
    atLeast(player, CharacterStat.FATIGUE, data.alphaGalDesiredFatigue, 1)
    atMost(player, CharacterStat.ENDURANCE, data.alphaGalDesiredEndurance, 0)

    if progress >= 1 then
        local finalHealth = body:getOverallBodyHealth()
        if finalHealth > targetHealth then
            body:ReduceGeneralHealth(finalHealth - targetHealth)
        end
        beginDeathCountdown(player, data)
    end
end

function AlphaGalCore.tickPlayerMinute(player)
    if not player or player:isDead() or not AlphaGalCore.hasTrait(player) then return end
    local data = getData(player)
    local decay = math.max(0, getConfig("ExposureDecayPerHour", 0.08)) / 60
    data.alphaGalExposure = math.max(0, AlphaGalCore.getExposure(player) - decay)

    local pendingSeverity = tonumber(data.alphaGalPendingSeverity) or 0
    if pendingSeverity > 0 then
        local delayHours = math.max(0, getConfig("ReactionDelayHours", 2.0))
        data.alphaGalReactionDelayElapsed = (tonumber(data.alphaGalReactionDelayElapsed) or 0) + (1 / 60)
        if data.alphaGalReactionDelayElapsed >= delayHours then
            clearPendingReaction(data)
            AlphaGalCore.startReaction(player, pendingSeverity)
        end
    end

    local severity = tonumber(data.alphaGalReactionSeverity) or 0
    if severity == 3 then
        tickSevere(player, data)
    elseif severity == 2 then
        tickModerate(player, data)
    elseif severity == 1 then
        tickMild(player, data)
    end

    if tonumber(data.alphaGalDeathAtMs) and tonumber(data.alphaGalDeathAtMs) > 0 then
        AlphaGalCore.pendingDeaths[player] = true
    end
end

function AlphaGalCore.forEachPlayer(fn)
    if isClient() then return end
    if isServer() then
        local players = getOnlinePlayers()
        if not players then return end
        for i = 0, players:size() - 1 do
            local player = players:get(i)
            if player and not player:isDead() then fn(player) end
        end
        return
    end
    local count = getNumActivePlayers()
    for i = 0, count - 1 do
        local player = getSpecificPlayer(i)
        if player and not player:isDead() then fn(player) end
    end
end

function AlphaGalCore.onMinute()
    AlphaGalCore.forEachPlayer(AlphaGalCore.tickPlayerMinute)
end

local function enforceSevereStats(player)
    if not player or player:isDead() then
        AlphaGalCore.activeSevere[player] = nil
        return
    end

    local data = getData(player)
    if tonumber(data.alphaGalReactionSeverity) ~= 3 then
        AlphaGalCore.activeSevere[player] = nil
        return
    end

    if tonumber(data.alphaGalDesiredFoodSickness) then atLeast(player, CharacterStat.FOOD_SICKNESS, tonumber(data.alphaGalDesiredFoodSickness), 100) end
    if tonumber(data.alphaGalDesiredStress) then atLeast(player, CharacterStat.STRESS, tonumber(data.alphaGalDesiredStress), 1) end
    if tonumber(data.alphaGalDesiredPanic) then atLeast(player, CharacterStat.PANIC, tonumber(data.alphaGalDesiredPanic), 100) end
    if tonumber(data.alphaGalDesiredPain) then atLeast(player, CharacterStat.PAIN, tonumber(data.alphaGalDesiredPain), 100) end
    if tonumber(data.alphaGalDesiredFatigue) then atLeast(player, CharacterStat.FATIGUE, tonumber(data.alphaGalDesiredFatigue), 1) end
    if tonumber(data.alphaGalDesiredEndurance) then atMost(player, CharacterStat.ENDURANCE, tonumber(data.alphaGalDesiredEndurance), 0) end
end

function AlphaGalCore.onTick()
    for player, _ in pairs(AlphaGalCore.activeSevere) do
        enforceSevereStats(player)
    end

    for player, _ in pairs(AlphaGalCore.pendingDeaths) do
        if not player or player:isDead() then
            AlphaGalCore.pendingDeaths[player] = nil
        else
            local data = getData(player)
            local deathAt = tonumber(data.alphaGalDeathAtMs) or 0
            if deathAt <= 0 then
                AlphaGalCore.pendingDeaths[player] = nil
            elseif getTimestampMs() >= deathAt then
                local body = player:getBodyDamage()
                body:ReduceGeneralHealth(200)
                body:setOverallBodyHealth(0)
                player:setHealth(0)
                data.alphaGalExposure = 0
                data.alphaGalDeathAtMs = nil
                AlphaGalCore.pendingDeaths[player] = nil
            end
        end
    end
end
