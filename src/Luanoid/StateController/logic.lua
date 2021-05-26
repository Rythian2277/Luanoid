local CharacterState = require(script.Parent.Parent.CharacterState)

return function(self)
    local luanoid = self.Luanoid
    local curState = luanoid.State
    local groundDistanceGoal = luanoid.HipHeight + luanoid.Character.HumanoidRootPart.Size.Y / 2
    local currentVelocityY = luanoid.Character.HumanoidRootPart.AssemblyLinearVelocity.Y
    local raycastResult = self.RaycastResult

    local newState
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
            else
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

    return newState or curState
end