AlphaGalAPI = AlphaGalAPI or {}

AlphaGalAPI.redMeat = AlphaGalAPI.redMeat or {}
AlphaGalAPI.whiteMeat = AlphaGalAPI.whiteMeat or {}
AlphaGalAPI.vomitingHandlers = AlphaGalAPI.vomitingHandlers or {}

local redFoodTypes = {
    BEEF = true,
    PORK = true,
    BACON = true,
    HAM = true,
    LAMB = true,
    MUTTON = true,
    VENISON = true,
    GAME = true,
    SAUSAGE = true,
    MEAT = true,
}

local whiteFoodTypes = {
    CHICKEN = true,
    TURKEY = true,
    DUCK = true,
    POULTRY = true,
    FISH = true,
    SEAFOOD = true,
    ROE = true,
}

local whiteTokens = {
    "chicken", "turkey", "duck", "goose", "pheasant", "quail", "smallbird", "poultry",
    "fish", "seafood", "salmon", "trout", "tuna", "bass", "catfish", "pike", "perch",
    "shrimp", "prawn", "crab", "lobster", "oyster", "mussel", "clam", "squid", "octopus",
    "roe", "frog", "snail", "insect", "cricket", "grasshopper", "cockroach", "worm",
}

local redTokens = {
    "beef", "steak", "meatpatty", "groundbeef", "pork", "bacon", "salami", "pepperoni",
    "lamb", "mutton", "venison", "deer", "boar", "bison", "goat", "rabbit", "veal",
}

local function clamp(value, low, high)
    if value < low then return low end
    if value > high then return high end
    return value
end

local function listEach(list, fn)
    if not list then return end
    if type(list) == "table" then
        for _, value in pairs(list) do
            fn(value)
        end
        return
    end
    local ok, size = pcall(function() return list:size() end)
    if not ok or not size then return end
    for i = 0, size - 1 do
        fn(list:get(i))
    end
end

local function safeString(call)
    local ok, value = pcall(call)
    if not ok or value == nil then return "" end
    return tostring(value)
end

local function getFullType(item)
    if not item then return "" end
    return safeString(function() return item:getFullType() end)
end

local function getFoodType(item)
    if not item then return "" end
    local value = safeString(function() return item:getFoodType() end)
    return string.upper(value)
end

local function containsToken(value, tokens)
    value = string.lower(value or "")
    for i = 1, #tokens do
        if string.find(value, tokens[i], 1, true) then
            return true
        end
    end
    return false
end

function AlphaGalAPI.registerRedMeat(fullType, triggerStrength)
    if type(fullType) ~= "string" or fullType == "" then return false end
    local strength = tonumber(triggerStrength) or 1.0
    AlphaGalAPI.redMeat[fullType] = math.max(0, strength)
    AlphaGalAPI.whiteMeat[fullType] = nil
    return true
end

function AlphaGalAPI.unregisterRedMeat(fullType)
    if type(fullType) ~= "string" then return false end
    AlphaGalAPI.redMeat[fullType] = nil
    return true
end

function AlphaGalAPI.registerWhiteMeat(fullType)
    if type(fullType) ~= "string" or fullType == "" then return false end
    AlphaGalAPI.whiteMeat[fullType] = true
    AlphaGalAPI.redMeat[fullType] = nil
    return true
end

function AlphaGalAPI.unregisterWhiteMeat(fullType)
    if type(fullType) ~= "string" then return false end
    AlphaGalAPI.whiteMeat[fullType] = nil
    return true
end

function AlphaGalAPI.getBaseTriggerStrength(item)
    if not item then return 0 end
    local fullType = getFullType(item)
    if AlphaGalAPI.whiteMeat[fullType] then return 0 end
    if AlphaGalAPI.redMeat[fullType] ~= nil then
        return math.max(0, tonumber(AlphaGalAPI.redMeat[fullType]) or 0)
    end

    local lowerType = string.lower(fullType)
    local foodType = getFoodType(item)

    if whiteFoodTypes[foodType] or containsToken(lowerType, whiteTokens) then
        return 0
    end
    if redFoodTypes[foodType] or containsToken(lowerType, redTokens) then
        return 1.0
    end
    return 0
end

function AlphaGalAPI.isWhiteMeat(item)
    if not item then return false end
    local fullType = getFullType(item)
    if AlphaGalAPI.whiteMeat[fullType] then return true end
    local foodType = getFoodType(item)
    if whiteFoodTypes[foodType] then return true end
    return containsToken(string.lower(fullType), whiteTokens)
end

function AlphaGalAPI.isRedMeat(item)
    return AlphaGalAPI.getBaseTriggerStrength(item) > 0
end

function AlphaGalAPI.getStoredContamination(item)
    if not item then return 0 end
    local ok, modData = pcall(function() return item:getModData() end)
    if not ok or not modData then return 0 end
    return math.max(0, tonumber(modData.alphaGalContamination) or 0)
end

function AlphaGalAPI.getContamination(item)
    if not item then return 0 end
    local stored = AlphaGalAPI.getStoredContamination(item)
    if stored > 0 then return stored end
    return AlphaGalAPI.getBaseTriggerStrength(item)
end

function AlphaGalAPI.setContamination(item, amount)
    if not item then return false end
    local value = math.max(0, tonumber(amount) or 0)
    local ok, modData = pcall(function() return item:getModData() end)
    if not ok or not modData then return false end
    modData.alphaGalContamination = value
    return true
end

function AlphaGalAPI.addContamination(item, amount)
    if not item then return false end
    return AlphaGalAPI.setContamination(item, AlphaGalAPI.getStoredContamination(item) + math.max(0, tonumber(amount) or 0))
end

function AlphaGalAPI.propagate(inputs, outputs)
    local total = 0
    listEach(inputs, function(item)
        total = total + AlphaGalAPI.getContamination(item)
    end)
    if total <= 0 then return 0 end

    local foodOutputs = {}
    listEach(outputs, function(item)
        local ok, isFood = pcall(function() return item:IsFood() end)
        if ok and isFood then
            table.insert(foodOutputs, item)
        end
    end)
    if #foodOutputs == 0 then return 0 end

    local share = total / #foodOutputs
    for i = 1, #foodOutputs do
        local item = foodOutputs[i]
        local inherited = math.max(AlphaGalAPI.getStoredContamination(item), AlphaGalAPI.getBaseTriggerStrength(item), share)
        AlphaGalAPI.setContamination(item, inherited)
    end
    return total
end

function AlphaGalAPI.propagateCraftRecipe(craftRecipeData)
    if not craftRecipeData then return 0 end
    local okInputs, inputs = pcall(function()
        local recorded = craftRecipeData:getAllRecordedConsumedItems()
        if recorded and recorded:size() > 0 then return recorded end
        return craftRecipeData:getAllConsumedItems()
    end)
    local okOutputs, outputs = pcall(function() return craftRecipeData:getAllCreatedItems() end)
    if not okInputs or not okOutputs then return 0 end
    return AlphaGalAPI.propagate(inputs, outputs)
end

function AlphaGalAPI.registerVomitingHandler(handler)
    if type(handler) ~= "function" then return false end
    table.insert(AlphaGalAPI.vomitingHandlers, handler)
    return true
end

function AlphaGalAPI.triggerVomitingHandlers(player, severity)
    for i = 1, #AlphaGalAPI.vomitingHandlers do
        pcall(AlphaGalAPI.vomitingHandlers[i], player, severity)
    end
end

function AlphaGalAPI.getExposureForBite(item, fraction)
    local amount = clamp(tonumber(fraction) or 0, 0, 1)
    return AlphaGalAPI.getContamination(item) * amount
end

local defaults = {
    ["Base.Beef"] = 1.0,
    ["Base.Steak"] = 1.0,
    ["Base.Burger"] = 1.0,
    ["Base.Hamburger"] = 1.0,
    ["Base.MeatPatty"] = 1.0,
    ["Base.GroundBeef"] = 1.0,
    ["Base.PorkChop"] = 1.0,
    ["Base.Bacon"] = 1.0,
    ["Base.Ham"] = 1.0,
    ["Base.Sausage"] = 1.0,
    ["Base.Salami"] = 1.0,
    ["Base.Pepperoni"] = 1.0,
    ["Base.Lamb"] = 1.0,
    ["Base.MuttonChop"] = 1.0,
    ["Base.Venison"] = 1.0,
    ["Base.Rabbitmeat"] = 1.0,
}

for fullType, strength in pairs(defaults) do
    if AlphaGalAPI.redMeat[fullType] == nil and not AlphaGalAPI.whiteMeat[fullType] then
        AlphaGalAPI.redMeat[fullType] = strength
    end
end
