local CharacterState = require(script.Parent.Parent.CharacterState)

local Jumping = {}

function Jumping.step(self)
    local luanoid = self.Luanoid

    luanoid._mover.Enabled = false
    luanoid._aligner.Enabled = true

    if luanoid.State ~= CharacterState.Jumping then
        luanoid.Character.HumanoidRootPart:ApplyImpulse(Vector3.new(0, luanoid.JumpPower * luanoid.Character.HumanoidRootPart.AssemblyMass, 0))
    end

    if luanoid.LookDirection.Magnitude > 0 then
        luanoid._aligner.Attachment1.CFrame = CFrame.lookAt(Vector3.new(), luanoid.LookDirection)
    end
end

return Jumping