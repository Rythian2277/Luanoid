local Players = game:GetService("Players")

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

    luanoid:SetNetworkOwner(player)
end

for _,player in pairs(Players:GetPlayers()) do
    makePlayerCharacter(player)
end

Players.PlayerAdded:Connect(makePlayerCharacter)