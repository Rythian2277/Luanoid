local Class = require(3696101309)
local CharacterState = require(script.Parent.CharacterState)

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

local StateController = Class() do
    function StateController:init(luanoid)
        self.Luanoid = luanoid
        self.Floor = nil
        self._accumulatedTime = 0
        self._currentAccelerationX = 0
        self._currentAccelerationZ = 0
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {self.Luanoid.Character}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.IgnoreWater = false
        self.RaycastParams = raycastParams
    end

    function StateController:step(dt)
        if self.Luanoid.MoveToTarget then
            if tick() - self.Luanoid._moveToTickStart < self.Luanoid.MoveToTimeout then
                if typeof(self.Luanoid.MoveToTarget) == "Instance" then
                    self.Luanoid.MoveToTarget = self.Luanoid.MoveToTarget.Position
                end

                if math.abs(self.Luanoid.MoveToTarget.X - self.Luanoid.Character.HumanoidRootPart.Position.X) < self.Luanoid.Character:GetExtentsSize().X / 2 and math.abs(self.Luanoid.MoveToTarget.Y - self.Luanoid.Character.HumanoidRootPart.Position.Y) < self.Luanoid.Character:GetExtentsSize().Y and math.abs(self.Luanoid.MoveToTarget.Z - self.Luanoid.Character.HumanoidRootPart.Position.Z) < self.Luanoid.Character:GetExtentsSize().Z / 2 then
                    self.Luanoid:CancelMoveTo()
                    self.Luanoid.MoveToFinished:Fire(true)
                else
                    self.Luanoid.MoveDir = (self.Luanoid.MoveToTarget - self.Luanoid.Character.HumanoidRootPart.Position).Unit
                end
            else
                self.Luanoid:CancelMoveTo()
                self.Luanoid.MoveToFinished:Fire(false)
            end
        end

        local function castCollideOnly(origin, dir)
            --[[
                Shallow copies the original FilterDescendantsInstances table
                due to objects with CanCollide disabled being inserted which
                can become CanCollide enabled later.
            ]]
            local originalFilter = {table.unpack(self.RaycastParams.FilterDescendantsInstances)}

            repeat
                local result = workspace:Raycast(origin, dir, self.RaycastParams)
                if result then
                    if result.Instance.CanCollide then
                        self.RaycastParams.FilterDescendantsInstances = originalFilter
                        return result
                    else
                        table.insert(self.RaycastParams.FilterDescendantsInstances, result.Instance)
                        origin = result.Position
                        dir = dir.Unit * (dir.Magnitude - (origin - result.Position).Magnitude)
                    end
                else
                    self.RaycastParams.FilterDescendantsInstances = originalFilter
                    return nil
                end
            until not result
        end

        -- Calculating state logic
        local hipHeight = self.Luanoid.HipHeight
        local groundDistanceGoal = hipHeight + self.Luanoid.Character.HumanoidRootPart.Size.Y / 2
        local raycastResult = castCollideOnly(self.Luanoid.Character.HumanoidRootPart.Position, Vector3.new(0, -groundDistanceGoal, 0))
        local velocity = self.Luanoid.Character.HumanoidRootPart.AssemblyLinearVelocity

        local currentVelocityX = velocity.X
        local currentVelocityY = velocity.Y
        local currentVelocityZ = velocity.Z

        local curState = self.Luanoid.State
        local newState = curState

        if self.Luanoid.Character.HumanoidRootPart:GetRootPart() == self.Luanoid.Character.HumanoidRootPart then
            if curState == CharacterState.Jumping then
                if currentVelocityY < 0 then
                    -- We passed the peak of the jump and are now falling downward
                    newState = CharacterState.Unsimulated

                    self.Floor = nil
                end
            elseif curState ~= CharacterState.Climbing then
                if raycastResult and (self.Luanoid.Character.HumanoidRootPart.Position - raycastResult.Position).Magnitude < groundDistanceGoal then
                    -- We are grounded
                    if self.Luanoid.JumpInput then
                        self.Luanoid.JumpInput = false
                        newState = CharacterState.Jumping
                    else
                        if self.Luanoid.MoveDir.Magnitude > 0 then
                            newState = CharacterState.Walking
                        else
                            newState = CharacterState.Idling
                        end
                    end

                    self.Floor = raycastResult.Instance
                else
                    newState = CharacterState.Unsimulated

                    self.Floor = nil
                end
            end
        else
            -- HRP isn't RootPart so Character is likely welded to something
            newState = CharacterState.Unsimulated

            self.Floor = nil
        end

        -- State handling logic
        local mover = self.Luanoid._mover
        local aligner = self.Luanoid._aligner

        if newState == CharacterState.Idling or newState == CharacterState.Walking then

            -- Luanoid calculations used for idle/walking state
            local groundPos = raycastResult.Position
            local targetVelocity = Vector3.new()

            self.Luanoid.MoveDir = Vector3.new(self.Luanoid.MoveDir.X, 0, self.Luanoid.MoveDir.Z)
            if self.Luanoid.MoveDir.Magnitude > 0 then
                targetVelocity = Vector3.new(self.Luanoid.MoveDir.X, 0, self.Luanoid.MoveDir.Z).Unit * self.Luanoid.WalkSpeed
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
                    26,
                    0.001
                )
                currentVelocityZ, self._currentAccelerationZ = StepSpring(
                    1 / 240,
                    currentVelocityZ,
                    self._currentAccelerationZ or 0,
                    targetVelocity.Z,
                    170,
                    26,
                    0.001
                )
            end
            local targetHeight = groundPos.Y + hipHeight + self.Luanoid.Character.HumanoidRootPart.Size.Y / 2
            local currentHeight = self.Luanoid.Character.HumanoidRootPart.Position.Y
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

            mover.Force = Vector3.new(aX, aUp, aZ) * self.Luanoid.Character.HumanoidRootPart.AssemblyMass

            -- Look direction stuff
            if self.Luanoid.MoveDir.Magnitude > 0 and self.Luanoid.AutoRotate then
                self.Luanoid.LookDir = self.Luanoid.MoveDir
            end

            if self.Luanoid.LookDir.Magnitude > 0 then
                aligner.Attachment1.CFrame = CFrame.lookAt(Vector3.new(), self.Luanoid.LookDir)
            end

        elseif newState == CharacterState.Jumping then

            mover.Force = Vector3.new()
            if curState ~= CharacterState.Jumping then
                self.Luanoid.Character.HumanoidRootPart:ApplyImpulse(Vector3.new(0, self.Luanoid.JumpPower * self.Luanoid.Character.HumanoidRootPart.AssemblyMass, 0))
            end

            if self.Luanoid.LookDir.Magnitude > 0 then
                aligner.Attachment1.CFrame = CFrame.lookAt(Vector3.new(), self.Luanoid.LookDir)
            end

        elseif newState == CharacterState.Unsimulated then

            mover.Force = Vector3.new()

        end

        return newState
    end
end

return StateController