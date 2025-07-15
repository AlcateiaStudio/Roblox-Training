--// Services //--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports //--
local ClientAreaDetector = require(ReplicatedStorage.Client.Components.ClientAreaDetector)
local Component = require(ReplicatedStorage.Packages.Component)
local TooltipUI = require(ReplicatedStorage.Client.Controllers.GUI.TooltipUI)

--// Constants //--
local COMPONENT_DETECTION_TIMEOUT = 3
--------------------------------------------------------------------------------
--// Component //--
--------------------------------------------------------------------------------
local TooltipShower = Component.new({ Tag = "TooltipShower", Extensions = {} })

function TooltipShower:Construct()
	assert(self.Instance:IsA("Model"), "TooltipShower must be a Model")

	assert(
		self.Instance.ModelStreamingMode == Enum.ModelStreamingMode.Persistent,
		"TooltipShower Model must have ModelStreamingMode set to Persistent"
	)

	local tooltip = self.Instance:GetAttribute("Tooltip")
	assert(tooltip, "TooltipShower must have a Tooltip attribute of type string")

	-- Store references
	self.tooltipString = tooltip
	self.isUIShowing = false
end

function TooltipShower:Start()
	ClientAreaDetector:WaitForInstance(self.Instance, COMPONENT_DETECTION_TIMEOUT):andThen(function(component: ClientAreaDetector.AreaDetector)
		self.areaDetector = component
		component.Signals.Entered:Connect(function()
			if not self.isUIShowing then
				self.isUIShowing = true
				TooltipUI:Show(self.tooltipString, "Central")
			end
		end)

		component.Signals.Left:Connect(function()
			if self.isUIShowing then
				self.isUIShowing = false
				TooltipUI:Hide()
			end
		end)
	end)	
end

function TooltipShower:Stop()
	-- Clean up connections
	if self.playerInAreaConnection then
		self.playerInAreaConnection:Disconnect()
		self.playerInAreaConnection = nil
	end

	if self.playerLeftConnection then
		self.playerLeftConnection:Disconnect()
		self.playerLeftConnection = nil
	end

	-- Hide UI if it was showing
	if self.isUIShowing then
		TooltipUI:Hide()
	end

	-- Clear references
	self.proximityPrompt = nil
	self.TooltipShowerID = nil
	self.isUIShowing = nil
end

return TooltipShower
