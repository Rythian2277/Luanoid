local FRAMERATE = 1 / 240
local STIFFNESS = 300
local DAMPING = 30
local PRECISION = 0.001
local POP_TIME = 0.05

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

    while self._accumulatedTime >= FRAMERATE do
        self._accumulatedTime = self._accumulatedTime - FRAMERATE

        currentVelocityX, self._currentAccelerationX = StepSpring(
            FRAMERATE,
            currentVelocityX,
            self._currentAccelerationX or 0,
            targetVelocity.X,
            STIFFNESS,
            DAMPING,
            PRECISION
        )

        currentVelocityZ, self._currentAccelerationZ = StepSpring(
            FRAMERATE,
            currentVelocityZ,
            self._currentAccelerationZ or 0,
            targetVelocity.Z,
            STIFFNESS,
            DAMPING,
            PRECISION
        )
    end

    local g = workspace.Gravity
    local targetHeight = groundPos.Y + hipHeight + rootPart.Size.Y / 2
    local currentHeight = rootPart.Position.Y
    local aUp = g + 2*((targetHeight - currentHeight) - currentVelocityY*POP_TIME)/(POP_TIME^2)
    local deltaHeight = math.max((targetHeight - currentHeight)*1.01, 0)
    deltaHeight = math.min(deltaHeight, hipHeight)
    local maxUpVelocity = math.sqrt(2.0*g*deltaHeight)
    local maxUpImpulse = math.max((maxUpVelocity - currentVelocityY)*60, 0)
    aUp = math.min(aUp, maxUpImpulse)
    aUp = math.max(-1, aUp)

    local aX = self._currentAccelerationX
    local aZ = self._currentAccelerationZ

    local normal = self.RaycastResult.Normal
    local maxSlopeAngle = math.rad(luanoid.MaxSlopeAngle)
    local maxInclineTan = math.tan(maxSlopeAngle)
    local maxInclineStartTan = math.tan(math.max(0, maxSlopeAngle - math.rad(2.5)))
    local steepness = math.clamp((Vector2.new(normal.X, normal.Z).Magnitude/normal.Y - maxInclineStartTan) / (maxInclineTan - maxInclineStartTan), 0, 1)
    if steepness > 0 then
        -- deflect control acceleration off slope normal, discarding the parallell component
        local aControl = Vector3.new(aX, 0, aZ)
        local dot = math.min(0, normal:Dot(aControl)) -- clamp below 0, don't subtract forces away from normal
        local aInto = normal*dot
        local aPerp = aControl - aInto
        local aNew = aPerp
        aNew = aControl:Lerp(aNew, steepness)
        aX, aZ = aNew.X, aNew.Z
        -- mass on a frictionless incline: net acceleration = g * sin(incline angle)
        local aGravity = Vector3.new(0, -g, 0)
        dot = math.min(0, normal:Dot(aGravity))
        aInto = normal*dot
        aPerp = aGravity - aInto
        aNew = aPerp
        aX, aZ = aX + aNew.X*steepness, aZ + aNew.Z*steepness
        aUp = aUp + aNew.Y*steepness
        aUp = math.max(0, aUp)
    end

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