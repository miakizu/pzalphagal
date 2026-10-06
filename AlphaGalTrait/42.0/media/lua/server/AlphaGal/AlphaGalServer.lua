require "AlphaGal/AlphaGalCore"

local function onClientCommand(module, command, player, args)
    if module ~= "AlphaGalTrait" or command ~= "consume" then return end
    if not player or not args then return end
    local dose = math.max(0, math.min(4, tonumber(args.dose) or 0))
    if dose > 0 then
        AlphaGalCore.consume(player, dose)
    end
end

Events.OnClientCommand.Add(onClientCommand)
Events.EveryOneMinute.Add(AlphaGalCore.onMinute)
Events.OnTick.Add(AlphaGalCore.onTick)
