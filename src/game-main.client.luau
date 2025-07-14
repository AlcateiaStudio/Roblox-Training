local version = "0.1 - Hello World!"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local ClientFolder = ReplicatedStorage.Client

-- Variables
local debug = false

-- Imports
local AdminsList = require(ReplicatedStorage.Shared.Admins.AdminsList)
local LifetimeObject = require(ReplicatedStorage.Shared.System.LifetimeObject)
local Replica = require(ReplicatedStorage.Client.ReplicaClient)

local function printDebug(...)
	if debug then
		print(...)
	end
end

printDebug("Game v. ", version)

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

-- Phase 1: Awake all objects
LifetimeObject.AwakeAll()

-- Phase 2: Start all objects
LifetimeObject.StartAll()

printDebug("🎯 Lifetime System initialized successfully!")

--------------------------------------------------------------------------------
--// Commander //--
--------------------------------------------------------------------------------
if AdminsList.IsAdmin(Players.LocalPlayer.UserId) then
	local Cmdr = (require)(ReplicatedStorage:WaitForChild("CmdrClient"))

	Cmdr:SetActivationKeys({ Enum.KeyCode.F2 })
	printDebug("Cmdr initialized successfully!")
end
