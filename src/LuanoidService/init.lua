local LuanoidClass = require(script.Luanoid)
local buildRigFromAttachments = require(script.buildRigFromAttachments)

local luanoids = setmetatable({}, {__mode = "kv"})

local LuanoidService = {}

function LuanoidService.new(...)
    local luanoid = LuanoidClass(...)
    luanoids[luanoid.Character] = luanoid
    return luanoid
end

function LuanoidService:GetLuanoidFromCharacter(character)
    return luanoids[character]
end

LuanoidService.buildRigFromAttachments = buildRigFromAttachments

return LuanoidService