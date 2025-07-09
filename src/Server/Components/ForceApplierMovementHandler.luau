local ForceApplierMovementHandler = {}

local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local Net = require(ServerScriptService.Server.Net)

local forceAppliers: { Model } = CollectionService:GetTagged("ForceApplier")
local forceAppliersInfos = {}

local animationDuration = 0.5
local timeToGoBack = 1

local function SetupForceApplierAnimationVariables(forceApplier: Model, forceApplierID: number)
	local collision = forceApplier:FindFirstChild("Collision") :: BasePart
	local endPosition = forceApplier:FindFirstChild("EndPosition") :: BasePart

	local forceApplierInfo = {}

	forceApplierInfo.applyingForce = false
	forceApplierInfo.positionBase = collision.CFrame.Position
	forceApplierInfo.positionApplyingForce = endPosition.CFrame.Position

	forceAppliersInfos[forceApplierID] = forceApplierInfo
end

local function MakeForceApplierCollidersTransparent(forceApplier: Model)
	local trigger = forceApplier:FindFirstChild("Trigger") :: BasePart
	local endPosition = forceApplier:FindFirstChild("EndPosition") :: BasePart

	trigger.Transparency = 1
	endPosition.Transparency = 1
end

local function SetupForceAppliers()
	for i, forceApplier in ipairs(forceAppliers) do
		SetupForceApplierAnimationVariables(forceApplier, i)
		MakeForceApplierCollidersTransparent(forceApplier)

		forceApplier:SetAttribute("ID", i)
	end
end

local function MoveForceApplierToPosition(forceApplier: Model, _position: Vector3, _time: number)
	local collision = forceApplier:FindFirstChild("Collision") :: BasePart
	local tweenInfo = TweenInfo.new(_time)
	local endValues = { CFrame = CFrame.new(_position) * collision.CFrame.Rotation }

	local tween = TweenService:Create(collision, tweenInfo, endValues)

	tween:Play()
end

local function MakeForceApplierApplyForce(forceApplier: Model, forceApplierInfo)
	if forceApplierInfo.applyingForce == true then
		return
	end

	forceApplierInfo.applyingForce = true

	MoveForceApplierToPosition(forceApplier, forceApplierInfo.positionApplyingForce, animationDuration)

	wait(animationDuration + timeToGoBack)

	MoveForceApplierToPosition(forceApplier, forceApplierInfo.positionBase, animationDuration)

	wait(animationDuration + timeToGoBack)

	forceApplierInfo.applyingForce = false
end

local function GetForceApplier(forceApplierID: number)
	if forceApplierID < 1 or forceApplierID > #forceAppliers then
		warn(`O ID \"{forceApplierID}\" esta fora do intervalo da lista!`)
		return nil
	end

	return forceAppliers[forceApplierID]
end

local function GetForceApplierInfo(forceApplierID: number)
	if forceApplierID < 1 or forceApplierID > #forceAppliersInfos then
		warn(`O ID \"{forceApplierID}\" esta fora do intervalo da lista!`)
		return nil
	end

	return forceAppliersInfos[forceApplierID]
end

local function OnPlayerCollidedWithForceApplier(_: Player, forceApplierID: number)
	local forceApplier = GetForceApplier(forceApplierID)
	local forceApplierInfo = GetForceApplierInfo(forceApplierID)

	if forceApplier == nil or forceApplierInfo == nil then
		return
	end

	MakeForceApplierApplyForce(forceApplier, forceApplierInfo)
end

local function Initialize()
	SetupForceAppliers()

	Net.PlayerCollidedWithForceApplier.On(OnPlayerCollidedWithForceApplier)
end

Initialize()

return ForceApplierMovementHandler
