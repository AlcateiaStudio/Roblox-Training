return {
	Name = "DeleteDataStore",
	Aliases = { "deleteSave", "ds" },
	Description = "Deletes the player's data store",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "Player",
			Description = "The player to delete the data store of",
		},
	},
}
