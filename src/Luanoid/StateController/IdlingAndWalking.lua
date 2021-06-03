local function StepSpring(framerate, position, velocity, destination, stiffness, damping, precision)
	local displacement = position - destination
	local springForce = -stiffness * displacement
	local dampForce = -damping * velocity

	local acceleration = springForce + dampForce
	local newVelocity = velocity + acceleration * framerate
	local newPosition = position + velocity * framerate

	if math.abs(newVelocity) < precision and math.abs(destination - newPosition) < precision then
		return destination, 0
	end

	return newPosition, newVelocity
end

local IdlingAndWalking = {}

function IdlingAndWalking.step(self, dt)
    local luanoid = self.Luanoid
    local rootPart = luanoid.RootPart
    local hipHeight = luanoid.HipHeight
    local velocity = rootPart.AssemblyLinearVelocity
    local currentVelocityX = velocity.X
    local currentVelocityY = velocity.Y
    local currentVelocityZ = velocity.Z
    local mover = luanoid._mover
    local aligner = luanoid._aligner
    local groundPos = self.RaycastResult.Position
    local targetVelocity = Vector3.new()

    local moveDir = luanoid.MoveDirection
    if moveDir.Magnitude > 0 then
        targetVelocity = Vector3.new(moveDir.X, 0, moveDir.Z).Unit * luanoid.WalkSpeed
    end

    self._accumulatedTime = (self._accumulatedTime or 0) + dt

    while self._accumulatedTime >= 1 / 240 do
        self._accumulatedTime = self._accumulatedTime - 1 / 240
        currentVelocityX, self._currentAccelerationX = StepSpring(
            1 / 240,
            currentVelocityX,
            self._currentAccelerationX or 0,
            targetVelocity.X,
            170,
            22,
            0.001
        )
        currentVelocityZ, self._currentAccelerationZ = StepSpring(
            1 / 240,
            currentVelocityZ,
            self._currentAccelerationZ or 0,
            targetVelocity.Z,
            170,
            22,
            0.001
        )
    end
    local targetHeight = groundPos.Y + hipHeight + rootPart.Size.Y / 2
    local currentHeight = rootPart.Position.Y
    local aUp
    local t = 0.05
    aUp = workspace.Gravity + 2*((targetHeight - currentHeight) - currentVelocityY*t)/(t*t)
    local deltaHeight = math.max((targetHeight - currentHeight)*1.01, 0)
    deltaHeight = math.min(deltaHeight, hipHeight)
    local maxUpVelocity = math.sqrt(2.0*workspace.Gravity*deltaHeight)
    local maxUpImpulse = math.max((maxUpVelocity - currentVelocityY)*60, 0)
    aUp = math.min(aUp, maxUpImpulse)
    aUp = math.max(-1, aUp)

    local aX = self._currentAccelerationX
    local aZ = self._currentAccelerationZ

    mover.Enabled = true
    aligner.Enabled = true
    mover.Force = Vector3.new(aX, aUp, aZ) * rootPart.AssemblyMass

    -- Look direction stuff
    if luanoid.MoveDirection.Magnitude > 0 and luanoid.AutoRotate then
        luanoid.LookDirection = luanoid.MoveDirection
    end

    if luanoid.LookDirection.Magnitude > 0 then
        aligner.Attachment1.CFrame = CFrame.lookAt(Vector3.new(), luanoid.LookDirection)
    end

    local animationTrack = luanoid.AnimationTracks.Walking
    if animationTrack then
        animationTrack:AdjustSpeed(luanoid.WalkSpeed / 16)
    end
end

return IdlingAndWalking