--[[
    This example spawns, rigs, and animates a Luanoid using a modified version
    of Dogutsune's Dogu15 rig which is a R15 rig with mesh deformation. This
    example depends on HttpService being enabled to insert the rig.

    Dogu15 Rig:
    https://devforum.roblox.com/t/dogu15-an-improved-r15-rig-mesh-deformation/532832

    Modified Rig:
    https://www.roblox.com/library/6324529033/R15Rig
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local RunService = game:GetService("RunService")

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
local DOGU15_RIG

if RunService:IsServer() then
    DOGU15_RIG = InsertService:LoadAsset(6324529033).R15Rig
    DOGU15_RIG.Parent = ReplicatedStorage
else
    DOGU15_RIG = ReplicatedStorage:WaitForChild("R15Rig")
end

for _,animationData in pairs(ANIMATIONS) do
    local animation = Instance.new("Animation")
    animation.AnimationId = animationData.AnimationId
    animationData.Animation = animation
end

return function(cf)
    local luanoid = require(ReplicatedStorage.Luanoid)()

    luanoid:SetRig(DOGU15_RIG:Clone())

    luanoid.RootPart.CFrame = cf or CFrame.new(0, 10, 0)
    luanoid.Character.Parent = workspace

    for animationName, animationData in pairs(ANIMATIONS) do
        luanoid:LoadAnimation(
            animationData.Animation,
            animationName,
            {
                Priority = animationData[2],
            }
        )
    end

    for _,part in ipairs(luanoid.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
        end
    end

    return luanoid
end