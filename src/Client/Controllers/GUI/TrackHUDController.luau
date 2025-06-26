local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LifetimeObject = require(ReplicatedStorage.Shared.System.LifetimeObject)
local Timer = require(ReplicatedStorage.Shared.Utils.Timer)

--// Type Definitions //--
export type Hud = {
	ScreenGui: ScreenGui,
	Coins: TextLabel,
	Placement: TextLabel,
	Speed: TextLabel,
	Timer: TimerTexts,
}

export type TimerTexts = {
	Minutes: TextLabel,
	Seconds: TextLabel,
	Milliseconds: TextLabel,
}

local hud: Hud = nil
local localPlayer = Players.LocalPlayer

-- Create the controller object first
local TrackHUDController = {}

function TrackHUDController:OnAwake()
	if not hud then
		TrackHUDController:GetUI()
	end

	local function onTimerChange(timer: number)
		hud.Timer.Minutes.Text = string.format("%02d", math.floor(timer / 60))
		hud.Timer.Seconds.Text = string.format("%02d", math.floor(timer % 60))
		hud.Timer.Milliseconds.Text = string.format("%02d", math.floor((timer % 1) * 100))
	end

	self.trackClock = Timer.new(nil, nil, onTimerChange, "Timer", false)
	self.trackClock:StartTimer(0)
end

function TrackHUDController:OnStart() end

function TrackHUDController:OnDestroy() end

function TrackHUDController:GetUI()
	hud = {
		ScreenGui = nil,
		Coins = nil,
		Placement = nil,
		Speed = nil,
		Timer = nil,
	}

	local playerGui = localPlayer:WaitForChild("PlayerGui")
	hud.ScreenGui = playerGui:WaitForChild("TrackHUD")
	local configuration = hud.ScreenGui:WaitForChild("Configuration") :: Configuration
	local Minutes = configuration:WaitForChild("MinutesText") :: ObjectValue
	local Seconds = configuration:WaitForChild("SecondsText") :: ObjectValue
	local Milliseconds = configuration:WaitForChild("MiliSecondsText") :: ObjectValue
	hud.Timer = {
		Minutes = Minutes.Value :: TextLabel,
		Seconds = Seconds.Value :: TextLabel,
		Milliseconds = Milliseconds.Value :: TextLabel,
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

return LifetimeObject.extend(TrackHUDController, "TrackHUDController")
