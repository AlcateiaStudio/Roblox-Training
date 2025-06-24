local CharacterUtils = {}

function CharacterUtils:LockCharacter(character: Model)
	assert(character, "Character is nil")
	-- Lock character in place
	for _, part in ipairs(character:GetDescendants()) do
		local isTool = part:FindFirstAncestorWhichIsA("Tool")
		if part:IsA("BasePart") and not isTool then
			part.Anchored = true
		end
	end
end

function CharacterUtils:UnlockCharacter(character: Model)
	assert(character, "Character is nil")
	-- Unlock character
	for _, part in ipairs(character:GetDescendants()) do
		local isTool = part:FindFirstAncestorWhichIsA("Tool")
		if part:IsA("BasePart") and not isTool then
			part.Anchored = false
		end
	end
end

function CharacterUtils:HideCharacter(character: Model)
	if not character or not character.Parent then
		warn("HideCharacter: Character does not exist or has been removed.")
		return
	end

	for _, v in ipairs(character:GetDescendants()) do
		if v:IsA("BasePart") or v:IsA("Decal") then
			v.Transparency = 1
		elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
			v.Enabled = false
		end
	end
end

function CharacterUtils:HideAndRestore(character: Model)
	if not character or not character.Parent then
		warn("HideCharacter: Character does not exist or has been removed.")
		return
	end

	-- Table to store original states of modified objects
	local originalStates = {}

	for _, v in ipairs(character:GetDescendants()) do
		-- Handle BaseParts and Decals
		if v:IsA("BasePart") or v:IsA("Decal") then
			if v.Transparency < 1 then
				-- Store the original transparency
				originalStates[v] = v.Transparency
				v.Transparency = 1
			end
		-- Handle ParticleEmitters and Trails
		elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
			if v.Enabled == true then
			-- Store that it was enabled
				originalStates[v] = true
				v.Enabled = false
			end
		end
	end

	-- Return a function to restore original states
	local function RestoreCharacter()
		if not character or not character.Parent then
			warn("RestoreCharacter: Character does not exist or has been removed.")
			return
		end

		for obj, originalValue in pairs(originalStates) do
			if obj and obj.Parent then
				if obj:IsA("BasePart") or obj:IsA("Decal") then
					obj.Transparency = originalValue
				elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
					obj.Enabled = originalValue
				end
			end
		end
	end

	return RestoreCharacter
end

function CharacterUtils:ApplyCollisionGroup(character: Model, collisionGroup: string)
	local PhysicsService = game:GetService("PhysicsService")
	assert(PhysicsService:IsCollisionGroupRegistered(collisionGroup), "Collision group not registered")
	assert(character, "Character is nil")

	-- Apply collision group to character
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part = part :: BasePart
			part.CollisionGroup = collisionGroup
		end
	end
end

return CharacterUtils
