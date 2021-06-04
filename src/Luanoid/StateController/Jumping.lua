local CharacterState = require(script.Parent.Parent.CharacterState)

local Jumping = {}

function Jumping.Entering(self)
    self.Luanoid.Jumping:Fire(true)
end

function Jumping.Leaving(self)
    self.Luanoid.Jumping:Fire(false)
end

function Jumping.step(self)
    local luanoid = self.Luanoid

    luanoid._mover.Enabled = false
    luanoid._aligner.Enabled = true

    local rootPart = luanoid.RootPart
    if luanoid.State ~= CharacterState.Jumping then
        rootPart:ApplyImpulse(Vector3.new(0, luanoid.JumpPower * rootPart.AssemblyMass, 0))
    end

    if luanoid.LookDirection.Magnitude > 0 then
        luanoid._aligner.Attachment1.CFrame = CFrame.lookAt(Vector3.new(), luanoid.LookDirection)
    end
end

return Jumping