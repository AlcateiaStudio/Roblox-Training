return {
	Name = "FireBlink",
	Aliases = { "blink" },
	Description = "Fires the blink event for a player",
	Group = "Admin",
	Args = {
		{
			Type = "string",
			Name = "BlinkEventName",
			Description = "The blink event name to fire",
		},
		{
			Type = "player",
			Name = "Player",
			Description = "The player to fire the blink event for",
		},
		{
			Type = "number",
			Name = "NumberArgs",
			Description = "Additional number arguments to pass to the blink event",
			Optional = true,
		},
	},
}
