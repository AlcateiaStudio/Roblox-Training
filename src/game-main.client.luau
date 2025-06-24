local version = "0.1 - Hello World!"
print("Game v. ", version)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local ClientFolder = ReplicatedStorage.Client

-- Imports
local Knit = require(ReplicatedStorage.Packages.Knit)
local Replica = require(ReplicatedStorage.Client.ReplicaClient)
local AdminsList = require(ReplicatedStorage.Shared.Admins.AdminsList)

-- Require all the client modules
local function RequireContents(folder: Folder)
	for _, module in ipairs(folder:GetDescendants()) do
		if not module:IsA("ModuleScript") then
			continue
		end

		if module.Parent.Name == "Archive" then
			continue
		end

		-- print(`Requiring {module.Name}`) -- Commented so that we don't expose script names in the client side for security reasons

		local success, errorMsg = pcall(function()
			require(module)
		end)

		if not success then
			warn("Error requiring module:", module.Name, errorMsg)
		end
	end
end

RequireContents(ClientFolder)

Replica.RequestData()

Knit.Start()
	:andThen(function()
		print("Knit started all controllers")
	end)
	:catch(warn)

--------------------------------------------------------------------------------
--// Commander //--
--------------------------------------------------------------------------------
if AdminsList.IsAdmin(Players.LocalPlayer.UserId) then
	local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))

	Cmdr:SetActivationKeys({ Enum.KeyCode.F2 })
end

--------------------------------------------------------------------------------
--// Override Default Core Call for Resetting Character //--
--------------------------------------------------------------------------------
local coreCall
do
	local MAX_RETRIES = 8

	local StarterGui = game:GetService("StarterGui")
	local RunService = game:GetService("RunService")

	function coreCall(method, ...)
		local result = {}
		for retries = 1, MAX_RETRIES do
			result = { pcall(StarterGui[method], StarterGui, ...) }
			if result[1] then
				break
			end
			RunService.Stepped:Wait()
		end
		return unpack(result)
	end
end

coreCall("SetCore", "ResetButtonCallback", false)
