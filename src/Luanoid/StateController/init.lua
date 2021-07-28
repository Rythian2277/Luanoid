local RAYCAST_CUSHION = 2

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
            if self.StateHandlers[oldState] then
                local leaving = self.StateHandlers[oldState].Leaving
                if leaving then
                    leaving(self, newState)
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
        local rootPart = luanoid.RootPart

        local movetoTarget = luanoid._moveToTarget
        local moveToTickStart = luanoid._moveToTickStart
        local moveToTimeout = luanoid._moveToTimeout
        local movetoDeadzoneRadius = luanoid._moveToDeadzoneRadius

        if movetoTarget then
            if tick() - moveToTickStart < moveToTimeout then
                if typeof(movetoTarget) == "Instance" then
                    movetoTarget = movetoTarget.Position
                end

                if (movetoTarget - rootPart.Position).Magnitude < movetoDeadzoneRadius then
                    luanoid:CancelMoveTo()
                    luanoid.MoveToFinished:Fire(true)
                else
                    luanoid.MoveDirection = (movetoTarget - rootPart.Position).Unit
                end
            else
                luanoid:CancelMoveTo()
                luanoid.MoveToFinished:Fire(false)
            end
        end

        -- Calculating state logic
        --self.RaycastResult = self:CastCollideOnly(rootPart.Position, Vector3.new(0, -(luanoid.HipHeight + rootPart.Size.Y / 2) - RAYCAST_CUSHION, 0))
        do
            local hrpSize = rootPart.Size
            local rayDir = Vector3.new(0, -(luanoid.HipHeight + hrpSize.Y / 2) - RAYCAST_CUSHION, 0)
            local center = self:CastCollideOnly(
                rootPart.Position,
                rayDir
            )
            local topleft = self:CastCollideOnly(
                (rootPart.CFrame * CFrame.new(-hrpSize.X/2, 0, -hrpSize.Z/2)).Position,
                rayDir
            )
            local topright = self:CastCollideOnly(
                (rootPart.CFrame * CFrame.new(hrpSize.X/2, 0, -hrpSize.Z/2)).Position,
                rayDir
            )
            local bottomleft = self:CastCollideOnly(
                (rootPart.CFrame * CFrame.new(-hrpSize.X/2, 0, hrpSize.Z/2)).Position,
                rayDir
            )
            local bottomright = self:CastCollideOnly(
                (rootPart.CFrame * CFrame.new(hrpSize.X/2, 0, hrpSize.Z/2)).Position,
                rayDir
            )
            local raycastResults = {
                center,
                topleft,
                topright,
                bottomleft,
                bottomright,
            }

            table.sort(raycastResults, function(a, b)
                return (a and a.Position.Y or -math.huge) > (b and b.Position.Y or -math.huge)
            end)

            --[[
                self.RaycastResult will be the RaycastResult with the highest
                altitude while self.RaycastResults will detail all Raycasts
            ]]
            self.RaycastResult = raycastResults[1]
            self.RaycastResults = {
                Center = center,
                TopLeft = topleft,
                TopRight = topright,
                bottomleft = bottomleft,
                bottomright = bottomright,
            }
        end
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
