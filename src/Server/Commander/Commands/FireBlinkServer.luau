local ServerScriptService = game:GetService("ServerScriptService")
return function(context, blinkEventName: string, player: Player, numberArgs: number?)
	local Net = require(ServerScriptService.Server.Net)
	local blinkEvent = Net[blinkEventName]
	print("Testing blink event:", blinkEventName)
	if not blinkEvent then
		error("Blink event '" .. blinkEventName .. "' does not exist.")
	end
	blinkEvent.Fire(player, numberArgs)
end
