local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local serverServicesFolder = ServerScriptService.Server.Services
local componentsFolder = ServerScriptService.Server.Components

local commandsFolder = ServerScriptService.Server.Commander.Commands
local commanderTypesFolder = ServerScriptService.Server.Commander.Types
local commanderHooksFolder = ServerScriptService.Server.Commander.Hooks

local Cmdr = require(ReplicatedStorage.Packages.Cmdr)
local LifetimeObject = require(ReplicatedStorage.Shared.System.LifetimeObject)

local debug = false

local function printDebug(...)
	if debug then
		print(...)
	end
end

local function RequireContents(folder: Folder)
	for _, module in ipairs(folder:GetDescendants()) do
		if not module:IsA("ModuleScript") then
			continue
		end

		print(`Requiring Service {module.Name}`)

		local success, errorMsg = pcall(function()
			require(module)
		end)

		if not success then
			warn("Error requiring module:", module.Name, errorMsg)
		end
	end
end

RequireContents(serverServicesFolder)
RequireContents(componentsFolder)

Cmdr:RegisterDefaultCommands()
Cmdr:RegisterCommandsIn(commandsFolder)
Cmdr:RegisterTypesIn(commanderTypesFolder)
Cmdr:RegisterHooksIn(commanderHooksFolder)

-- Phase 1: Awake all objects
LifetimeObject.AwakeAll()

-- Phase 2: Start all objects
LifetimeObject.StartAll()

print("🎯 All Server Lifetime Systems initialized successfully!")
