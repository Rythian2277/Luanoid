local FallingAndPhysics = {}

function FallingAndPhysics.Entering(self)
    self.Luanoid.FreeFalling:Fire(true)
end

function FallingAndPhysics.Leaving(self)
    self.Luanoid.FreeFalling:Fire(false)
end

function FallingAndPhysics.step(self)
    local luanoid = self.Luanoid
    luanoid._mover.Enabled = false
    luanoid._aligner.Enabled = false
end

return FallingAndPhysics