local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataService = require(ServerScriptService.Server.Services.PlayerDataService)

return function(context, player: Player)
	PlayerDataService:WipePlayerData(player)
	return "Deleted Data Store"
end
