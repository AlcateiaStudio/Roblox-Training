MatchManagerRunController = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ServerNet = require(ServerScriptService.Server.Net)

local PlayerTable = {}

function MatchManagerRunController:Start()
	local function OnPlayerReachedCheckpoint(...)
		self:PlayerReachedCheckpoint(...)
	end
	ServerNet.PlayerReacheadNewCheckpoint.On(OnPlayerReachedCheckpoint)
end

function MatchManagerRunController:PlayerReachedCheckpoint(_player: Player, index: number)
	for _, playerTable in pairs(PlayerTable) do
		if playerTable.player == _player then
			playerTable.checkpoint = index
			print(`Player :{playerTable.player} Checkpoint :{playerTable.checkpoint}, Lap :{playerTable.lap}`)
			break
		end
	end
end

function MatchManagerRunController:PlayerReachedFinishLine(player: Player)
	ServerNet.PlayerReachedFinishLine.Fire(player)
end

function MatchManagerRunController:OnPlayerEnter(_player: Player)
	local playerTable = { player = _player, checkpoint = 0, lap = 0 }
	table.insert(PlayerTable, playerTable)
end

function MatchManagerRunController:GetPlayerTable(_player: Player)
	for _, playerTable in pairs(PlayerTable) do
		if playerTable.player == _player then
			return playerTable
		end
	end
	return
end

function MatchManagerRunController:CleanAllPlayers()
	PlayerTable = {}
end

return MatchManagerRunController
