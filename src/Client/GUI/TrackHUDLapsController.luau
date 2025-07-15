--// Services //--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports //--
local LifetimeObject = require(ReplicatedStorage.Shared.System.LifetimeObject)
local Net = require(ReplicatedStorage.Client.Net)
local TrackHUD = require(ReplicatedStorage.Client.GUI.TrackHUD)

--// Constants //--
local PRE_LAPS_STRING = "/ "
local TEST_LAPS = 10 -- TODO: Change this to the actual number of laps in the game

local TrackHUDLapsController = {}

local lapsTexts: TrackHUD.LapsTexts
local currentLap = 1

local function OnLapChanged()
	currentLap += 1
	lapsTexts.CurrentLap.Text = tostring(currentLap)
end

local function OnRaceStarted()
	lapsTexts.TotalLaps.Text = tostring(PRE_LAPS_STRING .. tostring(TEST_LAPS))
end

function TrackHUDLapsController:OnStart()
	lapsTexts = TrackHUD:GetLapsTexts()

	assert(lapsTexts, "Placement texts were not found")

	Net.RaceStarted.On(OnRaceStarted)
	Net.PlayerReachedFinishLine.On(OnLapChanged)
end

return LifetimeObject.extend(TrackHUDLapsController, "TrackHUDLapsController")
