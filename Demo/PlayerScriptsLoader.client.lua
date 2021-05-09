local Player = game:GetService("Players").LocalPlayer
local Luanoid = require(game:GetService("ReplicatedStorage"):WaitForChild("Luanoid"))
local PlayerModule = require(script.Parent:WaitForChild("PlayerModule"))
local Camera = workspace.CurrentCamera

local Character
local CurrentLuanoid

local PRIORITY = Enum.AnimationPriority
local ANIMATIONS = {
    Climbing = {
        AnimationId = "http://www.roblox.com/asset/?id=507765644",
        Priority = PRIORITY.Movement
    },
    Falling = {
        AnimationId = "http://www.roblox.com/asset/?id=507767968",
        Priority = PRIORITY.Movement
    },
    Idling = {
        AnimationId = "http://www.roblox.com/asset/?id=507766388", -- Looking around: 507766666
        Priority = PRIORITY.Idle
    },
    Jumping = {
        AnimationId = "http://www.roblox.com/asset/?id=507765000",
        Priority = PRIORITY.Movement
    },
    Swimming = {
        AnimationId = "http://www.roblox.com/asset/?id=913384386",
        Priority = PRIORITY.Movement
    },
    Walking = {
        AnimationId = "http://www.roblox.com/asset/?id=913402848",
        Priority = PRIORITY.Movement
    },
}

for _,animationData in pairs(ANIMATIONS) do
    local animation = Instance.new("Animation")
    animation.AnimationId = animationData.AnimationId
    animationData.Animation = animation
end

Player.CharacterAdded:Connect(function(character)
	Character = character
	Camera.CameraSubject = character.PrimaryPart
	Camera.CameraType = Enum.CameraType.Custom
	CurrentLuanoid = Luanoid(character)

	for animationName, animationData in pairs(ANIMATIONS) do
        CurrentLuanoid:LoadAnimation(
            animationData.Animation,
            animationName,
            {
                Priority = animationData[2],
            }
        )
    end
end)

game:GetService("RunService").Heartbeat:Connect(function()
	if CurrentLuanoid and Character and Character.Parent then
		local activeController = PlayerModule.controls.activeController

		if activeController then
			local moveVector = activeController.moveVector

			if activeController.jumpRequested then
				CurrentLuanoid:Jump()
			end

			CurrentLuanoid.MoveDirection = Camera.CFrame:VectorToWorldSpace(moveVector)
		end
	end
end)