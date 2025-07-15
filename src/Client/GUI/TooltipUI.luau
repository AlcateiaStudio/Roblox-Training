local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LifetimeObject = require(ReplicatedStorage.Shared.System.LifetimeObject)

local TooltipUI = {}

--// Type Definitions //--
export type TooltipUI = {
	ScreenGui: ScreenGui,
	TooltipTitle: TextLabel,
	TooltipDescription: TextLabel,
	MainFrame: Frame,
}

export type TooltipKind = "Central"

--// Constants //--
local TWEEN_INFO = TweenInfo.new(
	0.5, -- Duration
	Enum.EasingStyle.Quart,
	Enum.EasingDirection.Out,
	0, -- Repeat count
	false, -- Reverses
	0 -- Delay
)

--// Static Vars //--

local tooltipUI: TooltipUI
local localPlayer = Players.LocalPlayer

-- Animation properties
local showPosition: UDim2
local hiddenPosition: UDim2
local currentTween: Tween?
local isAnimating = false
--------------------------------------------------------------------------------
--// Private Functions //--
--------------------------------------------------------------------------------
local function GetUI()
	tooltipUI = {
		ScreenGui = nil,
		TooltipTitle = nil,
		TooltipDescription = nil,
		MainFrame = nil,
	}

	local playerGui = localPlayer:WaitForChild("PlayerGui")
	tooltipUI.ScreenGui = playerGui:WaitForChild("Tooltip")
	tooltipUI.MainFrame = tooltipUI.ScreenGui:FindFirstChild("MainFrame") :: Frame

	local configuration = tooltipUI.ScreenGui:WaitForChild("Configuration")
	local tooltipTitleValue = configuration:WaitForChild("TooltipTitle", 2) :: ObjectValue
	tooltipUI.TooltipTitle = tooltipTitleValue.Value :: TextLabel
	local tooltipDescriptionValue = configuration:WaitForChild("TooltipDescription", 2) :: ObjectValue
	tooltipUI.TooltipDescription = tooltipDescriptionValue.Value :: TextLabel

	-- Set up animation positions
	if tooltipUI.MainFrame then
		-- Store the default position as show position
		showPosition = tooltipUI.MainFrame.Position

		-- Create hidden position (slide down and fade out)
		hiddenPosition = UDim2.new(
			showPosition.X.Scale,
			showPosition.X.Offset,
			showPosition.Y.Scale + 1, -- Move down slightly
			showPosition.Y.Offset -- Add some offset
		)

		-- Start hidden
		tooltipUI.MainFrame.Position = hiddenPosition
		-- tooltipUI.MainFrame.BackgroundTransparency = 1
		-- Make all text transparent initially
		-- if tooltipUI.TooltipTitle then
		-- tooltipUI.TooltipTitle.TextTransparency = 1
		-- end
		-- if tooltipUI.TooltipDescription then
		-- tooltipUI.TooltipDescription.TextTransparency = 1
		-- end
	end

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

	-- Hide the UI initially
	if tooltipUI and tooltipUI.ScreenGui then
		tooltipUI.ScreenGui.Enabled = false
	end
end

local function ShowUIWithAnimation()
	if tooltipUI and tooltipUI.ScreenGui and tooltipUI.MainFrame then
		-- Cancel current tween if it exists
		if currentTween then
			currentTween:Cancel()
			currentTween = nil
		end

		isAnimating = true

		-- Enable the ScreenGui first
		tooltipUI.ScreenGui.Enabled = true

		-- Create tweens for position and transparency
		local positionTween = TweenService:Create(tooltipUI.MainFrame, TWEEN_INFO, {
			Position = showPosition,
			-- BackgroundTransparency = 0,
		})

		-- local titleTween = TweenService:Create(tooltipUI.TooltipTitle, TWEEN_INFO, {
		-- 	TextTransparency = 0,
		-- })

		-- local descriptionTween = TweenService:Create(tooltipUI.TooltipDescription, TWEEN_INFO, {
		-- 	TextTransparency = 0,
		-- })

		currentTween = positionTween

		-- Play all tweens
		positionTween:Play()
		-- titleTween:Play()
		-- descriptionTween:Play()

		-- Handle tween completion
		positionTween.Completed:Connect(function(playbackState)
			isAnimating = false
			if currentTween == positionTween then
				currentTween = nil
			end
		end)
	end
end

local function HideUIWithAnimation()
	if tooltipUI and tooltipUI.ScreenGui and tooltipUI.MainFrame then
		-- Cancel current tween if it exists
		if currentTween then
			currentTween:Cancel()
			currentTween = nil
		end

		isAnimating = true

		-- Create tweens for position and transparency
		local positionTween = TweenService:Create(tooltipUI.MainFrame, TWEEN_INFO, {
			Position = hiddenPosition,
			BackgroundTransparency = 1,
		})

		-- local titleTween = TweenService:Create(tooltipUI.TooltipTitle, TWEEN_INFO, {
		-- 	TextTransparency = 1,
		-- })

		-- local descriptionTween = TweenService:Create(tooltipUI.TooltipDescription, TWEEN_INFO, {
		-- 	TextTransparency = 1,
		-- })

		currentTween = positionTween

		-- Play all tweens
		positionTween:Play()
		-- titleTween:Play()
		-- descriptionTween:Play()

		-- Handle tween completion
		positionTween.Completed:Connect(function(playbackState)
			if playbackState == Enum.PlaybackState.Completed then
				tooltipUI.ScreenGui.Enabled = false
			end
			isAnimating = false
			if currentTween == positionTween then
				currentTween = nil
			end
		end)
	end
end

function TooltipUI:Show(title: string, description: string, tooltipKind: TooltipKind?)
	tooltipKind = tooltipKind or "Central"

	if not tooltipUI then
		GetUI()
	end

	-- Update text content
	tooltipUI.TooltipTitle.Text = title
	tooltipUI.TooltipDescription.Text = description

	-- Show with animation
	ShowUIWithAnimation()
end

function TooltipUI:Hide()
	if not tooltipUI then
		return
	end

	-- Hide with animation
	HideUIWithAnimation()
end

return LifetimeObject.extend(TooltipUI, "TooltipUI")
