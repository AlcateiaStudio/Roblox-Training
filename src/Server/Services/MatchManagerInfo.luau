MatchManagerInfo = {}

local CoinID = 0
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerNet = require(ServerScriptService.Server.Net)

local COIN_TAG = "Coin"

local inactiveCoins = {}
local CoinCollections = {}
local taggedCoinModels = CollectionService:GetTagged(COIN_TAG) :: { Model }

local offsetValue = Vector3.new(0, 1000, 0)
local MatchManagerModule = require(ServerScriptService.Server.Services.MatchManagerModule)

local function CreateIDCoin()
	CoinID += 1
	return CoinID
end

function MatchManagerInfo:Start()
	for _, coin in ipairs(taggedCoinModels) do
		local uid = CreateIDCoin()
		coin:SetAttribute("UID", uid)
		table.insert(CoinCollections, coin:GetPivot())
	end

	local function localPlayerCollideWithCoins(...)
		self:PlayerCollidedWithCoin(...)
	end

	local function ActiveCoins(...)
		self:ToogleCoins(false)
		table.clear(inactiveCoins)
	end

	local function DeactiveCoins(...)
		self:ToogleCoins(true)
	end

	ServerNet.SendCoinsOnPlayerEntered.On(localPlayerCollideWithCoins)
	MatchManagerModule.OnPlayersTeleportedToStartRace:Connect(ActiveCoins)
	MatchManagerModule.OnLastPlayerCrossedFinishLine:Connect(DeactiveCoins)

	DeactiveCoins()
end

function MatchManagerInfo:ToogleCoins(active: boolean)
	for index, _ in ipairs(taggedCoinModels) do
		self:MoveCoin(index, active)
	end
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
	local model = taggedCoinModels[index]
	local pos = CoinCollections[index]
	if disapear == true then
		model:PivotTo(pos + offsetValue)
	else
		model:PivotTo(pos)
	end
end

return MatchManagerInfo
