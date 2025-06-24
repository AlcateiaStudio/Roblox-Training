local fs = require("@lune/fs")
local task = require("@lune/task")

export type fsMetadata = fs.Metadata

local fileWatcher = {}

local function scanDirectory(dir: string, pattern: string)
	local files = {}
	local directories = {}
	local function scan(path)
		for _, entry in ipairs(fs.readDir(path)) do
			local fullPath = `{path}/{entry}`
			if fs.isDir(fullPath) then
				directories[fullPath] = true
				scan(fullPath)
			elseif entry:match(pattern) then
				files[fullPath] = fs.metadata(fullPath)
			end
		end
	end
	scan(dir)
	return files, directories
end

export type FileWatchOptions = {
	path: string?,
	pattern: string?,
	onFileCreated: (fullPath: string, metadata: fsMetadata) -> (),
	onFileChanged: (fullPath: string, metadata: fsMetadata) -> (),
	onFileRemoved: (fullPath: string) -> (),
	onDirectoryCreated: (fullPath: string) -> (),
	onDirectoryRemoved: (fullPath: string) -> (),
	checkInterval: number?,
}

function fileWatcher.watchDirectory(options: FileWatchOptions)
	local dir = options.path or "."
	local pattern = options.pattern or ".*"
	local checkInterval = options.checkInterval or 0 -- 0 means every frame

	local fileStates, directoryStates = scanDirectory(dir, pattern)

	local function updateStates()
		local currentFiles, currentDirectories = scanDirectory(dir, pattern)

		-- Check for new and modified files
		for fullPath, metadata in pairs(currentFiles) do
			if not fileStates[fullPath] then
				local success, err = pcall(options.onFileCreated :: any, fullPath, metadata)
				if not success then
					warn(err)
				end
			elseif metadata.modifiedAt ~= fileStates[fullPath].modifiedAt then
				local success, err = pcall(options.onFileChanged :: any, fullPath, metadata)
				if not success then
					warn(err)
				end
			end
		end

		-- Check for removed files
		for fullPath, _ in pairs(fileStates) do
			if not currentFiles[fullPath] then
				local success, err = pcall(options.onFileRemoved :: any, fullPath)
				if not success then
					warn(err)
				end
			end
		end

		-- Check for new directories
		for fullPath, _ in pairs(currentDirectories) do
			if not directoryStates[fullPath] then
				local success, err = pcall(options.onDirectoryCreated :: any, fullPath)
				if not success then
					warn(err)
				end
			end
		end

		-- Check for removed directories
		for fullPath, _ in pairs(directoryStates) do
			if not currentDirectories[fullPath] then
				local success, err = pcall(options.onDirectoryRemoved :: any, fullPath)
				if not success then
					warn(err)
				end
			end
		end

		fileStates = currentFiles
		directoryStates = currentDirectories
	end

	-- Return a function that, when called, starts the watching process
	return function()
		while true do
			updateStates()
			if checkInterval > 0 then
				task.wait(checkInterval)
			else
				task.wait() -- Wait for the next frame
			end
		end
	end
end

function fileWatcher.watchFile(path: string, onFileChanged: (string, fs.Metadata) -> ())
	local metadata = fs.metadata(path)

	return function()
		while true do
			local newMetadata = fs.metadata(path)
			if newMetadata.modifiedAt ~= metadata.modifiedAt then
				onFileChanged(path, newMetadata)
			end
			metadata = newMetadata
			task.wait()
		end
	end
end

return fileWatcher
