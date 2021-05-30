local Dead = {}

function Dead.Entering(self)
    self.Luanoid.Died:Fire(true)
    self.Luanoid:StopAnimations()
    self.Luanoid:PauseSimulation()
end

function Dead.Leaving(self)
    self.Luanoid.Died:Fire(false)
end

function Dead.step(self)
    local luanoid = self.Luanoid

    luanoid._mover.Enabled = false
    luanoid._aligner.Enabled = false
    luanoid:PauseSimulation()
end

return Dead