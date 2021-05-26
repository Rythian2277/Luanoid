local Class = require(script.Parent.Class)
local CharacterState = require(script.Parent.CharacterState)

local DEFAULT_LOGIC_HANDLER = require(script.logic)
local DEFAULT_STATE_HANDLERS = {}
DEFAULT_STATE_HANDLERS[CharacterState.Physics] = require(script.FallingAndPhysics)
DEFAULT_STATE_HANDLERS[CharacterState.Idling] = require(script.IdlingAndWalking)
DEFAULT_STATE_HANDLERS[CharacterState.Walking] = DEFAULT_STATE_HANDLERS[CharacterState.Idling]
DEFAULT_STATE_HANDLERS[CharacterState.Jumping] = require(script.Jumping)
DEFAULT_STATE_HANDLERS[CharacterState.Falling] = DEFAULT_STATE_HANDLERS[CharacterState.Physics]
DEFAULT_STATE_HANDLERS[CharacterState.Dead] = require(script.Dead)

local StateController = Class() do
    function StateController:init(luanoid)
        self.Luanoid = luanoid
        self._accumulatedTime = 0
        self._currentAccelerationX = 0
        self._currentAccelerationZ = 0

        self.Logic = DEFAULT_LOGIC_HANDLER
        self.StateHandlers = {}

        for i,v in pairs(DEFAULT_STATE_HANDLERS) do
            self.StateHandlers[i] = v
        end

        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {luanoid.Character}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.IgnoreWater = false
        self.RaycastParams = raycastParams

        luanoid.StateChanged:Connect(function(newState, oldState)
            if self.StateHandlers[newState] then
                local leaving = self.StateHandlers[newState].Leaving
                if leaving then
                    leaving(self)
                end
            end
            if self.StateHandlers[newState] then
                if newState ~= oldState then
                    local entering = self.StateHandlers[newState].Entering
                    if entering then
                        entering(self)
                    end
                end
            end
        end)
    end

    function StateController:CastCollideOnly(origin, dir)
        local originalFilter = self.RaycastParams.FilterDescendantsInstances
        local tempFilter = self.RaycastParams.FilterDescendantsInstances

        repeat
            local result = workspace:Raycast(origin, dir, self.RaycastParams)
            if result then
                if result.Instance.CanCollide then
                    self.RaycastParams.FilterDescendantsInstances = originalFilter
                    return result
                else
                    table.insert(tempFilter, result.Instance)
                    self.RaycastParams.FilterDescendantsInstances = tempFilter
                    origin = result.Position
                    dir = dir.Unit * (dir.Magnitude - (origin - result.Position).Magnitude)
                end
            else
                self.RaycastParams.FilterDescendantsInstances = originalFilter
                return nil
            end
        until not result
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

        -- Calculating state logic
        self.RaycastResult = self:CastCollideOnly(luanoid.Character.HumanoidRootPart.Position, Vector3.new(0, -(luanoid.HipHeight + luanoid.Character.HumanoidRootPart.Size.Y / 2), 0))
        local curState = luanoid.State
        local newState = self:Logic(dt)

        -- State handling logic
        if self.StateHandlers[newState] then
            self.StateHandlers[newState].step(self, dt)
        end

        luanoid:ChangeState(newState)
        if newState ~= curState then
            luanoid:StopAnimation(curState.Name)
            luanoid:PlayAnimation(newState.Name)
        end
    end
end

return StateController