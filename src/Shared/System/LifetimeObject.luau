local LifetimeObject = {}
LifetimeObject.__index = LifetimeObject

-- Registry to keep track of all lifetime objects
local lifetimeObjects = {}

local debug = false

local function printDebug(...)
	if debug then
		print(...)
	end
end

-- Create a new lifetime object
function LifetimeObject.new(name: string?)
	local self = setmetatable({}, LifetimeObject)

	-- Set the name for debugging purposes
	self.Name = name or "UnnamedLifetimeObject"

	-- Register this object
	table.insert(lifetimeObjects, self)

	return self
end

-- Lifecycle methods (to be overridden by inheriting objects)
function LifetimeObject:OnAwake()
	-- Override this method in your controllers/services
end

function LifetimeObject:OnStart()
	-- Override this method in your controllers/services
end

function LifetimeObject:OnDestroy()
	-- Override this method in your controllers/services
end

-- Static methods to manage all lifetime objects
function LifetimeObject.AwakeAll()
	-- LifetimeObject.SetDebug(true) -- Enable when debugging
	printDebug("🚀 Starting OnAwake phase...")
	for _, object in ipairs(lifetimeObjects) do
		local success, errorMsg = pcall(function()
			printDebug(`⚡ {object.Name}:OnAwake()`)
			object:OnAwake()
		end)

		if not success then
			warn("❌ Error in OnAwake for object:", object.Name or object, errorMsg)
		end
	end
	printDebug("✅ OnAwake phase completed")
end

function LifetimeObject.StartAll()
	printDebug("🚀 Starting OnStart phase...")
	for _, object in ipairs(lifetimeObjects) do
		local success, errorMsg = pcall(function()
			printDebug(`⚡ {object.Name}:OnStart()`)
			object:OnStart()
		end)

		if not success then
			warn("❌ Error in OnStart for object:", object.Name or object, errorMsg)
		end
	end
	printDebug("✅ OnStart phase completed")
end

function LifetimeObject.DestroyAll()
	printDebug("🚀 Starting OnDestroy phase...")
	for _, object in ipairs(lifetimeObjects) do
		local success, errorMsg = pcall(function()
			printDebug(`{object.Name}:OnDestroy()`)
			object:OnDestroy()
		end)

		if not success then
			warn("❌ Error in OnDestroy for object:", object.Name or object, errorMsg)
		end
	end
	printDebug("✅ OnDestroy phase completed")

	-- Clear the registry
	lifetimeObjects = {}
end

-- Get all registered objects (for debugging)
function LifetimeObject.GetAll()
	return lifetimeObjects
end

-- Enable/disable debug mode
function LifetimeObject.SetDebug(enabled: boolean)
	debug = enabled
end

-- Get current debug state
function LifetimeObject.GetDebug()
	return debug
end

return LifetimeObject
