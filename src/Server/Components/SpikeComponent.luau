local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TIME_OUT = 2
local DAMAGE = 20

local Net = require(ServerScriptService.Server.Net)
local Component = require(ReplicatedStorage.Packages.Component)

local AreaDetectorComponent = require(ServerScriptService.Server.Components.AreaDetectorComponent)

local SpikeComponent = Component.new({ Tag = "Spike", Extensions = {} })

function SpikeComponent:Start()
	AreaDetectorComponent:WaitForInstance(self.instance, TIME_OUT)
		:andThen(function(component)
			print("Spike contains a valid area detector component: ", component)
			self.spikeAreaDetector = component
			self:SetUpAreaDetectorEvents()
		end)
		:catch(function(err)
			warn("SpikeComponent failed to find AreaDetectorComponent in instance:", self.instance, err)
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

	Net.PlayerCollidedWithSpike.Fire(player, DAMAGE)
end

function SpikeComponent:Stop() end

return SpikeComponent
