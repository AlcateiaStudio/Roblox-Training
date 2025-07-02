local BlinkProcessor = {}

function BlinkProcessor.Execute(Utils)
	return Utils.createProcess("blink", { "Events", "--watch" }, "yellow", "• Blink events being monitored")
end

return BlinkProcessor
