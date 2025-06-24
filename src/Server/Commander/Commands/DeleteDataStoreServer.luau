local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

return function(context, player: Player)
	local PlayerDataService = Knit.GetService("PlayerDataService")
	PlayerDataService:WipePlayerData(player)
	return "Deleted Data Store"
end
