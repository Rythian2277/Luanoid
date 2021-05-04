--[[
    This example spawns, rigs, and animates a Luanoid using a modified version
    of Dogutsune's Dogu15 rig which is a R15 rig with mesh deformation. This
    example depends on HttpService being enabled to insert the rig.

    https://devforum.roblox.com/t/dogu15-an-improved-r15-rig-mesh-deformation/532832
]]

local ANIMATIONS = {
    Climbing = {
        "http://www.roblox.com/asset/?id=507765644",
    },
    Falling = {
        "http://www.roblox.com/asset/?id=507767968",
    },
    Idling = {
        "http://www.roblox.com/asset/?id=507766388",
        "http://www.roblox.com/asset/?id=507766666",
    },
    Jumping = {
        "http://www.roblox.com/asset/?id=507765000",
    },
    Swimming = {
        "http://www.roblox.com/asset/?id=913384386",
    },
    Walking = {
        "http://www.roblox.com/asset/?id=913402848",
    },
}
local DOGU15_RIG = game:GetService("InsertService"):LoadAsset(6324529033).R15Rig

for _,variants in pairs(ANIMATIONS) do
    for i, assetId in ipairs(variants) do
        local animation = Instance.new("Animation")
        animation.AnimationId = assetId
        variants[i] = animation
    end
end

return function(cf)
    local luanoid = require(game:GetService("ReplicatedStorage").Luanoid)()

    luanoid:MountRig(DOGU15_RIG:Clone())

    luanoid.RootPart.CFrame = cf or CFrame.new(0, 10, 0)
    luanoid.Character.Parent = workspace

    for animationName, variants in pairs(ANIMATIONS) do
        for _,animation in ipairs(variants) do
            luanoid:LoadAnimation(animation, animationName)
        end
    end

    return luanoid
end