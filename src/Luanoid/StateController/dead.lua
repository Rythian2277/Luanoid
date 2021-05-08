local Dead = {}

function Dead.step(self)
    local luanoid = self.Luanoid

    luanoid._mover.Enabled = false
    luanoid._aligner.Enabled = false
    luanoid:PauseSimulation()
end

return Dead