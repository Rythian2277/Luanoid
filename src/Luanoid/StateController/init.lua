local Class = require(script.Parent.Class)
local CharacterState = require(script.Parent.CharacterState)

local DEFAULT_LOGIC_HANDLER = require(script.logic)
local DEFAULT_STATE_HANDLERS = {}
DEFAULT_STATE_HANDLERS[CharacterState.Physics] = require(script.fallingAndPhysics)
DEFAULT_STATE_HANDLERS[CharacterState.Idling] = require(script.idlingAndWalking)
DEFAULT_STATE_HANDLERS[CharacterState.Walking] = DEFAULT_STATE_HANDLERS[CharacterState.Idling]
DEFAULT_STATE_HANDLERS[CharacterState.Jumping] = require(script.jumping)
DEFAULT_STATE_HANDLERS[CharacterState.Falling] = DEFAULT_STATE_HANDLERS[CharacterState.Physics]
DEFAULT_STATE_HANDLERS[CharacterState.Dead] = require(script.dead)

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
        self.RaycastResult = castCollideOnly(luanoid.Character.HumanoidRootPart.Position, Vector3.new(0, -(luanoid.HipHeight + luanoid.Character.HumanoidRootPart.Size.Y / 2), 0))
        local curState = luanoid.State
        local newState = self:Logic(dt)

        -- State handling logic
        self.StateHandlers[newState](self, dt)

        luanoid:ChangeState(newState)
        if newState ~= curState then
            luanoid:StopAnimation(curState.Name)
            luanoid:PlayAnimation(newState.Name)
        end
    end
end

return StateController