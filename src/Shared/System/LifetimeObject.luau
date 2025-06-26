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

function LifetimeObject.extend<T>(object: T, name: string?): T
	-- Copy all LifetimeObject methods
	for key, value in pairs(LifetimeObject) do
		if type(value) == "function" and key ~= "new" and key ~= "extend" then
			(object :: any)[key] = value
		end
	end

	-- Set up metatable for inheritance
	setmetatable(object :: any, LifetimeObject)

	-- Set the name for debugging purposes
	local anyObject = object :: any
	anyObject.Name = name or "UnnamedLifetimeObject"

	-- Register this object
	table.insert(lifetimeObjects, anyObject)

	return anyObject
end

--------------------------------------------------------------------------------
--// Lifecycle Methods //--
--------------------------------------------------------------------------------
function LifetimeObject:OnAwake()
	-- Override this method in your controllers/services
end

function LifetimeObject:OnStart()
	-- Override this method in your controllers/services
end

function LifetimeObject:OnDestroy()
	-- Override this method in your controllers/services
end

--------------------------------------------------------------------------------
--// Static Methods //--
--------------------------------------------------------------------------------
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

	lifetimeObjects = {}
end

--------------------------------------------------------------------------------
--// Helpers //--
--------------------------------------------------------------------------------
function LifetimeObject.GetAll()
	return lifetimeObjects
end

function LifetimeObject.SetDebug(enabled: boolean)
	debug = enabled
end

return LifetimeObject
