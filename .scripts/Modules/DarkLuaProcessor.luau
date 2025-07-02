-- Note: This module requires the ProjectManagementUtils to be passed as a parameter

local DarkLuaProcessor = {}

-- Constants
local SRC_PATH = "src"
local DARKLUA_PATH = "DarkLua"

function DarkLuaProcessor.Prepare(Utils)
	Utils.safeRemove(DARKLUA_PATH, "yellow", "Removing old DarkLua Build...")
end

function DarkLuaProcessor.Execute(Utils)
	return Utils.createProcess("darklua", { "process", "--watch", SRC_PATH, DARKLUA_PATH }, "purple", "• DarkLua processing")
end

return DarkLuaProcessor
