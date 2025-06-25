export type Test = "Test1" | "Test2"

return function(registry)
	registry:RegisterType(
		"test",
		registry.Cmdr.Util.MakeEnumType("Test", {
			"Test1",
			"Test2",
		})
	)
end
