local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LifetimeObject = require(ReplicatedStorage.Shared.System.LifetimeObject)

local TooltipUI = {}

export type TooltipUI = {
	ScreenGui: ScreenGui,
	TooltipTitle: TextLabel,
	TooltipDescription: TextLabel,
}

export type TooltipKind = "Central"

local tooltipUI: TooltipUI
local localPlayer = Players.LocalPlayer

--------------------------------------------------------------------------------
--// Private Functions //--
--------------------------------------------------------------------------------
local function GetUI()
	tooltipUI = {
		ScreenGui = nil,
		TooltipTitle = nil,
		TooltipDescription = nil,
	}

	local playerGui = localPlayer:WaitForChild("PlayerGui")
	tooltipUI.ScreenGui = playerGui:WaitForChild("Tooltip")

	local configuration = tooltipUI.ScreenGui:WaitForChild("Configuration")
	local tooltipTitleValue = configuration:WaitForChild("TooltipTitle", 2) :: ObjectValue
	tooltipUI.TooltipTitle = tooltipTitleValue.Value :: TextLabel
	local tooltipDescriptionValue = configuration:WaitForChild("TooltipDescription", 2) :: ObjectValue
	tooltipUI.TooltipDescription = tooltipDescriptionValue.Value :: TextLabel

	-- Validation
	assert(tooltipUI.ScreenGui.ResetOnSpawn == false, "UI should not reset on spawn")
end

--------------------------------------------------------------------------------
--// Module //--
--------------------------------------------------------------------------------
function TooltipUI:OnAwake()
	if not tooltipUI then
		GetUI()
	end
end

function TooltipUI:Show(title: string, description: string, tooltipKind: TooltipKind?)
	tooltipKind = tooltipKind or "Central"
	tooltipUI.ScreenGui.Enabled = true
	tooltipUI.TooltipTitle.Text = title
	tooltipUI.TooltipDescription.Text = description
end

function TooltipUI:Hide()
	tooltipUI.ScreenGui.Enabled = false
end

return LifetimeObject.extend(TooltipUI, "TooltipUI")
