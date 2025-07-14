local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Clock = require(ReplicatedStorage.Packages.Clock)
local LifetimeObject = require(ReplicatedStorage.Shared.System.LifetimeObject)
local Net = require(ReplicatedStorage.Client.Net)

--// Type Definitions //--
export type CountdownLights = {
	Light1: Frame,
	Light2: Frame,
	Light3: Frame,
	Light4: Frame,
}

export type Countdown = {
	ScreenGui: ScreenGui,
	CountdownLights: CountdownLights,
}

local countdownUI: Countdown = nil
local localPlayer = Players.LocalPlayer
local currentCountdownStep: number = 0
local lights: { Frame } = {}
local StopClock: () -> () = nil

local StartCountdownUIController = {}

local redLightColors = {
	off = Color3.fromRGB(85, 0, 0),
	on = Color3.fromRGB(174, 14, 14),
}

local greenLightColors = {
	off = Color3.fromRGB(0, 85, 0),
	on = Color3.fromRGB(14, 174, 14),
}

--------------------------------------------------------------------------------
--// Private Functions //--
--------------------------------------------------------------------------------

local function ToggleLightForStep(step: number)
	if step == #lights then
		lights[step].BackgroundColor3 = greenLightColors.on
	else
		lights[step].BackgroundColor3 = redLightColors.on
	end
end

local function ResetLights()
	for i, light in ipairs(lights) do
		if i == #lights then
			light.BackgroundColor3 = greenLightColors.off
		else
			light.BackgroundColor3 = redLightColors.off
		end
	end
end

local function OnCountdownStarted()
	StartCountdownUIController:ToggleUI(true)
end

local function OnCountdownEnded()
	StartCountdownUIController:ToggleUI(false)
	ResetLights()
end

local function OnCountdownChanged()
	currentCountdownStep += 1
	if currentCountdownStep <= #lights then
		ToggleLightForStep(currentCountdownStep)
	else
		StopClock()
		OnCountdownEnded()
	end
end

local function GetUI()
	countdownUI = {
		ScreenGui = nil,
		CountdownLights = {
			Light1 = nil,
			Light2 = nil,
			Light3 = nil,
			Light4 = nil,
		},
	}

	local playerGui = localPlayer:WaitForChild("PlayerGui")
	countdownUI.ScreenGui = playerGui:WaitForChild("StartCountdown")
	local configuration = countdownUI.ScreenGui:WaitForChild("Configuration") :: Configuration

	local countdownLight1Value = configuration.Light1 :: ObjectValue
	countdownUI.CountdownLights.Light1 = countdownLight1Value.Value :: Frame
	table.insert(lights, countdownUI.CountdownLights.Light1)
	local countdownLight2Value = configuration.Light2 :: ObjectValue
	countdownUI.CountdownLights.Light2 = countdownLight2Value.Value :: Frame
	table.insert(lights, countdownUI.CountdownLights.Light2)
	local countdownLight3Value = configuration.Light3 :: ObjectValue
	countdownUI.CountdownLights.Light3 = countdownLight3Value.Value :: Frame
	table.insert(lights, countdownUI.CountdownLights.Light3)
	local countdownLight4Value = configuration.Light4 :: ObjectValue
	countdownUI.CountdownLights.Light4 = countdownLight4Value.Value :: Frame
	table.insert(lights, countdownUI.CountdownLights.Light4)

	-- Validation
	assert(countdownUI.ScreenGui.ResetOnSpawn == false, "UI should not reset on spawn")
end

function StartCountdownUIController:ToggleUI(toggle: boolean)
	countdownUI.ScreenGui.Enabled = toggle or false
end
--------------------------------------------------------------------------------
--// Module Functions //--
--------------------------------------------------------------------------------
function StartCountdownUIController:OnAwake()
	if not countdownUI then
		GetUI()
	end

	StartCountdownUIController:ToggleUI(false)
end

function StartCountdownUIController:OnStart()
	local function onTrackStartedCountdown()
		print("INITIALIZED TIMER!!!!")
		OnCountdownStarted()
		StopClock = Clock(1, OnCountdownChanged)
	end

	Net.RaceCountdownStarted.On(onTrackStartedCountdown)
end

return LifetimeObject.extend(StartCountdownUIController, "StartCountdownUIController")
