local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local LifetimeObject = require(ReplicatedStorage.Shared.System.LifetimeObject)
local AreaDetectorComponent = require(ServerScriptService.Server.Components.AreaDetectorComponent)

local ComponentTester = {}
ComponentTester.Name = "ComponentTester"

function ComponentTester:OnStart()
	local areaDetectorTest = workspace:WaitForChild("AreaDetectorTest", 10) :: Model
	assert(areaDetectorTest, "AreaDetector not found in workspace")

	AreaDetectorComponent:WaitForInstance(areaDetectorTest)
		:andThen(function(component)
			component.Signals.Entered:Connect(function(player)
				print(player, `entered`)
			end)

			component.Signals.Left:Connect(function(player)
				print(player, `left`)
			end)
		end)
		:catch(function()
			print("Couldn't get component")
		end)
end

return LifetimeObject.extend(ComponentTester, "ComponentTester")
