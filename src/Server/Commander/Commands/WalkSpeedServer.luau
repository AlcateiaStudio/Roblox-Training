return function(context, player: Player, walkSpeed: number)
	local character = player.Character
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	humanoid.WalkSpeed = walkSpeed
end
