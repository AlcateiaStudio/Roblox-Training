--// Services //--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Folders //--
local client = ReplicatedStorage.Client
local shared = ReplicatedStorage.Shared
local data = shared.Data

--// Imports //--
local ClientAreaDetector = require(client.Components.ClientAreaDetector)
local Component = require(ReplicatedStorage.Packages.Component)
local Corridas = require(data.Corridas)
local TooltipUI = require(ReplicatedStorage.Client.Controllers.GUI.TooltipUI)

--// Constants //--
local COMPONENT_DETECTION_TIMEOUT = 3

--// Types //--
type TooltipSource = "RaceTracks"

--------------------------------------------------------------------------------
--// Private Functions //--
--------------------------------------------------------------------------------
local function GetTooltipStrings(tooltipID: string, tooltipSource: TooltipSource): Corridas.Corrida
	if tooltipSource == "RaceTracks" then
		local corrida: Corridas.Corrida = Corridas[tooltipID]
		if not corrida then
			warn("Invalid tooltipID: ", tostring(tooltipID), Corridas)
		end
		return corrida
	else
		error("Unsupported TooltipSource: " .. tostring(tooltipSource))
	end
end
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

	local tooltipID = self.Instance:GetAttribute("TooltipID")
	assert(tooltipID, "TooltipShower must have a Tooltip attribute of type string")
	local tooltipSource = self.Instance:GetAttribute("TooltipSource") :: TooltipSource
	assert(tooltipSource, "TooltipShower must have a TooltipSource attribute of type TooltipSource")

	local corrida = GetTooltipStrings(tooltipID, tooltipSource)

	-- Store references
	self.tooltipTitle = corrida.Nome
	self.tooltipDescription = corrida.Description
	self.isUIShowing = false
end

function TooltipShower:Start()
	ClientAreaDetector:WaitForInstance(self.Instance, COMPONENT_DETECTION_TIMEOUT)
		:andThen(function(component: ClientAreaDetector.AreaDetector)
			self.areaDetector = component
			component.Signals.Entered:Connect(function()
				print("TooltipShower: Player entered area for", self.tooltipTitle)
				if not self.isUIShowing then
					self.isUIShowing = true
					TooltipUI:Show(self.tooltipTitle, self.tooltipDescription, "Central")
				end
			end)

			component.Signals.Left:Connect(function()
				print("TooltipShower: Player left area for", self.tooltipTitle)
				if self.isUIShowing then
					self.isUIShowing = false
					TooltipUI:Hide()
				end
			end)

			warn("TooltipShower: ClientAreaDetector started for", self.Instance.Name)
		end)
		:catch(function(err)
			warn("TooltipShower: Failed to get ClientAreaDetector for", self.Instance.Name, "Error:", err)
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
