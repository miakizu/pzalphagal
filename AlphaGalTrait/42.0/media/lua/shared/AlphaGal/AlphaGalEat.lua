require "TimedActions/ISEatFoodAction"
require "AlphaGal/AlphaGalAPI"
require "AlphaGal/AlphaGalCore"

if not AlphaGalEatPatched then
    AlphaGalEatPatched = true
    local originalComplete = ISEatFoodAction.complete

    function ISEatFoodAction:complete()
        local item = self.item
        local character = self.character
        local percentage = tonumber(self.percentage) or 0
        local dose = AlphaGalAPI.getExposureForBite(item, percentage)
        local result = originalComplete(self)

        if dose <= 0 or not character or not AlphaGalCore.hasTrait(character) then
            return result
        end

        if isServer() then
            return result
        end

        if isClient() then
            sendClientCommand(character, "AlphaGalTrait", "consume", { dose = dose })
        else
            AlphaGalCore.consume(character, dose)
        end
        return result
    end
end
