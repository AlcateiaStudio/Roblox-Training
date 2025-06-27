local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Net = require(ServerScriptService.Server.Net)
local Component = require(ReplicatedStorage.Packages.Component)

local AreaDetectorComponent = require(ServerScriptService.Server.Components.AreaDetectorComponent)
local ObjectThatCausesDamageComponent = Component.new({ Tag = "ObjectThatCausesDamage", Extensions = {} })

local timeOut = 2
local collisionBodyPartsNames = { "LeftFoot", "RightFoot" }

local function OnCharacterAdded_GetNecessaryPartsToTrack(player: Player, character: Model)
	local partsToTrack: { BasePart } = {}

	for i, v in pairs(collisionBodyPartsNames) do
		local collisionBodyPart = character:FindFirstChild(v)

		if collisionBodyPart:IsA("BasePart") then
			table.insert(partsToTrack, collisionBodyPart)
		else
			warn(`O objeto com nome \"{v}\" nao e uma BasePart!`)
		end
	end

	return partsToTrack
end

function ObjectThatCausesDamageComponent:Start()
	AreaDetectorComponent:WaitForInstance(self.Instance, timeOut)
		:andThen(function(component)
			self.areaDetector = component
			self.areaDetector.Signals.OnCharacterAdded:Connect(OnCharacterAdded_GetNecessaryPartsToTrack)

			self:SetUpAreaDetectorEvents()
		end)
		:catch(function(err)
			warn("ObjectThatCausesDamage failed to find AreaDetectorComponent in instance:", self.Instance, err)

			return nil
		end)
end

function ObjectThatCausesDamageComponent:Stop() end

function ObjectThatCausesDamageComponent:SetUpAreaDetectorEvents()
	self.areaDetector.Signals.Entered:Connect(function(player: Player)
		self:CauseDamage(player)
	end)
end

function ObjectThatCausesDamageComponent:CauseDamage(player: Player)
	local character: Model? = player.Character

	if character == nil then
		warn("Player character not found for player:", player.Name)

		return
	end

	print(`ObjectThatCausesDamage: causing damage to player {player.Name}`)

	--TODO: calcular direcao do knockback
	Net.PlayerTakeDamage.Fire(player, Vector3.zero)
end

return ObjectThatCausesDamageComponent
