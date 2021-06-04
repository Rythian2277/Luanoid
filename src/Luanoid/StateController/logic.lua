local RAYCAST_CUSHION = 2

local CharacterState = require(script.Parent.Parent.CharacterState)

return function(self)
    local luanoid = self.Luanoid
    local rootPart = luanoid.RootPart
    local curState = luanoid.State
    local groundDistanceGoal = luanoid.HipHeight + rootPart.Size.Y / 2 + RAYCAST_CUSHION
    local currentVelocityY = rootPart.AssemblyLinearVelocity.Y
    local raycastResult = self.RaycastResult

    local newState
    if luanoid.Health <= 0 then
        newState = CharacterState.Dead
    else
        if rootPart:GetRootPart() == rootPart then
            if curState == CharacterState.Jumping then
                if currentVelocityY < 0 then
                    -- We passed the peak of the jump and are now falling downward
                    newState = CharacterState.Falling

                    luanoid.Floor = nil
                end
            else
                if raycastResult and (rootPart.Position - raycastResult.Position).Magnitude < groundDistanceGoal then
                    -- We are grounded
                    if luanoid.Jump then
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
    luanoid.Jump = false

    return newState or curState
end