--// File Name: Luanoid (Based on Cardinoid, separated from Cardinal Engine and built in a proper class structure.)
--// Creator: Rythian Smythe / Rythian2277
--// Date: April 18, 2021

local Class = require(3696101309)
local Event = require(3908178708)
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

            self.Character.PrimaryPart = humanoidRootPart

            self._mover = vectorForce
            self._aligner = alignOrientation
            self.Animator = animator
            self.RootPart = humanoidRootPart
        end

        self._preSimConnection = nil
        self.JumpInput = false
        self.MoveToTarget = nil
        self.MoveToTimeout = 0
        self._moveToTickStart = 0
        self.RigParts = {}
        self.MoveDir = Vector3.new()
        self.LookDir = Vector3.new()
        self.LastState = CharacterState.Idling
        self.State = CharacterState.Idling
        self.AnimationTracks = {}
        self.PlayingAnimations = {}
        self.MoveToFinished = Event()
        self.StateChanged = Event()

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
            if self.Character:IsDescendantOf(game.Workspace) and self:GetNetworkOwner() == localNetworkOwner then
                self:ResumeSimulation()
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

    function Luanoid:MountRig(rig)
        assert(typeof(rig) == "Instance", "Expected Instance as Argument #1, instead got ".. typeof(rig))
        assert(rig:FindFirstChild("HumanoidRootPart"), "Expected rig to have a HumanoidRootPart")

        self:UnmountRig()

        local character = self.Character
        local humanoidRootPart = character.HumanoidRootPart
        local rigParts = self.RigParts

        rig = rig:Clone()
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
    end

    function Luanoid:UnmountRig()
        for _,limb in pairs(self.RigParts) do
            limb:Destroy()
        end
        return self
    end

    function Luanoid:LoadAnimation(animation, name)
        assert(typeof(animation) == "Instance" and animation:IsA("Animation"), "Expected Animation as Argument #1")
        name = name or animation.Name
        local animationTrack = self.Animator:LoadAnimation(animation)
        self.AnimationTracks[name] = self.AnimationTracks[name] or {}
        table.insert(self.AnimationTracks[name], animationTrack)
        return animationTrack
    end

    function Luanoid:PlayAnimation(name, ...)
        local animationTracks = self.AnimationTracks[name]
        if animationTracks then
            local numAnimationTracks = #animationTracks
            local animationTrack = animationTracks[math.random(1, numAnimationTracks)]
            animationTrack:Play(...)
            self.PlayingAnimations[name] = animationTrack
        end
        return self
    end

    function Luanoid:StopAnimation(name, ...)
        local animationTrack = self.PlayingAnimations[name]
        if animationTrack then
            animationTrack:Stop(...)
            self.PlayingAnimations[name] = nil
        end
        return self
    end

    function Luanoid:StopAllAnimations(...)
        for _,animationTrack in pairs(self.Animator:GetPlayingAnimationTracks()) do
            animationTrack:Stop(...)
        end
        return self
    end

    function Luanoid:Jump()
        if self.CanJump then
            self.JumpInput = true
        end
        return self
    end

    function Luanoid:MoveTo(target, timeout)
        self.MoveToTarget = target
        self.MoveToTimeout = timeout or 8
        self._moveToTickStart = tick()
    end

    function Luanoid:CancelMoveTo()
        self.MoveToTarget = nil
        self.MoveToTimeout = 8
        self._moveToTickStart = 0
    end

    function Luanoid:GetNetworkOwner()
        local networkOwner = self.RootPart:GetAttribute("NetworkOwner")
        if networkOwner then
            networkOwner = Players[networkOwner]
        end
        return networkOwner
    end

    function Luanoid:SetNetworkOwner(networkOwner)
        assert(networkOwner == nil or (typeof(networkOwner) == "Instance" and networkOwner:IsA("Player")), "Expected nil or Player as Argument #1, instead got ".. typeof(networkOwner))
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
                    local newState = self.StateController:step(dt)
                    local curState = self.State
                    if newState ~= curState then
                        self.LastState = curState
                        self.State = newState
                        self.StateChanged:Fire(self.State, self.LastState)
                        self:StopAnimation(curState.Name)
                        self:PlayAnimation(newState.Name)
                    end
                end
            end)
        end
    end
end

return Luanoid
