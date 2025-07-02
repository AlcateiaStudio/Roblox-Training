local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")
local task = require("@lune/task")

local ProjectManagementUtils = {}

-------------------------------------------------------------------------------------------------
-- Settings --
local stdIoOptions: process.ExecStdioOptions = {
	stdout = "forward", -- Inherit stdio to allow direct output to console
	stderr = "forward", -- Inherit stdio to allow direct output to console
}

local execOptions: process.ExecOptions = {
	stdio = stdIoOptions,
}

local createOptions: process.CreateOptions = {
	stdio = stdIoOptions,
}

-------------------------------------------------------------------------------------------------
-- Utility Functions --

function ProjectManagementUtils.createStdoutReader(results, program: string, color: "red" | "purple" | "blue" | "yellow")
	return task.spawn(function()
		while true do
			local output = results.stdout:read()
			if output then
				stdio.write(stdio.color(color))
				print("\n┌─ [" .. program:upper() .. "] ─────")
				ProjectManagementUtils.resetStyle()
				print(output)
				stdio.write(stdio.color(color))
				print("└──────────────────")
				ProjectManagementUtils.resetStyle()
			else
				break
			end
		end
	end)
end

function ProjectManagementUtils.createStderrReader(results, program: string)
	return task.spawn(function()
		while true do
			local output = results.stderr:read()
			if output then
				stdio.write(stdio.color("red"))
				print("┌─ [" .. program:upper() .. " ERROR] ─────")
				ProjectManagementUtils.resetStyle()
				print(output)
				stdio.write(stdio.color("red"))
				print("└──────────────────")
				ProjectManagementUtils.resetStyle()
			else
				break
			end
		end
	end)
end

function ProjectManagementUtils.execute(...)
	local tbl = { ... }
	local program = table.remove(tbl, 1)
	local child = process.create(program, tbl, createOptions)
	return child:status()
end

function ProjectManagementUtils.executeString(command: string)
	return ProjectManagementUtils.execute(table.unpack(string.split(command, " ")))
end

function ProjectManagementUtils.resetStyle()
	stdio.write(stdio.style("reset"))
end

function ProjectManagementUtils.safeRemove(path: string, color: "red" | "purple" | "blue" | "yellow", actionLog: string)
	if fs.isFile(path) then
		stdio.write(stdio.color(color))
		print(actionLog .. " (file)")
		ProjectManagementUtils.resetStyle()
		fs.removeFile(path)
	elseif fs.isDir(path) then
		stdio.write(stdio.color(color))
		print(actionLog .. " (directory)")
		ProjectManagementUtils.resetStyle()
		fs.removeDir(path)
	end
end

function ProjectManagementUtils.createProcess(
	program: string,
	args: { string },
	color: "red" | "purple" | "blue" | "yellow",
	successLog: string
)
	local processTask = task.spawn(function()
		local results = process.create(program, args, createOptions)

		-- Use utility functions for reading stdout and stderr
		ProjectManagementUtils.createStdoutReader(results, program, color)
		ProjectManagementUtils.createStderrReader(results, program)

		local status = results:status() -- Wait for the process to complete
		if not status.ok then
			stdio.write(stdio.color("red"))
			print("[" .. program .. "] Process exited with code " .. tostring(status.code))
			ProjectManagementUtils.resetStyle()
		end
	end)

	-- Give the process a moment to start
	task.wait(0.1)

	-- Print success message
	stdio.write(stdio.color(color))
	print(successLog)
	ProjectManagementUtils.resetStyle()

	return processTask
end

function ProjectManagementUtils.executeProcess(
	program: string,
	args: { string },
	color: "red" | "purple" | "blue" | "yellow",
	actionLog: string
)
	stdio.write(stdio.color(color))
	print(actionLog)
	ProjectManagementUtils.resetStyle()

	local status = process.exec(program, args, execOptions)

	if not status.ok then
		stdio.write(stdio.color("red"))
		print("Error: Process failed with code " .. tostring(status.code))
		ProjectManagementUtils.resetStyle()
	end

	return status
end

return ProjectManagementUtils
