local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local makeDogu15Rig = require(script:WaitForChild("Dogu15"))
local applyHumanoidDescription = require(script:WaitForChild("R15HumanoidDescriptionApplier"))

Players.CharacterAutoLoads = false

local function makePlayerCharacter(player)
    local luanoid = makeDogu15Rig(CFrame.new(0, 10, 0))
    local character = luanoid.Character
    local humanoidDescription = Players:GetHumanoidDescriptionFromUserId(player.UserId)

    applyHumanoidDescription(luanoid, humanoidDescription)
    humanoidDescription.Parent = character
    character.Name = player.Name
    character.Parent = workspace
    player.Character = character

    --[[
        Luanoids use a custom SetNetworkOwner() method due to Roblox's tendancy
        to reset the NetworkOwner to automatic network ownership which is
        not favorable for characters.

        Another reason is the NetworkOwner is set
        as an attribute for clients to know when they are the NetworkOwner due
        to clients not able to use GetNetworkOwner() which is necessary to
        determine if they are the currently expected machine to simulate the
        Luanoid.
    ]]
    luanoid:SetNetworkOwner(player)
end

local resetEvent = Instance.new("RemoteEvent")
resetEvent.Name = "ResetEvent"
resetEvent.Parent = ReplicatedStorage

resetEvent.OnServerEvent:Connect(function(player)
    player.Character:Destroy()
    makePlayerCharacter(player)
end)

for _,player in pairs(Players:GetPlayers()) do
    makePlayerCharacter(player)
end

Players.PlayerAdded:Connect(makePlayerCharacter)