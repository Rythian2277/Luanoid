--// File Name: Luanoid (Based on Cardinoid, separated from Cardinal Engine and built in a proper class structure.)
--// Creator: Rythian Smythe / Rythian2277
--// Date: April 18, 2021

local Class = require(script.Class)
local Event = require(script.Event)
local StateController = require(script.StateController)
local CharacterState = require(script.CharacterState)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Luanoid = Class() do
    function Luanoid:init(luanoidParams)
        if typeof(luanoidParams) == "Instance" then --// Luanoid model exists, just mounting onto the model.
            local humanoidRootPart = luanoidParams:WaitForChild("HumanoidRootPart")
            self.Character = luanoidParams
			self._mover = humanoidRootPart.Mover
			self._aligner = humanoidRootPart.Aligner
            self.Animator = self.Character.AnimationController.Animator
			self.RootPart = humanoidRootPart
        else --// Needs to be created
            luanoidParams = luanoidParams or {}

            self.Character = Instance.new("Model")
            self.Character.Name = luanoidParams.Name or "NPC"
            local moveDirAttachment = Instance.new("Attachment")
            moveDirAttachment.Name = "MoveDirection"

            local lookDirAttachment = Instance.new("Attachment")
            lookDirAttachment.Name = "LookDirection"

            local humanoidRootPart = Instance.new("Part")
            humanoidRootPart.Name = "HumanoidRootPart"
            humanoidRootPart.Transparency = 1
            humanoidRootPart.Size = Vector3.new(1,1,1)
            humanoidRootPart.RootPriority = 127
            humanoidRootPart.Parent = self.Character

            local vectorForce = Instance.new("VectorForce")
            vectorForce.Name = "Mover"
            vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
            vectorForce.ApplyAtCenterOfMass = true
            vectorForce.Attachment0 = moveDirAttachment
            vectorForce.Force = Vector3.new()
            vectorForce.Parent = humanoidRootPart

            local alignOrientation = Instance.new("AlignOrientation")
            alignOrientation.Name = "Aligner"
            alignOrientation.Responsiveness = 20
            alignOrientation.Attachment0 = moveDirAttachment
            alignOrientation.Attachment1 = lookDirAttachment
            alignOrientation.Parent = humanoidRootPart

            moveDirAttachment.Parent = humanoidRootPart
            lookDirAttachment.Parent = game.Workspace:FindFirstChildWhichIsA("Terrain")

            local animationController = Instance.new("AnimationController")
            animationController.Parent = self.Character

            local animator = Instance.new("Animator")
            animator.Parent = animationController

            local accessoriesFolder = Instance.new("Folder")
            accessoriesFolder.Name = "Accessories"
            accessoriesFolder.Parent = self.Character

            self.Character.PrimaryPart = humanoidRootPart

            self._mover = vectorForce
            self._aligner = alignOrientation
            self.Animator = animator
            self.RootPart = humanoidRootPart
        end

        self._preSimConnection = nil
        self.Floor = nil
        self._jumpInput = false
        self._walkToTarget = nil
        self._walkToTimeout = 0
        self._walkToTickStart = 0
        self.RigParts = {}
        self.MoveDirection = Vector3.new()
        self.LookDirection = Vector3.new()
        self.LastState = CharacterState.Idling
        self.State = CharacterState.Idling
        self.AnimationTracks = {}

        self.WalkToFinished = Event()
        self.StateChanged = Event()
        self.AccessoryEquipped = Event()
        self.AccessoryUnequipping = Event()

        if type(luanoidParams) == "table" then
            self.Health = luanoidParams.Health or 100
            self.MaxHealth = luanoidParams.MaxHealth or 100
            self.WalkSpeed = luanoidParams.WalkSpeed or 16
            self.JumpPower = luanoidParams.JumpPower or 50
            self.HipHeight = luanoidParams.HipHeight or 2
            self.StateController = (luanoidParams.StateController or StateController)(self)

            if luanoidParams.AutoRotate == nil then
                self.AutoRotate = true
            else
                self.AutoRotate = luanoidParams.AutoRotate
            end
            if luanoidParams.CanJump == nil then
                self.CanJump = true
            else
                self.CanJump = luanoidParams.CanJump
            end
            if luanoidParams.CanClimb == nil then
                self.CanClimb = true
            else
                self.CanClimb = luanoidParams.CanClimb
            end
        else
            self.Health = 100
            self.MaxHealth = 100
            self.WalkSpeed = 16
            self.JumpPower = 50
            self.HipHeight = 2
            self.StateController = StateController(self)
        end

        local localNetworkOwner
        if RunService:IsClient() then
            localNetworkOwner = Players.LocalPlayer
        end
        --[[
            If we are on a Client the localNetworkOwner is the player while on
            the server the localNetworkOwner is nil which reprents server.
        ]]
        self:SetNetworkOwner(localNetworkOwner)

        self.Character.AncestryChanged:Connect(function()
            if self.Character:IsDescendantOf(game.Workspace) then
                if RunService:IsServer() and not self.RootPart:IsGrounded() then
                    --[[
                        Not sure why waiting fixes automatic NetworkOwnership
                        not properly being disabled but it just works.
                    ]]
                    RunService.Heartbeat:Wait()
                    self.RootPart:SetNetworkOwner(nil)
                end

                if self:GetNetworkOwner() == localNetworkOwner then
                    self:ResumeSimulation()
                end
            else
                self:PauseSimulation()
            end
        end)

        self.Character:GetAttributeChangedSignal("NetworkOwner"):Connect(function()
            if self:GetNetworkOwner() == localNetworkOwner then
                self:ResumeSimulation()
            else
                self:PauseSimulation()
            end
        end)

        if self:GetNetworkOwner() == localNetworkOwner and self.Character:IsDescendantOf(game.Workspace) then
            self:ResumeSimulation()
        end
    end

    function Luanoid:Destroy()
        self._aligner.Attachment1:Destroy()
        self.Character:Destroy()
        self.StateController:Destroy()
        self:PauseSimulation()
    end

    function Luanoid:SetRig()
        
    end

    function Luanoid:BuildRigFromAttachments(rig)
        assert(typeof(rig) == "Instance" and rig:IsA("Model"), "Expected Model as Argument #1")
        assert(rig:FindFirstChild("HumanoidRootPart"), "Expected rig to have a HumanoidRootPart")

        self:RemoveRig()

        local character = self.Character
        local humanoidRootPart = self.RootPart
        local rigParts = self.RigParts

        --[[
        for _,v in pairs(rig:GetDescendants()) do
            if v:IsA("Motor6D") then
                if v.Part0.Name == "HumanoidRootPart" then
                    v.Part0 = humanoidRootPart
                end
                if v.Part1.Name == "HumanoidRootPart" then
                    v.Part1 = humanoidRootPart
                end
            elseif v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                table.insert(rigParts, v)
                v.Anchored = false
                v.Massless = true
                v.Parent = character
            end
        end

        humanoidRootPart.Size = rig.HumanoidRootPart.Size

        rig:Destroy()
        ]]

        return self
    end

    function Luanoid:RemoveRig()
        for _,limb in pairs(self.RigParts) do
            limb:Destroy()
        end
        return self
    end

    function Luanoid:LoadAnimation(animation, name)
        assert(typeof(animation) == "Instance" and animation:IsA("Animation"), "Expected Animation as Argument #1")

        name = name or animation.Name
        local animationTrack = self.Animator:LoadAnimation(animation)
        self.AnimationTracks[name] = animationTrack
        return animationTrack
    end

    function Luanoid:PlayAnimation(name, ...)
        local animationTrack = self.AnimationTracks[name]
        if animationTrack then
            animationTrack:Play(...)
        end
        return self
    end

    function Luanoid:StopAnimation(name, ...)
        local animationTrack = self.AnimationTracks[name]
        if animationTrack then
            animationTrack:Stop(...)
        end
        return self
    end

    function Luanoid:StopAnimations(...)
        for _,animationTrack in pairs(self.Animator:GetPlayingAnimationTracks()) do
            animationTrack:Stop(...)
        end
        return self
    end

    function Luanoid:UnloadAnimation(name)
        local animationTrack = self.AnimationTracks[name]
        if animationTrack then
            animationTrack:Destroy()
        end
        return self
    end

    function Luanoid:UnloadAnimations()
        for _,animation in pairs(self.AnimationTracks) do
            animation:Destroy()
        end
        return self
    end

    function Luanoid:Jump()
        if self.CanJump then
            self._jumpInput = true
        end
        return self
    end

    function Luanoid:WalkTo(target, timeout)
        self._walkToTarget = target
        self._walkToTimeout = timeout or 8
        self._walkToTickStart = tick()
        return self
    end

    function Luanoid:CancelWalkTo()
        self._walkToTarget = nil
        self._walkToTimeout = 8
        self._walkToTickStart = 0
        return self
    end

    function Luanoid:AddAccessory(accessory, base, pivot)
        local character = self.Character

        assert(
            typeof(accessory) == "Instance"
            and accessory:IsA("Instance"),
            "Expected Instance as Argument #1"
        )

        local primaryPart = accessory
        if accessory:IsA("Accessory") then
            -- Accessory is a Roblox accessory
            primaryPart = accessory.Handle
            local attachment0 = primaryPart:FindFirstChildWhichIsA("Attachment")
            local attachment1 = self.Character:FindFirstChild(attachment0.Name, true)
            base = attachment1.Parent

            primaryPart.CFrame = attachment1.WorldCFrame * attachment0.CFrame:Inverse()
        else
            -- Accessory is a BasePart or Model
            assert(
                typeof(base) == "Instance",
                "Expected Instance as Argument #2"
            )
            assert(
                base:IsDescendantOf(character),
                "Expected Argument #2 to be descendant of Luanoid"
            )

            if accessory:IsA("Model") then
                primaryPart = accessory.PrimaryPart
            end
            if not pivot then
                if base:IsA("BasePart") then
                    pivot = base.CFrame
                elseif base:IsA("Attachment") then
                    pivot = base.WorldCFrame
                    base = base.Parent
                end
            end

            accessory:PivotTo(pivot)
        end
        local weldConstraint = Instance.new("WeldConstraint")
        weldConstraint.Part0 = primaryPart
        weldConstraint.Part1 = base
        weldConstraint.Parent = primaryPart
        accessory.Parent = character.Accessories

        self.AccessoryEquipped:Fire(accessory)

        return self
    end

    function Luanoid:RemoveAccessory(accessory)
        assert(
            typeof(accessory) == "Instance",
            "Expected Instance as Argument #1"
        )
        assert(
            accessory:IsDescendantOf(self.Character.Accessories),
            "Expected accessory to be descendant of Luanoid.Accessories"
        )

        self.AccessoryUnequipping:Fire(accessory)
        accessory:Destroy()

        return self
    end

    function Luanoid:RemoveAccessories()
        for _,accessory in pairs(self:GetAccessories()) do
            self:RemoveAccessory(accessory)
        end
    end

    function Luanoid:GetAccessories()
        return self.Character.Accessories:GetChildren()
    end

    function Luanoid:GetNetworkOwner()
        local networkOwner = self.RootPart:GetAttribute("NetworkOwner")
        if networkOwner then
            networkOwner = Players[networkOwner]
        end
        return networkOwner
    end

    function Luanoid:SetNetworkOwner(networkOwner)
        assert(
            networkOwner == nil
            or (typeof(networkOwner) == "Instance" and networkOwner:IsA("Player")),
            "Expected nil or Player as Argument #1"
        )

        local character = self.Character
        if networkOwner then
            character:SetAttribute("NetworkOwner", networkOwner.Name)
        else
            character:SetAttribute("NetworkOwner", nil)
        end
        if character:IsDescendantOf(workspace) and RunService:IsServer() then
            character.HumanoidRootPart:SetNetworkOwner(networkOwner)
        end
        return self
    end

    function Luanoid:ChangeState(newState)
        local curState = self.State
        if newState ~= curState then
            self.LastState = curState
            self.State = newState
            self.StateChanged:Fire(self.State, self.LastState)
        end
    end

    function Luanoid:PauseSimulation()
        local connection = self._preSimConnection
        if connection then
            connection:Disconnect()
        end
    end

    function Luanoid:ResumeSimulation()
        local connection = self._preSimConnection
        if not connection or (connection and not connection.Connected) then
            -- TODO: Switch this to PreSimulation once enabled
            self._preSimConnection = RunService.Heartbeat:Connect(function(dt)
                if not self.Character.HumanoidRootPart:IsGrounded() then
                    self.StateController:step(dt)
                end
            end)
        end
    end
end

return Luanoid
