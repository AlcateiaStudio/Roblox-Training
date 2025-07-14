local PlacementEndingStrings = {
	[1] = "st",
	[2] = "nd",
	[3] = "rd",
}

local furtherNumbersEnding = "th"

PlacementEndingStrings.GetEnding = function(number: number): string
	if number < 1 or number > 3 then
		return furtherNumbersEnding
	end
	return PlacementEndingStrings[number]
end

return PlacementEndingStrings
