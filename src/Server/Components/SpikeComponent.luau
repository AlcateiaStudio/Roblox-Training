local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TIME_OUT = 2
local DAMAGE = 20

local Net = require(ServerScriptService.Server.Net)
local Component = require(ReplicatedStorage.Packages.Component)

local AreaDetectorComponent = require(ServerScriptService.Server.Components.AreaDetectorComponent)

local SpikeComponent = Component.new({ Tag = "Spike", Extensions = {} })

local function onCharacterAdded_GetNecessaryPartsToTrack(player: Player, character: Model)
	return nil --TODO: Retornar aqui quais partes você quer trackear
end

function SpikeComponent:Start()
	AreaDetectorComponent:WaitForInstance(self.Instance, TIME_OUT)
		:andThen(function(component)
			print("Spike contains a valid area detector component: ", component)
			self.spikeAreaDetector = component
			self.spikeAreaDetector.Signals.OnCharacterAdded:Connect(onCharacterAdded_GetNecessaryPartsToTrack)
			self:SetUpAreaDetectorEvents()
		end)
		:catch(function(err)
			warn("SpikeComponent failed to find AreaDetectorComponent in instance:", self.Instance, err)
			return nil
		end)
end

function SpikeComponent:SetUpAreaDetectorEvents()
	self.spikeAreaDetector.Signals.Entered:Connect(function(player: Player)
		self:ReduceHP(player)
	end)
end

function SpikeComponent:ReduceHP(player: Player)
	local character: Model? = player.Character
	if character == nil then
		warn("Player character not found for player:", player.Name)
		return
	end

	print(`SpikeComponent: Reducing HP for player {player.Name}`)
	Net.PlayerCollidedWithSpike.Fire(player, DAMAGE)
end

function SpikeComponent:Stop() end

return SpikeComponent
