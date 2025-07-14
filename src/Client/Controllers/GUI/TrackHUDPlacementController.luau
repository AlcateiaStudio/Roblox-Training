local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LifetimeObject = require(ReplicatedStorage.Shared.System.LifetimeObject)
local PlacementEndingStrings = require(ReplicatedStorage.Shared.Data.PlacementEndingStrings)
local TrackHUDController = require(ReplicatedStorage.Client.Controllers.GUI.TrackHUDController)

local Net = require(ReplicatedStorage.Client.Net)

local TrackHUDPlacementController = {}

local placementNumberTexts: TrackHUDController.PlacementTexts

local function OnPlacementChanged(placement: number)
	placementNumberTexts.Placement.Text = tostring(placement)
	placementNumberTexts.Ending.Text = PlacementEndingStrings.GetEnding(placement)
end

function TrackHUDPlacementController:OnStart()
	placementNumberTexts = TrackHUDController:GetPlacementTexts()

	assert(placementNumberTexts, "Placement texts were not found")

	Net.PlayerPlacementChanged.On(OnPlacementChanged)
end

return LifetimeObject.extend(TrackHUDPlacementController, "TrackHUDPlacementController")
