--[[
    Applies HumanoidDescriptions to R15-like rigs such as Dogu15. Due to
    Luanoids not using Humanoids this will not apply Shirts, Pants, or
    T-Shirts. This will not be implemented in the form of ApplyDescription()
    due to Luanoid's support for rigs beyond R6 and R15.
]]

local InsertService = game:GetService("InsertService")
local MarketPlaceService = game:GetService("MarketplaceService")

local buildRigFromAttachments = require(script.Parent.buildRigFromAttachments)

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

local function getLimbParts(limbId)
    local assetTypeId = MarketPlaceService:GetProductInfo(limbId).AssetTypeId

    if assetTypeId == 17 then
        local head = Instance.new("Part")
        head.Name = "Head"
        head.Size = Vector3.new(2, 1, 1)

        local mesh = InsertService:LoadAsset(limbId).Mesh
        mesh.Parent = head

        local faceCenterAttachment = Instance.new("Attachment")
        faceCenterAttachment.Name = "FaceCenterAttachment"
        faceCenterAttachment.Position = mesh.FaceCenterAttachment.Value
        faceCenterAttachment.Parent = head

        local faceFrontAttachment = Instance.new("Attachment")
        faceFrontAttachment.Name = "FaceFrontAttachment"
        faceFrontAttachment.Position = mesh.FaceFrontAttachment.Value
        faceFrontAttachment.Parent = head

        local hairAttachment = Instance.new("Attachment")
        hairAttachment.Name = "HairAttachment"
        hairAttachment.Position = mesh.HairAttachment.Value
        hairAttachment.Parent = head

        local hatAttachment = Instance.new("Attachment")
        hatAttachment.Name = "HatAttachment"
        hatAttachment.Position = mesh.HatAttachment.Value
        hatAttachment.Parent = head

        local neckRigAttachment = Instance.new("Attachment")
        neckRigAttachment.Name = "NeckRigAttachment"
        neckRigAttachment.Position = mesh.NeckRigAttachment.Value
        neckRigAttachment.Parent = head

        mesh:ClearAllChildren()
        return {head}
    else
        return InsertService:LoadAsset(limbId).R15Fixed:GetChildren()
    end
end

local function applyAnimation(luanoid, animationId, animationName)
    luanoid:LoadAnimation(getAnimation(animationId), animationName)
end

local function applyLimb(character, limbId)
    for _,part in pairs(getLimbParts(limbId)) do
        part.Material = Enum.Material.SmoothPlastic
        part.CanCollide = false
        part.Parent = character
    end
end

local function breakAndDestroy(parts)
    for _,part in ipairs(parts) do
        part:BreakJoints()
        part:Destroy()
    end
end

return function(luanoid, humanoidDescription)
    local character = luanoid.Character

    if humanoidDescription.ClimbAnimation ~= 0 then
        applyAnimation(luanoid, humanoidDescription.ClimbAnimation, "Climbing")
    end
    if humanoidDescription.FallAnimation ~= 0 then
        applyAnimation(luanoid, humanoidDescription.FallAnimation, "Falling")
    end
    if humanoidDescription.IdleAnimation ~= 0 then
        applyAnimation(luanoid, humanoidDescription.IdleAnimation, "Idling")
    end
    if humanoidDescription.JumpAnimation ~= 0 then
        applyAnimation(luanoid, humanoidDescription.JumpAnimation, "Jumping")
    end
    if humanoidDescription.RunAnimation ~= 0 then
        applyAnimation(luanoid, humanoidDescription.RunAnimation, "Running")
    end
    if humanoidDescription.SwimAnimation ~= 0 then
        applyAnimation(luanoid, humanoidDescription.SwimAnimation, "Swimming")
    end
    if humanoidDescription.WalkAnimation ~= 0 then
        applyAnimation(luanoid, humanoidDescription.WalkAnimation, "Walking")
    end

    if humanoidDescription.Head ~= 0 then
        breakAndDestroy {
            character.Head,
        }
        applyLimb(character, humanoidDescription.Head)
    end
    if humanoidDescription.LeftArm ~= 0 then
        breakAndDestroy {
            character.LeftUpperArm,
            character.LeftLowerArm,
            character.LeftHand,
        }
        applyLimb(character, humanoidDescription.LeftArm)
    end
    if humanoidDescription.LeftLeg ~= 0 then
        breakAndDestroy {
            character.LeftUpperLeg,
            character.LeftLowerLeg,
            character.LeftFoot,
        }
        applyLimb(character, humanoidDescription.LeftLeg)
    end
    if humanoidDescription.RightArm ~= 0 then
        breakAndDestroy {
            character.RightUpperArm,
            character.RightLowerArm,
            character.RightHand,
        }
        applyLimb(character, humanoidDescription.RightArm)
    end
    if humanoidDescription.RightLeg ~= 0 then
        breakAndDestroy {
            character.RightUpperLeg,
            character.RightLowerLeg,
            character.RightFoot,
        }
        applyLimb(character, humanoidDescription.RightLeg)
    end
    if humanoidDescription.Torso ~= 0 then
        breakAndDestroy {
            character.UpperTorso,
            character.LowerTorso,
        }
        applyLimb(character, humanoidDescription.Torso)
    end
    buildRigFromAttachments(character)

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

    if humanoidDescription.Face ~= 0 then
        local existingFace = character.Head:FindFirstChild("face")
        if existingFace then
            existingFace:Destroy()
        end

        getFace(humanoidDescription.Face).Parent = character.Head
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