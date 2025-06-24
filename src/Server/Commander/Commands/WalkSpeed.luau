return {
	Name = "WalkSpeed",
	Aliases = { "task", "complete" },
	Description = "Sets the player's walk speed to value",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "Player",
			Description = "The player to set the walk speed of",
		},
		{
			Type = "number",
			Name = "Number",
			Description = "The walk speed value",
		},
	},
}
