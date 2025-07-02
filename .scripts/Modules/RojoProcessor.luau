local RojoProcessor = {}

-- Constants
local ROJO_PROJECT_JSON_FILE = "default.project.json"

function RojoProcessor.Execute(Utils)
	local sourcemapWatch =
		Utils.createProcess("rojo", { "sourcemap", "--watch", "--output", "sourcemap.json" }, "red", "• Sourcemap watching")
	local rojoServe = Utils.createProcess("rojo", { "serve", ROJO_PROJECT_JSON_FILE }, "blue", "• Rojo served the project")

	return { sourcemapWatch, rojoServe }
end

return RojoProcessor
