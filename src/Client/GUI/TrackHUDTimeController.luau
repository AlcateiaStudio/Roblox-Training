local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LifetimeObject = require(ReplicatedStorage.Shared.System.LifetimeObject)
local TrackHUD = require(ReplicatedStorage.Client.GUI.TrackHUD)

local Net = require(ReplicatedStorage.Client.Net)
local Timer = require(ReplicatedStorage.Shared.Utils.Timer)

local TrackHUDTimeController = {}

function TrackHUDTimeController:OnStart()
	Net.RaceStarted.On(function()
		TrackHUDTimeController:OnRaceStarted()
	end)
end

function TrackHUDTimeController:OnRaceStarted()
	local timerTexts = TrackHUD:GetTimeTexts()

	local function onTimerChange(timer: number)
		timerTexts.Minutes.Text = string.format("%02d", math.floor(timer / 60))
		timerTexts.Seconds.Text = string.format("%02d", math.floor(timer % 60))
		timerTexts.Milliseconds.Text = string.format("%02d", math.floor((timer % 1) * 100))
	end

	self.trackClock = Timer.new(nil, nil, onTimerChange, "Timer", false)
	self.trackClock:StartTimer(0)
end

return LifetimeObject.extend(TrackHUDTimeController, "TrackHUDTimeController")
