local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LifetimeObject = require(ReplicatedStorage.Shared.System.LifetimeObject)
local PlacementEndingStrings = require(ReplicatedStorage.Shared.Data.PlacementEndingStrings)
local TrackHUD = require(ReplicatedStorage.Client.GUI.TrackHUD)

local Net = require(ReplicatedStorage.Client.Net)

local TrackHUDPlacementController = {}

local placementNumberTexts: TrackHUD.PlacementTexts

local function OnPlacementChanged(placement: number)
	placementNumberTexts.Placement.Text = tostring(placement)
	placementNumberTexts.Ending.Text = PlacementEndingStrings.GetEnding(placement)
end

function TrackHUDPlacementController:OnStart()
	placementNumberTexts = TrackHUD:GetPlacementTexts()

	assert(placementNumberTexts, "Placement texts were not found")

	Net.PlayerPlacementChanged.On(OnPlacementChanged)
end

return LifetimeObject.extend(TrackHUDPlacementController, "TrackHUDPlacementController")
