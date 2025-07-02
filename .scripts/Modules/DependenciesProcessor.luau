local task = require("@lune/task")

local DependenciesProcessor = {}

function DependenciesProcessor.Prepare(Utils)
	Utils.safeRemove("sourcemap.json", "yellow", "Removing sourcemap.json...")
	Utils.safeRemove("wally.lock", "yellow", "Removing wally.lock...")
	Utils.safeRemove("Packages", "yellow", "Removing Packages...")
end

function DependenciesProcessor.Execute(Utils)
	Utils.executeProcess("rokit", { "install" }, "red", "Installing Rokit packages...")

	Utils.executeProcess("wally", { "install" }, "blue", "Setting up Wally packages...")

	Utils.executeProcess("rojo", { "sourcemap", ".", "-o", "sourcemap.json" }, "red", "Generating source map...")

	Utils.executeProcess("wally-package-types", { "--sourcemap", "sourcemap.json", "Packages" }, "purple", "Setting up package types...")

	Utils.executeProcess("lune", { "setup" }, "blue", "Setting up Lune...")
end

function DependenciesProcessor.LateExecute(Utils)
	-- Final source map generation
	local results = Utils.executeString("rojo sourcemap . -o sourcemap.json")
	if not results.ok then
		warn(results)
	end
end

return DependenciesProcessor
