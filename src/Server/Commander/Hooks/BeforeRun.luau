local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AdminsList = require(ReplicatedStorage.Shared.Admins.AdminsList)

local function IsValidUserID(userId: number)
	return AdminsList.IsAdmin(userId)
end

return function(registry)
	registry:RegisterHook("BeforeRun", function(context)
		-- Allow commands to run freely in Studio
		if RunService:IsStudio() then
			return -- Proceed with command execution
		end

		-- Get the executor of the command
		local executor = context.Executor

		-- Check if the executor exists and is a valid user
		if executor and IsValidUserID(executor.UserId) then
			return -- Proceed with command execution
		else
			return "You don't have permission to run this command"
		end
	end)
end
