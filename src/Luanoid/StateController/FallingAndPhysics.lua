local FallingAndPhysics = {}

function FallingAndPhysics.Entering(self)
	local luanoid = self.Luanoid
	luanoid.FreeFalling:Fire(true)

    local rootPart = luanoid.RootPart
	local assemblyVel = rootPart.AssemblyLinearVelocity
	if math.abs(assemblyVel.Y) > 100 then
		rootPart.AssemblyLinearVelocity = Vector3.new(assemblyVel.X, 0, assemblyVel.Z)
	end
end

function FallingAndPhysics.Leaving(self)
	local luanoid = self.Luanoid
	luanoid.FreeFalling:Fire(false)

    local rootPart = luanoid.RootPart
	local assemblyVel = rootPart.AssemblyLinearVelocity
	if math.abs(assemblyVel.Y) > 100 then
		rootPart.AssemblyLinearVelocity = Vector3.new(assemblyVel.X, 0, assemblyVel.Z)
	end
end

function FallingAndPhysics.step(self)
    local luanoid = self.Luanoid
    luanoid._mover.Enabled = false
	luanoid._aligner.Enabled = false

	local rootPart = luanoid.RootPart
	local assemblyVel = rootPart.AssemblyLinearVelocity
	if assemblyVel.Y > 15 then
        --[[
            Stops the Luanoid from bouncing back up when falling from high
            speeds. A longer than usual raycast is used due to the Luanoids
            often not detecting the ground in time.
        ]]
		local raycastResult = self:CastCollideOnly(rootPart.Position, Vector3.new(0, -20, 0))

		if raycastResult then
			rootPart.AssemblyLinearVelocity = Vector3.new(assemblyVel.X, 0, assemblyVel.Z)
			rootPart.CFrame *= CFrame.new(0, raycastResult.Position.Y + luanoid.HipHeight + rootPart.Size.Y / 2 - rootPart.Position.Y, 0)
		end
	elseif assemblyVel.Magnitude < 0.1 then
		rootPart:ApplyImpulse(Vector3.new(0, rootPart.AssemblyMass * luanoid.JumpPower, 0))
	end
end

return FallingAndPhysics