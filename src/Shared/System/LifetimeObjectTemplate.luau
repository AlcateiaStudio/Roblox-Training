local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LifetimeObject = require(ReplicatedStorage.Shared.System.LifetimeObject)

local LifetimeObjectTemplate = {}

function LifetimeObjectTemplate:OnAwake() end

function LifetimeObjectTemplate:OnStart() end

function LifetimeObjectTemplate:OnDestroy() end

return LifetimeObject.extend(LifetimeObjectTemplate, "LifetimeObjectTemplate")
