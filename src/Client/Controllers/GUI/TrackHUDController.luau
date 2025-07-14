local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LifetimeObject = require(ReplicatedStorage.Shared.System.LifetimeObject)

--// Type Definitions //--
export type Hud = {
	ScreenGui: ScreenGui,
	Coins: TextLabel,
	Placement: PlacementTexts,
	Speed: TextLabel,
	Timer: TimerTexts,
	TrackImage: ImageLabel,
}

export type TimerTexts = {
	Minutes: TextLabel,
	Seconds: TextLabel,
	Milliseconds: TextLabel,
}

export type PlacementTexts = {
	Placement: TextLabel,
	Ending: TextLabel,
}

local hud: Hud = nil
local localPlayer = Players.LocalPlayer

local TrackHUDController = {}

function TrackHUDController:OnAwake()
	if not hud then
		TrackHUDController:GetUI()
	end
end

function TrackHUDController:GetUI()
	hud = {
		ScreenGui = nil,
		Coins = nil,
		Placement = nil,
		Speed = nil,
		Timer = nil,
		TrackImage = nil,
	}

	local playerGui = localPlayer:WaitForChild("PlayerGui")
	hud.ScreenGui = playerGui:WaitForChild("TrackHUD")
	local configuration = hud.ScreenGui:WaitForChild("Configuration") :: Configuration
	local minutes = configuration:WaitForChild("MinutesText") :: ObjectValue
	local seconds = configuration:WaitForChild("SecondsText") :: ObjectValue
	local milliseconds = configuration:WaitForChild("MiliSecondsText") :: ObjectValue
	hud.Timer = {
		Minutes = minutes.Value :: TextLabel,
		Seconds = seconds.Value :: TextLabel,
		Milliseconds = milliseconds.Value :: TextLabel,
	}

	local trackImage = configuration:WaitForChild("TrackImage") :: ObjectValue
	hud.TrackImage = trackImage.Value :: ImageLabel

	local placementText = configuration:WaitForChild("PlacementNumberText") :: ObjectValue
	local placementEndingText = configuration:WaitForChild("PlacementEndingSymbolText") :: ObjectValue
	hud.Placement = {
		Placement = placementText.Value :: TextLabel,
		Ending = placementEndingText.Value :: TextLabel,
	}

	-- Validation
	assert(hud.ScreenGui.ResetOnSpawn == false, "UI should not reset on spawn")
end

function TrackHUDController:GetTimeTexts(): TimerTexts
	if not hud then
		self:GetUI()
	end

	return hud.Timer
end

function TrackHUDController:GetTrackImage(): ImageLabel
	if not hud then
		self:GetUI()
	end

	return hud.TrackImage
end

function TrackHUDController:GetPlacementTexts(): PlacementTexts
	if not hud then
		self:GetUI()
	end

	return hud.Placement
end

return LifetimeObject.extend(TrackHUDController, "TrackHUDController")
