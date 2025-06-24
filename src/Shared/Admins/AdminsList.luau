local AdminsList = {}

AdminsList.Admins = {
	-1, -- Studio Player
	-2, -- Studio Player
	-3, -- Studio Player
	-4, -- Studio Player
	4133075243, -- AmdreTm
}

AdminsList.IsAdmin = function(userId: number)
	for _, adminId in ipairs(AdminsList.Admins) do
		if adminId == userId then
			return true
		end
	end

	return false
end

return AdminsList
