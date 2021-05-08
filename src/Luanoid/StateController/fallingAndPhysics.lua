local fallingAndPhysics = {}

function fallingAndPhysics.step(self)
    local luanoid = self.Luanoid
    luanoid._mover.Enabled = false
    luanoid._aligner.Enabled = false
end

return fallingAndPhysics