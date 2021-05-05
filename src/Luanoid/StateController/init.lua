local Class = require(script.Parent.Class)
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
        self._accumulatedTime = 0
        self._currentAccelerationX = 0
        self._currentAccelerationZ = 0
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {luanoid.Character}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.IgnoreWater = false
        self.RaycastParams = raycastParams
    end

    function StateController:step(dt)
        local luanoid = self.Luanoid

        if luanoid._moveToTarget then
            if tick() - luanoid._moveToTickStart < luanoid._moveToTimeout then
                if typeof(luanoid._moveToTarget) == "Instance" then
                    luanoid._moveToTarget = luanoid._moveToTarget.Position
                end

                if math.abs(luanoid._moveToTarget.X - luanoid.Character.HumanoidRootPart.Position.X) < luanoid.Character:GetExtentsSize().X / 2 and math.abs(luanoid._moveToTarget.Y - luanoid.Character.HumanoidRootPart.Position.Y) < luanoid.Character:GetExtentsSize().Y and math.abs(luanoid._moveToTarget.Z - luanoid.Character.HumanoidRootPart.Position.Z) < luanoid.Character:GetExtentsSize().Z / 2 then
                    luanoid:CancelMoveTo()
                    luanoid.MoveToFinished:Fire(true)
                else
                    luanoid.MoveDirection = (luanoid._moveToTarget - luanoid.Character.HumanoidRootPart.Position).Unit
                end
            else
                luanoid:CancelMoveTo()
                luanoid.MoveToFinished:Fire(false)
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
        local hipHeight = luanoid.HipHeight
        local groundDistanceGoal = hipHeight + luanoid.Character.HumanoidRootPart.Size.Y / 2
        local raycastResult = castCollideOnly(luanoid.Character.HumanoidRootPart.Position, Vector3.new(0, -groundDistanceGoal, 0))
        local velocity = luanoid.Character.HumanoidRootPart.AssemblyLinearVelocity

        local currentVelocityX = velocity.X
        local currentVelocityY = velocity.Y
        local currentVelocityZ = velocity.Z

        local curState = luanoid.State
        local newState = curState

        local mover = luanoid._mover
        local aligner = luanoid._aligner

        --[[
            Some states are unique and are never entered through this
            StateController. These states get priority over the rest of the
            state handling logic.
        ]]
        if curState == CharacterState.Ragdoll then
            mover.Enabled = false
            aligner.Enabled = false
            luanoid:Ragdoll(true)
            return curState
        end

        if luanoid.Health <= 0 then
            newState = CharacterState.Dead
        else
            if luanoid.Character.HumanoidRootPart:GetRootPart() == luanoid.Character.HumanoidRootPart then
                if curState == CharacterState.Jumping then
                    if currentVelocityY < 0 then
                        -- We passed the peak of the jump and are now falling downward
                        newState = CharacterState.Falling

                        luanoid.Floor = nil
                    end
                elseif curState ~= CharacterState.Climbing then
                    if raycastResult and (luanoid.Character.HumanoidRootPart.Position - raycastResult.Position).Magnitude < groundDistanceGoal then
                        -- We are grounded
                        if luanoid._jumpInput then
                            luanoid._jumpInput = false
                            newState = CharacterState.Jumping
                        else
                            if luanoid.MoveDirection.Magnitude > 0 then
                                newState = CharacterState.Walking
                            else
                                newState = CharacterState.Idling
                            end
                        end

                        luanoid.Floor = raycastResult.Instance
                    else
                        newState = CharacterState.Falling

                        luanoid.Floor = nil
                    end
                end
            else
                -- HRP isn't RootPart so Character is likely welded to something
                newState = CharacterState.Physics

                luanoid.Floor = nil
            end
        end

        -- State handling logic
        mover.Enabled = true
        aligner.Enabled = true
        if newState == CharacterState.Idling or newState == CharacterState.Walking then

            -- Luanoid calculations used for idle/walking state
            local groundPos = raycastResult.Position
            local targetVelocity = Vector3.new()

            luanoid.MoveDirection = Vector3.new(luanoid.MoveDirection.X, 0, luanoid.MoveDirection.Z)
            if luanoid.MoveDirection.Magnitude > 0 then
                targetVelocity = Vector3.new(luanoid.MoveDirection.X, 0, luanoid.MoveDirection.Z).Unit * luanoid.WalkSpeed
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
            local targetHeight = groundPos.Y + hipHeight + luanoid.Character.HumanoidRootPart.Size.Y / 2
            local currentHeight = luanoid.Character.HumanoidRootPart.Position.Y
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

            mover.Force = Vector3.new(aX, aUp, aZ) * luanoid.Character.HumanoidRootPart.AssemblyMass

            -- Look direction stuff
            if luanoid.MoveDirection.Magnitude > 0 and luanoid.AutoRotate then
                luanoid.LookDirection = luanoid.MoveDirection
            end

            if luanoid.LookDirection.Magnitude > 0 then
                aligner.Attachment1.CFrame = CFrame.lookAt(Vector3.new(), luanoid.LookDirection)
            end

        elseif newState == CharacterState.Jumping then

            mover.Enabled = false
            if curState ~= CharacterState.Jumping then
                luanoid.Character.HumanoidRootPart:ApplyImpulse(Vector3.new(0, luanoid.JumpPower * luanoid.Character.HumanoidRootPart.AssemblyMass, 0))
            end

            if luanoid.LookDirection.Magnitude > 0 then
                aligner.Attachment1.CFrame = CFrame.lookAt(Vector3.new(), luanoid.LookDirection)
            end

        elseif newState == CharacterState.Falling or newState == CharacterState.Physics then

            mover.Enabled = false

        elseif newState == CharacterState.Dead then

            -- Stop the simulation and begin ragdolling the Luanoid
            mover.Enabled = false
            luanoid:PauseSimulation()
            luanoid:Ragdoll(true)

        end

        luanoid:ChangeState(newState)
        if newState ~= curState then
            luanoid:StopAnimation(curState.Name)
            luanoid:PlayAnimation(newState.Name)
        end
    end
end

return StateController