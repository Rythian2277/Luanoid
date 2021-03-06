--// File Name: Luanoid (Based on Cardinoid, separated from Cardinal Engine and built in a proper class structure.)
--// Creator: Rythian Smythe / Rythian2277
--// Date: April 18, 2021

type Target = BasePart | Vector3
type CustomAccessory = Accessory | Model | BasePart

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Class = require(script.Class)
local Event = require(script.Event)
local StateController = require(script.StateController)
local CharacterState = require(script.CharacterState)

local IS_CLIENT = RunService:IsClient()
local IS_SERVER = RunService:IsServer()

local Luanoid = Class() do
    function Luanoid:init(luanoidParams, character: Model?): nil
        luanoidParams = luanoidParams or {}

        if character then --// Luanoid model exists, just mounting onto the model.
            local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
            self.Character = character
			self._mover = humanoidRootPart.Mover
			self._aligner = humanoidRootPart.Aligner
            self.Animator = character.AnimationController.Animator
			self.RootPart = humanoidRootPart

            self:wrapinstance(
                character,
                {
                    "MoveDirection",
                    "LookDirection",
                    "Health",
                    "MaxHealth",
                    "WalkSpeed",
                    "JumpPower",
                    "HipHeight",
                    "MaxSlopeAngle",
                    "AutoRotate",
                    "Jump",
                }
            )
        else --// Needs to be created
            character = Instance.new("Model")
            character.Name = luanoidParams and luanoidParams.Name or "NPC"
            self.Character = character

            local moveDirAttachment = Instance.new("Attachment")
            moveDirAttachment.Name = "MoveDirection"

            local lookDirAttachment = Instance.new("Attachment")
            lookDirAttachment.Name = "LookDirection"

            local humanoidRootPart = Instance.new("Part")
            humanoidRootPart.Name = "HumanoidRootPart"
            humanoidRootPart.Transparency = 1
            humanoidRootPart.Size = Vector3.new(1, 1, 1)
            humanoidRootPart.RootPriority = 127
            humanoidRootPart.Parent = character

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
            animationController.Parent = character

            local animator = Instance.new("Animator")
            animator.Parent = animationController

            local accessoriesFolder = Instance.new("Folder")
            accessoriesFolder.Name = "Accessories"
            accessoriesFolder.Parent = character

            character.PrimaryPart = humanoidRootPart

            self._mover = vectorForce
            self._aligner = alignOrientation
            self.Animator = animator
            self.RootPart = humanoidRootPart

            if luanoidParams.AutoRotate == nil then
                luanoidParams.AutoRotate = true
            end

            self:wrapinstance(
                character,
                {
                    MoveDirection = Vector3.new(),
                    LookDirection = Vector3.new(),

                    Health = luanoidParams.Health or 100,
                    MaxHealth = luanoidParams.MaxHealth or 100,
                    WalkSpeed = luanoidParams.WalkSpeed or 16,
                    JumpPower = luanoidParams.JumpPower or 50,
                    HipHeight = luanoidParams.HipHeight or 2,
                    MaxSlopeAngle = luanoidParams.MaxSlopeAngle or 89,

                    AutoRotate = luanoidParams.AutoRotate,
                    Jump = false,
                }
            )
        end

        self._preSimConnection = nil
        self._moveToTarget = nil
        self._moveToTimeout = 8
        self._moveToTickStart = 0
        self._moveToDeadzoneRadius = 6
        self._stateEnterTime = 0
        self._stateEnterPosition = Vector3.new()

        self.Floor = nil
        self.RigParts = {}
        self.Motor6Ds = {}
        self.LastState = CharacterState.Idling
        self.State = CharacterState.Idling
        self.AnimationTracks = {}

        self.RigChanged = Event()

        self.MoveToFinished = Event()
        self.AccessoryEquipped = Event()
        self.AccessoryUnequipping = Event()

        self.StateChanged = Event()
        self.HealthChanged = Event()

        self.Died = Event()
        self.FreeFalling = Event()
        self.Jumping = Event()

        if luanoidParams then
            self.StateController = (luanoidParams.StateController or StateController)(self)
        else
            self.StateController = StateController(self)
        end

        local localNetworkOwner
        if IS_CLIENT then
            localNetworkOwner = Players.LocalPlayer
        end

        if not self:GetNetworkOwner() and not self:IsNetworkOwnerServer() then
            --[[
                If we are on a Client the localNetworkOwner is the player while on
                the server the localNetworkOwner is nil which represents the
                server.
            ]]
            self:SetNetworkOwner(localNetworkOwner)
        end

        character.AncestryChanged:Connect(function()
            if character:IsDescendantOf(game.Workspace) then
                if self:GetNetworkOwner() == localNetworkOwner then
                    self:ResumeSimulation()
                end
            else
                if self.RootPart.Parent == character then
                    self:PauseSimulation()
                else
                    --[[
                        We don't pause the simulation to allow the Dead
                        CharacterState handler to run.
                    ]]
                    self:ChangeState(CharacterState.Dead)
                end
            end
        end)

        character:GetAttributeChangedSignal("NetworkOwner"):Connect(function()
            if self:GetNetworkOwner() == localNetworkOwner then
                self:ResumeSimulation()
            else
                self:PauseSimulation()
            end
        end)
        character:GetAttributeChangedSignal("Health"):Connect(function()
            self.Health = math.clamp(self.Health, 0, self.MaxHealth)
            self.HealthChanged:Fire(self.Health)
        end)
        character:GetAttributeChangedSignal("MaxHealth"):Connect(function()
            self.Health = math.clamp(self.Health, 0, self.MaxHealth)
        end)
        character:GetAttributeChangedSignal("MaxSlopeAngle"):Connect(function()
            self.MaxSlopeAngle = math.clamp(self.MaxSlopeAngle, 0, 89)
        end)
        character:GetAttributeChangedSignal("MoveDirection"):Connect(function()
            local moveDir = self.MoveDirection
            self.MoveDirection = Vector3.new(moveDir.X, 0, moveDir.Z)
        end)
        character:GetAttributeChangedSignal("LookDirection"):Connect(function()
            local lookDir = self.LookDirection
            self.LookDirection = Vector3.new(lookDir.X, 0, lookDir.Z)
        end)

        if self:GetNetworkOwner() == localNetworkOwner and character:IsDescendantOf(game.Workspace) then
            self:ResumeSimulation()
        end
    end

    function Luanoid:Destroy(): nil
        self._aligner.Attachment1:Destroy()
        self.Character:Destroy()
        --self.StateController:Destroy()
        self:PauseSimulation()
    end

    function Luanoid:SetRig(rig: Model): nil
        assert(typeof(rig) == "Instance" and rig:IsA("Model"), "Expected Model as Argument #1")
        assert(rig:FindFirstChild("HumanoidRootPart"), "Expected rig to have a HumanoidRootPart")

        self:RemoveRig()

        local character = self.Character
        local humanoidRootPart = self.RootPart
        local rigParts = self.RigParts

        for _,v in ipairs(rig:GetDescendants()) do
            if v.Parent.Name == "HumanoidRootPart" then
                v.Parent = humanoidRootPart
            end
            if v:IsA("Motor6D") then
                table.insert(self.Motor6Ds, v)

                if v.Part0.Name == "HumanoidRootPart" then
                    v.Part0 = humanoidRootPart
                end
                if v.Part1.Name == "HumanoidRootPart" then
                    v.Part1 = humanoidRootPart
                end
            elseif v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                table.insert(rigParts, v)
                v.CanCollide = false
                v.Parent = character
            end
        end
        humanoidRootPart.Size = rig.HumanoidRootPart.Size
        rig:Destroy()

        self.RigChanged:Fire(character)

        return self
    end

    function Luanoid:ToggleRigCollision(canCollide: boolean)
        for _,part in ipairs(self.RigParts) do
            if part:IsA("BasePart") then
                part.CanCollide = canCollide
            end
        end
        return self
    end

    function Luanoid:RemoveRig()
        for _,limb in ipairs(self.RigParts) do
            limb:Destroy()
        end
        return self
    end

    function Luanoid:LoadAnimation(animation: Animation, name: string?): AnimationTrack
        assert(typeof(animation) == "Instance" and animation:IsA("Animation"), "Expected Animation as Argument #1")

        name = name or animation.Name
        local animationTrack = self.Animator:LoadAnimation(animation)
        self.AnimationTracks[name] = animationTrack
        return animationTrack
    end

    function Luanoid:PlayAnimation(name: string, ...)
        local animationTrack = self.AnimationTracks[name]
        if animationTrack then
            animationTrack:Play(...)
        end
        return self
    end

    function Luanoid:StopAnimation(name: string, ...)
        local animationTrack = self.AnimationTracks[name]
        if animationTrack then
            animationTrack:Stop(...)
        end
        return self
    end

    function Luanoid:StopAnimations(...)
        for _,animationTrack in ipairs(self.Animator:GetPlayingAnimationTracks()) do
            animationTrack:Stop(...)
        end
        return self
    end

    function Luanoid:UnloadAnimation(name: string)
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

    function Luanoid:TakeDamage(damage)
        self.Health = math.max(self.Health - math.abs(damage), 0)
    end

    function Luanoid:MoveTo(target: Target, timeout: number?, _moveToDeadzoneRadius: number?)
        self._moveToTarget = target
        self._moveToTimeout = timeout or 8
        self._moveToTickStart = tick()
        self._moveToDeadzoneRadius = _moveToDeadzoneRadius or 6
        return self
    end

    function Luanoid:CancelMoveTo()
        if self._moveToTarget then
            self._moveToTarget = nil
            self._moveToTimeout = 8
            self._moveToTickStart = 0
            self._moveToDeadzoneRadius = 6
            self.MoveDirection = Vector3.new()
        end
        return self
    end

    -- Accessories can be BasePart, Model, or Accessory
    function Luanoid:AddAccessory(accessory: CustomAccessory, base: Attachment?|BasePart?, pivot: CFrame?)
        local character = self.Character

        assert(
            typeof(accessory) == "Instance"
            and accessory:IsA("Instance"),
            "Expected Instance as Argument #1"
        )

        local existingWeldConstraint = accessory:FindFirstChild("AccessoryWeldConstraint", true)
        if existingWeldConstraint then
            existingWeldConstraint:Destroy()
        end

        local primaryPart = accessory
        if accessory:IsA("Accessory") then
            -- Accessory is a Roblox accessory
            primaryPart = accessory.Handle
            local attachment0 = primaryPart:FindFirstChildWhichIsA("Attachment")
            local attachment1 = self.Character:FindFirstChild(attachment0.Name, true)
            base = attachment1.Parent

            primaryPart.CanCollide = false
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
        weldConstraint.Name = "AccessoryWeldConstraint"
        weldConstraint.Part0 = primaryPart
        weldConstraint.Part1 = base
        weldConstraint.Parent = primaryPart
        accessory.Parent = character.Accessories

        self.AccessoryEquipped:Fire(accessory)

        return self
    end

    function Luanoid:RemoveAccessory(accessory: CustomAccessory)
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
        for _,accessory in ipairs(self:GetAccessories()) do
            self:RemoveAccessory(accessory)
        end
        return self
    end

    function Luanoid:GetAccessories(attachment: Attachment): {CustomAccessory}
        if attachment then
            local accessories = {}

            for _,accessory in ipairs(self.Character.Accessories:GetChildren()) do
                local weldConstraint = accessory:FindFirstChild("AccessoryWeldConstraint")
                if weldConstraint.Part0 == attachment.Parent or weldConstraint.Part1 == attachment.Parent then
                    table.insert(accessories, accessory)
                end
            end

            return accessories
        else
            return self.Character.Accessories:GetChildren()
        end
    end

    --[[
        This is different from the native GetNetworkOwner() method as it checks
        an attribute of who the NetworkOwner should be not who it currently
        is which also allows the client to call this method as well
    ]]
    function Luanoid:GetNetworkOwner(): Player?
        local networkOwnerString = self.Character:GetAttribute("NetworkOwner")
        if not networkOwnerString or networkOwnerString == "_SERVER_" then
            return nil
        else
            return Players:FindFirstChild(networkOwnerString)
        end
    end

    function Luanoid:SetNetworkOwner(networkOwner: Player?)
        assert(
            networkOwner == nil
            or (typeof(networkOwner) == "Instance" and networkOwner:IsA("Player")),
            "Expected string or Player as Argument #1"
        )

        local character = self.Character
        if networkOwner then
            character:SetAttribute("NetworkOwner", networkOwner.Name)
        else
            character:SetAttribute("NetworkOwner", "_SERVER_")
        end
        if character:IsDescendantOf(workspace) and IS_SERVER then
            self.RootPart:SetNetworkOwner(networkOwner)
        end
        return self
    end

    function Luanoid:IsNetworkOwnerServer(): boolean
        return self.Character:GetAttribute("NetworkOwner") == "_SERVER_"
    end

    function Luanoid:ChangeState(newState)
        local curState = self.State
        if newState ~= curState then
            self.LastState = curState
            self.State = newState
            self._stateEnterTime = os.clock()
            self._stateEnterPosition = self.RootPart.Position
            self.StateChanged:Fire(self.State, self.LastState)
        end
        return self
    end

    function Luanoid:GetStateElapsedTime(): number
        return os.clock() - self._stateEnterTime
    end

    --[[
        Returns a Vector3 of the position the character was at when ChangeState
        was last called.
    ]]
    function Luanoid:GetStateEnteredPosition(): Vector3
        return self._stateEnterPosition
    end

    function Luanoid:PauseSimulation()
        local connection = self._preSimConnection
        if connection then
            connection:Disconnect()
        end
        return self
    end

    function Luanoid:ResumeSimulation()
        local connection = self._preSimConnection
        if not connection or (connection and not connection.Connected) then
            self._preSimConnection = RunService.Heartbeat:Connect(function(dt)
                self:step(dt)
            end)
        end
        return self
    end

    function Luanoid:step(dt)
        if not self.RootPart:IsGrounded() then
            local correctNetworkOwner = self:GetNetworkOwner()
            if IS_SERVER and correctNetworkOwner ~= self.RootPart:GetNetworkOwner() then
                --[[
                    Roblox has automatically assigned a NetworkOwner
                    when it shouldn't have. This can cause Luanoids'
                    physics to become highly unstable.
                ]]
                self.RootPart:SetNetworkOwner(correctNetworkOwner)
            end

            self.StateController:step(dt)
        end
        return self
    end
end

return Luanoid
