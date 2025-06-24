local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LifetimeObject = require(ReplicatedStorage.Shared.System.LifetimeObject)

local LifetimeObjectTemplate = LifetimeObject.new()

function LifetimeObjectTemplate:OnAwake() end

function LifetimeObjectTemplate:OnStart() end

function LifetimeObjectTemplate:OnDestroy() end

return LifetimeObjectTemplate
