local fs = require("@lune/fs")
local stdio = require("@lune/stdio")
local task = require("@lune/task")

--// Constants //--
local EXIT = false
local MODULES_PATH = "./Modules"

--// Modules //--
local serviceModules = {
	["Blink"] = require(MODULES_PATH .. "/BlinkProcessor"),
	["Rojo"] = require(MODULES_PATH .. "/RojoProcessor"),
	["DarkLua"] = require(MODULES_PATH .. "/DarkLuaProcessor"),
}

local dependencyModules = {
	["Dependencies"] = require(MODULES_PATH .. "/DependenciesProcessor"),
}

local utils = require("./ProjectManagementUtils")
-------------------------------------------------------------------------------------------------
-- Utils --

local function resetStyle()
	stdio.write(stdio.style("reset"))
end

-------------------------------------------------------------------------------------------------

local function initializeServices()
	stdio.write(stdio.color("cyan"))
	print("Loading modules...")
	resetStyle()

	local activeTasks = {}

	print("")
	print("Starting services...")
	print("")

	for serviceName, serviceModule in pairs(serviceModules) do
		if serviceModule.Prepare then
			serviceModule.Prepare(utils)
			task.wait(0.1)
		end
	end

	for serviceName, serviceModule in pairs(serviceModules) do
		local taskHandle = serviceModule.Execute(utils)
		if taskHandle then
			table.insert(activeTasks, taskHandle)
			task.wait(0.3)
		else
			warn("Failed to start " .. serviceName .. " service.")
		end
	end

	for serviceName, serviceModule in pairs(serviceModules) do
		if serviceModule.LateExecute then
			serviceModule.LateExecute(utils)
			task.wait(0.1)
		end
	end

	stdio.write(stdio.color("green"))
	print("")
	print("✓ All watch services are running in background")
	print("✓ Files will auto-update when you make changes")
	print("✓ Your game is ready for development!")
	print("")
	resetStyle()

	stdio.prompt("text", "Press 'ENTER' to stop processes:")

	stdio.write(stdio.color("red"))
	print("Stopping all services...")

	-- Clean shutdown of all active tasks
	for _, activeTask in activeTasks do
		-- Check if the activeTask is a task or a table of tasks and handle appropriately
		if type(activeTask) == "table" then
			for _, taskItem in activeTask do
				task.cancel(taskItem)
			end
		else
			task.cancel(activeTask)
		end
	end

	print("Services stopped.")
	EXIT = true
	resetStyle()
end

local function setupDependencies()
	stdio.write(stdio.color("cyan"))
	print("Loading modules...")
	resetStyle()

	stdio.write(stdio.color("yellow"))
	print("Setting up dependencies...")
	resetStyle()

	-- Phase 1: Prepare all modules
	for moduleName, module in dependencyModules do
		if module.Prepare then
			module.Prepare(utils)
		end
	end

	-- Phase 2: Execute dependency setup
	for moduleName, module in dependencyModules do
		if module.Execute then
			module.Execute(utils)
		end
	end

	-- Phase 3: Late execute for any cleanup
	for moduleName, module in dependencyModules do
		if module.LateExecute then
			module.LateExecute(utils)
		end
	end

	print("Dependencies setup complete!")
end

-------------------------------------------------------------------------------------------------

local Options
Options = {
	[1] = {
		Name = "Initialize Services",
		Description = "Initializes all the installed services",
		Execute = initializeServices,
	},

	[2] = {
		Name = "Setup Dependencies",
		Description = "Installs Wally Packages, generates type defs, sets up Lune, sets up source map.",
		Execute = setupDependencies,
	},

	[0] = {
		Name = "EXIT",
		Description = "Exits the program.",
		Execute = function()
			EXIT = true
		end,
	},
}

-------------------------------------------------------------------------------------------------

print("")
print("Welcome to the Setup Manager!")
print("Remember to frequently pull from the 'main' branch")
print("and run 'wally install' to get the latest updates!")
print("")

while not EXIT do
	print("-------------")
	print("| Main Menu |")
	print("-------------")
	for i, option in pairs(Options) do
		stdio.write(stdio.style("bold"))
		stdio.write(i .. ") ")
		resetStyle()
		print(option.Name)
		stdio.write(stdio.color("black"))
		print("   - " .. option.Description)
		resetStyle()
	end
	print("-------------")

	local selectedOption = nil
	repeat
		local input = stdio.prompt("text", "ENTER OPTION: ")
		local inputArgs = string.split(input, " ")
		local number = tonumber(inputArgs[1])
		if number and Options[number] then
			selectedOption = Options[number]
		else
			warn("Invalid Choice. Please try again.")
		end
	until selectedOption

	if selectedOption.Execute then
		selectedOption.Execute()
	else
		warn("No execute function found for option.")
	end
end

print("Goodbye!")
return {}
