local stdio = require("@lune/stdio")
local process = require("@lune/process")
local task = require("@lune/task")
local fs = require("@lune/fs")
local fileWatcher = require("fileWatcher")

--// Constants //--
local EXIT = false

-------------------------------------------------------------------------------------------------
-- Utility Functions --

local function execute(...)
	local tbl = { ... }
	local program = table.remove(tbl, 1)
	return process.spawn(program, tbl)
end

local function executeString(command: string)
	return execute(table.unpack(string.split(command, " ")))
end

local function generateSourceMap(projectFile: string)
	local results = executeString("rojo sourcemap " .. projectFile .. " -o sourcemap.json")
	if not results.ok then
		warn(results)
	end
	return results
end

local function removeLastPathIdx(path: string): string
	local pathToArray = string.split(path, "/")
	table.remove(pathToArray, #pathToArray)
	return table.concat(pathToArray, "/")
end

local function resetStyle()
	stdio.write(stdio.style("reset"))
end

-------------------------------------------------------------------------------------------------

local function serveRojo()
	local luauLSPProjectFile = "lsp.project.json"
	local rojoProjectFile
	rojoProjectFile = "game.project.json"

	local PRINT_CHANGES = stdio.prompt("confirm", "Would you like to display file changes? (y/n)")

	print("Generating Source Map... ")
	generateSourceMap(luauLSPProjectFile)

	local function printChanges(...)
		if PRINT_CHANGES then
			print(...)
		end
	end

	local startWatchers = fileWatcher.watchDirectory({
		path = "src",
		onFileChanged = function(fullPath: string, metadata)
			printChanges("File Changed: ", fullPath)
			fullPath = removeLastPathIdx(fullPath)
		end,
		onFileCreated = function(fullPath: string, metadata)
			printChanges("File Created: ", fullPath)
		end,
		onFileRemoved = function(fullPath: string)
			printChanges("File Removed: ", fullPath)
		end,
		onDirectoryCreated = function(fullPath: string)
			printChanges("Directory Created: ", fullPath)
		end,
		onDirectoryRemoved = function(fullPath: string)
			printChanges("Directory Removed: ", fullPath)
		end,
		checkInterval = 1,
	})

	print("Serving Rojo and watching files...")
	local rojoServe = task.spawn(executeString, "rojo serve " .. rojoProjectFile)
	local watcherRoutine = task.spawn(startWatchers)
	task.defer(function()
		task.wait()
		printChanges("")
		printChanges("| File-Watcher |")
	end)
	stdio.prompt("text", "Press 'ctrl+c' to exit:")
	task.cancel(watcherRoutine)
	task.cancel(rojoServe)
	print("Stopping File-Watcher and Rojo Serve...")
	process.exit()
end

-------------------------------------------------------------------------------------------------

local Options
Options = {
	[1] = {
		Name = "Serve Rojo",
		Description = "Watches for changes, and serves the Rojo project.",
		Execute = serveRojo,
	},

	[2] = {
		Name = "Setup Wally Packages",
		Description = "Installs the latest Wally Packages, generates their type defs, and sets up the source map.",
		Execute = function()
			print("Clearing current systems...")
			executeString("rm sourcemap.json")
			executeString("rm wally.lock")
			executeString("rm -r Packages")

			print("Setting up Wally packages...")
			local results = execute("wally", "install")
			print(results.stderr)
			if not results.ok then
				warn(results)
			end

			task.wait(0.2)

			results = generateSourceMap("build.project.json")
			print(results.stderr)
			if not results.ok then
				warn(results)
			end

			task.wait(0.2)

			-- Build the types for Packages
			print("Setting up package types...")
			results = execute("wally-package-types", "--sourcemap", "sourcemap.json", "Packages")
			print(results.stderr)
			if not results.ok then
				warn(results)
			end

			generateSourceMap("build.project.json")
		end,
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
