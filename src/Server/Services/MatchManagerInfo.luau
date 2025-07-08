MatchManagerInfo = {}
local UID = 0
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerNet = require(ServerScriptService.Server.Net)

local COIN_TAG = "Coin"
local inactiveCoins = {}
local taggedModels = CollectionService:GetTagged(COIN_TAG) :: { Model }
local offsetValue = Vector3.new(0, 1000, 0)

local function CreateUID()
	UID += 1
	return UID
end

function MatchManagerInfo:Start()
	for _, coin in ipairs(taggedModels) do
		local uid = CreateUID()
		coin:SetAttribute("UID", uid)
	end

	local function localFunction(...)
		self:PlayerCollidedWithCoin(...)
	end

	ServerNet.SendCoinsOnPlayerEntered.On(localFunction)
end

function MatchManagerInfo:PlayerCollidedWithCoin(_, uid: string)
	for _, coin in ipairs(inactiveCoins) do
		if coin == uid then
			return
		end
	end

	table.insert(inactiveCoins, uid)
	self:CoinCollectedEvent(uid)
end

function MatchManagerInfo:CoinCollectedEvent(index: number)
	self:MoveCoin(index, true)
end

function MatchManagerInfo:MoveCoin(index: number, disapear: boolean)
	local model = taggedModels[index]
	local pos = model:GetPivot()
	local offsetPosition = offsetValue
	if disapear == true then
		offsetPosition = offsetValue * -1
	end
	model:PivotTo(pos + offsetPosition)
end

return MatchManagerInfo
