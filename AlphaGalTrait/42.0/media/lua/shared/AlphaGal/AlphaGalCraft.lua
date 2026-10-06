require "AlphaGal/AlphaGalAPI"

local function hungerAmount(item)
    if not item then return 0 end
    local ok, value = pcall(function() return math.abs(item:getHungerChange()) end)
    if not ok then return 0 end
    return tonumber(value) or 0
end

local function baseHungerAmount(item)
    if not item then return 0 end
    local ok, value = pcall(function() return math.abs(item:getBaseHunger()) end)
    if not ok then return 0 end
    return tonumber(value) or 0
end

local function clamp(value, low, high)
    if value < low then return low end
    if value > high then return high end
    return value
end

local okAdd = pcall(require, "TimedActions/ISAddItemInRecipe")
if okAdd and ISAddItemInRecipe and not AlphaGalAddItemRecipePatched then
    AlphaGalAddItemRecipePatched = true
    local originalAddComplete = ISAddItemInRecipe.complete

    function ISAddItemInRecipe:complete()
        local usedItem = self.usedItem
        local contamination = AlphaGalAPI.getContamination(usedItem)
        local beforeHunger = hungerAmount(usedItem)
        local baseHunger = baseHungerAmount(usedItem)
        local result = originalAddComplete(self)

        if contamination > 0 and self.baseItem then
            local fraction = 1
            if baseHunger > 0 then
                local afterHunger = hungerAmount(usedItem)
                local stillExists = usedItem and usedItem:getContainer() ~= nil
                if stillExists then
                    fraction = clamp((beforeHunger - afterHunger) / baseHunger, 0, 1)
                else
                    fraction = clamp(beforeHunger / baseHunger, 0, 1)
                end
                if fraction <= 0 then fraction = 1 end
            end
            AlphaGalAPI.addContamination(self.baseItem, contamination * fraction)
            if sendItemStats then
                sendItemStats(self.baseItem)
            end
        end
        return result
    end
end

local okCraft = pcall(require, "TimedActions/ISCraftAction")
if okCraft and ISCraftAction and not AlphaGalLegacyCraftPatched then
    AlphaGalLegacyCraftPatched = true

    function ISCraftAction:complete()
        local fromFloor = false
        if self.container:getType() == "floor" then fromFloor = true end

        local inputItems = nil
        pcall(function()
            inputItems = RecipeManager.getAvailableItemsNeeded(self.recipe, self.character, self.containers, self.item, nil)
        end)

        local list = RecipeManager.PerformMakeItem(self.recipe, self.item, self.character, self.containers)
        if list then
            AlphaGalAPI.propagate(inputItems, list)
            for i = 0, list:size() - 1 do
                local item = list:get(i)
                if fromFloor then
                    self.character:getCurrentSquare():AddWorldInventoryItem(
                        item,
                        self.character:getX() - math.floor(self.character:getX()) + ZombRandFloat(0.1, 0.5),
                        self.character:getY() - math.floor(self.character:getY()) + ZombRandFloat(0.1, 0.5),
                        self.character:getZ() - math.floor(self.character:getZ())
                    )
                    self.container:AddItem(item)
                else
                    Actions.addOrDropItem(self.character, item)
                end
            end
        end
        return true
    end
end
