--[[
    Applies HumanoidDescriptions to R15-like rigs such as Dogu15. Due to
    Luanoids not using Humanoids this will not apply Shirts, Pants, or
    T-Shirts. This will not be implemented in the form of ApplyDescription()
    due to Luanoid's support for rigs beyond R6 and R15.
]]

local InsertService = game:GetService("InsertService")
local MarketPlaceService = game:GetService("MarketplaceService")

local function getAnimation(animationId)
    local assetTypeId = MarketPlaceService:GetProductInfo(animationId).AssetTypeId
    local animation

    if assetTypeId == 24 then
        animation = Instance.new("Animation")
        animation.AnimationId = animationId
    else
        animation = InsertService:LoadAsset(animationId):FindFirstChildWhichIsA("Animation", true)
    end

    return animation
end

local function getFace(faceId)
    return InsertService:LoadAsset(faceId):FindFirstChildWhichIsA("Decal", true)
end

return function(luanoid, humanoidDescription)
    local character = luanoid.Character

    if humanoidDescription.Face ~= 0 then
        local existingFace = character.Head:FindFirstChild("face")
        if existingFace then
            existingFace:Destroy()
        end

        getFace(humanoidDescription.Face).Parent = character.Head
    end

    character.Head.Color = humanoidDescription.HeadColor
    character.LeftUpperArm.Color = humanoidDescription.LeftArmColor
    character.LeftLowerArm.Color = humanoidDescription.LeftArmColor
    character.LeftHand.Color = humanoidDescription.LeftArmColor
    character.LeftUpperLeg.Color = humanoidDescription.LeftLegColor
    character.LeftLowerLeg.Color = humanoidDescription.LeftLegColor
    character.LeftFoot.Color = humanoidDescription.LeftArmColor
    character.RightUpperArm.Color = humanoidDescription.RightArmColor
    character.RightLowerArm.Color = humanoidDescription.RightArmColor
    character.RightHand.Color = humanoidDescription.RightArmColor
    character.RightUpperLeg.Color = humanoidDescription.RightLegColor
    character.RightLowerLeg.Color = humanoidDescription.RightLegColor
    character.RightFoot.Color = humanoidDescription.RightArmColor
    character.UpperTorso.Color = humanoidDescription.TorsoColor
    character.LowerTorso.Color = humanoidDescription.TorsoColor

    if humanoidDescription.ClimbAnimation ~= 0 then
        luanoid:LoadAnimation(getAnimation(humanoidDescription.ClimbAnimation), "Climbing")
    end
    if humanoidDescription.FallAnimation ~= 0 then
        luanoid:LoadAnimation(getAnimation(humanoidDescription.FallAnimation), "Falling")
    end
    if humanoidDescription.IdleAnimation ~= 0 then
        luanoid:LoadAnimation(getAnimation(humanoidDescription.IdleAnimation), "Idling")
    end
    if humanoidDescription.JumpAnimation ~= 0 then
        luanoid:LoadAnimation(getAnimation(humanoidDescription.JumpAnimation), "Jumping")
    end
    if humanoidDescription.RunAnimation ~= 0 then
        luanoid:LoadAnimation(getAnimation(humanoidDescription.RunAnimation), "Running")
    end
    if humanoidDescription.SwimAnimation ~= 0 then
        luanoid:LoadAnimation(getAnimation(humanoidDescription.SwimAnimation), "Swimming")
    end
    if humanoidDescription.WalkAnimation ~= 0 then
        luanoid:LoadAnimation(getAnimation(humanoidDescription.WalkAnimation), "Walking")
    end

    local accessoryIds = {}
    table.insert(accessoryIds, humanoidDescription.BackAccessory:split(","))
    table.insert(accessoryIds, humanoidDescription.FaceAccessory:split(","))
    table.insert(accessoryIds, humanoidDescription.FrontAccessory:split(","))
    table.insert(accessoryIds, humanoidDescription.HairAccessory:split(","))
    table.insert(accessoryIds, humanoidDescription.HatAccessory:split(","))
    table.insert(accessoryIds, humanoidDescription.NeckAccessory:split(","))
    table.insert(accessoryIds, humanoidDescription.ShouldersAccessory:split(","))
    table.insert(accessoryIds, humanoidDescription.WaistAccessory:split(","))

    for _,accessoryGroup in pairs(accessoryIds) do
        for _,accessoryId in pairs(accessoryGroup) do
            accessoryId = tonumber(accessoryId)

            -- Sometimes the accessoryId is nil, not sure why
            if accessoryId then
                local accessory = InsertService:LoadAsset(accessoryId):FindFirstChildWhichIsA("Accessory")
                luanoid:AddAccessory(accessory)
            end
        end
    end
end