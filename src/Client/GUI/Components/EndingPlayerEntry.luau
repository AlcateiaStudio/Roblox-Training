local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)

local EndingPlayerEntry = Component.new({ Tag = "EndingPlayerEntry", Extensions = {} })

--// Types //--
export type PlayerEntry = {
	PlayerNameText: TextLabel,
	PlayerImage: ImageLabel,
	PositionText: TextLabel,
	SetUpFor: (self: PlayerEntry, player: Player, position: number) -> (),
}

--// Constants //--
local THUMB_SIZE = Enum.ThumbnailSize.Size48x48
local THUMB_TYPE = Enum.ThumbnailType.HeadShot

--------------------------------------------------------------------------------
--// PlayerEntry Methods //--
--------------------------------------------------------------------------------
function EndingPlayerEntry:SetPlayerName(playerName: string)
	assert(type(playerName) == "string", "Player name must be a string")
	self.PlayerNameText.Text = playerName
end

function EndingPlayerEntry:SetPlayerImage(playerImage: ImageLabel)
	assert(playerImage:IsA("ImageLabel"), "Player image must be an ImageLabel")
	self.PlayerImage.Image = playerImage.Image
end

function EndingPlayerEntry:SetPositionText(position: number)
	assert(type(position) == "number", "Position text must be a number")
	self.PositionText.Text = tostring(position)
end

function EndingPlayerEntry:CreatePlayerIconImage(player: Player)
	local content, isReady = Players:GetUserThumbnailAsync(player.UserId, THUMB_TYPE, THUMB_SIZE)

	self.PlayerImage.Image = content
end

function EndingPlayerEntry:SetUpFor(player: Player, position: number)
	self:SetPlayerName(player.Name)
	self:SetPositionText(position)
	self:CreatePlayerIconImage(player)
end
--------------------------------------------------------------------------------
--// Component Lifecycle Methods //--
--------------------------------------------------------------------------------
function EndingPlayerEntry:Construct()
	local configuration: Configuration = self.Instance:GetAttribute("Configuration")
	assert(configuration, "EndingPlayerEntry must have a Configuration attribute of type Configuration")
	local playerImageValue = configuration:FindFirstChild("PlayerImage") :: ObjectValue
	assert(playerImageValue, "EndingPlayerEntry must have a PlayerImage ObjectValue in its Configuration")
	self.PlayerImage = playerImageValue.Value
	local playerNameTextValue = configuration:FindFirstChild("PlayerName") :: StringValue
	assert(playerNameTextValue, "EndingPlayerEntry must have a PlayerName StringValue in its Configuration")
	self.PlayerNameText = playerNameTextValue.Value
	local positionTextValue = configuration:FindFirstChild("PositionText") :: StringValue
	assert(positionTextValue, "EndingPlayerEntry must have a PositionText StringValue in its Configuration")
	self.PositionText = positionTextValue.Value
end

function EndingPlayerEntry:Start() end

function EndingPlayerEntry:Stop() end

return EndingPlayerEntry
