local Player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Luanoid = require(ReplicatedStorage:WaitForChild("Luanoid"))
local PlayerModule = require(script.Parent:WaitForChild("PlayerModule"))
local Camera = workspace.CurrentCamera
local ResetEvent = ReplicatedStorage:WaitForChild("ResetEvent")

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
    local luanoid = Luanoid(nil, character)

	Character = character
	Camera.CameraSubject = character.PrimaryPart
	Camera.CameraType = Enum.CameraType.Custom
	CurrentLuanoid = luanoid

	for animationName, animationData in pairs(ANIMATIONS) do
        luanoid:LoadAnimation(
            animationData.Animation,
            animationName,
            {
                Priority = animationData[2],
            }
        )
    end

    --[[
        Luanoid CharacterState is not replicated between the Server and
        Client, as a result CharacterState related events must be detected
        on the machine simulating the Luanoid.

        Events such as HealthChanged, Died, and Jumping can be detected through
        the Luanoid's character attributes.
    ]]
    --[[
    luanoid.StateChanged:Connect(function(newState, oldState)
        print("CharacterState changed from", oldState.Name, "to", newState.Name)
    end)
    luanoid.HealthChanged:Connect(function(health)
        print("Health is now", health)
    end)
    luanoid.Died:Connect(function(isDead)
        print("Dead is", isDead)

        if isDead then
            ResetEvent:FireServer()
        end
    end)
    luanoid.FreeFalling:Connect(function(isFreeFalling)
        print("Freefalling is", isFreeFalling)
    end)
    luanoid.Jumping:Connect(function(isJumping)
        print("Jumping is", isJumping)
    end)
    ]]
end)

--[[
    This simply taps into the existing Roblox character scripts and sets the
    Luanoid's MoveDirection based on the camera every frame.
]]
RunService.Heartbeat:Connect(function()
	if CurrentLuanoid and Character and Character.Parent then
		local activeController = PlayerModule.controls.activeController

		if activeController then
			local moveVector = activeController.moveVector

			if activeController.jumpRequested then
				CurrentLuanoid.Jump = true
			end

			CurrentLuanoid.MoveDirection = Camera.CFrame:VectorToWorldSpace(moveVector)
		end
	end
end)

--[[
    Replaces the default reset logic with one that is compatible for Luanoids.
]]
local resetBindable = Instance.new("BindableEvent")

repeat
    local success = pcall(function()
        StarterGui:SetCore("ResetButtonCallback", resetBindable)
    end)
    RunService.Heartbeat:Wait()
until success

resetBindable.Event:Connect(function()
    ResetEvent:FireServer()
end)