# API

## Properties

### _preSimConnection

{internal} {read-only} {not-replicated} `RBXScriptConnection`

Connection created from `ResumeSimulation()`.

### _moveToTarget

{internal} {read-only} {not-replicated} `Vector3|BasePart`

Target defined by `MoveTo()`.

### _moveToTimeout

{internal} {read-only} {not-replicated} `number`

Timeout defined by `MoveTo()`.

### _moveToTickStart

{internal} {read-only} {not-replicated} `number`

Tick of when `MoveTo()` was last called.

### _moveToDeadzoneRadius

{internal} {read-only} {not-replicated} `number`

Deadzone radius defined by `MoveTo()`.

### Character

{read-only} {not-replicated} `Model`

Luanoid's character model.

### RootPart

{read-only} {not-replicated} `Part`

Luanoid.Character.HumanoidRootPart

### Animator

{read-only} {not-replicated} `Animator`

Luanoid.Character.AnimationController.Animator

### Floor

{not-replicated} `BasePart`

Instance the Luanoid is currently standing on. This property should be set by
the StateController on each update.

### RigParts

{read-only} {not-replicated} `{BasePart}`

All the BaseParts found after `SetRig()` is called.

### Motor6Ds

{read-only} {not-replicated} `{Motor6D}`

All the Motor6Ds found after `SetRig()` is called.

### State

{read-only} {not-replicated} `CharacterState`

State defined by `ChangeState()`.

### LastState

{read-only} {not-replicated} `CharacterState`

Previous `CharacterState` overwritten by `ChangeState()`.

### StateController

{not-replicated} `StateController`

Controller to be used during simulations.

### AnimationTracks

{read-only} {not-replicated} `{AnimationTrack}`

Dictionary of AnimationTracks created from `LoadAnimation()`

### MoveDirection

`Vector3`

Direction of character movement. In the default StateController the Y-value is
discarded.

### LookDirection

`Vector3`

Direction character will face. In the default StateController the Y-value is
discarded. This value also only gets used if Idling or `AutoRotate` is false.

### Health

`number`

Character's current health. In the default StateController if this value enters
0 or less the character will enter the state `Dead` and pause simulation.

### MaxHealth

`number`

Character's max health.

### WalkSpeed

`number`

Character's speed of movement.

### JumpPower

`number`

In the default StateController this is the force multiplied by character
`AssemblyMass` applied when jumping.

### HipHeight

`number`

In the default StateController this is the distance from the bottom of the
HumanoidRootPart to the surface the Luanoid is on to define levitation height.

### MaxSlopeAngle

`number`

In the default StateController this is the maximum slope angle that the Luanoid
can climb. If the angle of a slope is greater they will slide down the slope.

### AutoRotate

`boolean`

In the default StateController this defines if during the `Walking` state the
character should automatically face the direction of travel.

### Jump

`boolean`

In the default StateController this queues the StateController to jump the next
time it is run.

## Methods

### step

{internal}

```lua
luanoid:step(dt: number)
```

Checks if the current machine has network ownership of the Luanoid before
calling `StateController:step()`

### Destroy

```lua
luanoid:Destroy()
```

Destroys the Luanoid's character and stops simulation.

### SetRig

```lua
luanoid:SetRig(rig: Model)
```

Sets the Luanoid's character rig. This model should only contain Attachments,
BaseParts, and Motor6Ds. Everything else should be added after calling this
method to avoid errors.

### RemoveRig

```lua
luanoid:RemoveRig()
```

Destroys all BaseParts in `RigParts`.

### ToggleRigCollision

```lua
luanoid:ToggleRigCollision(collisionEnabled: boolean)
```

Sets all RigParts in `RigParts` to have `CanCollide` as true or false.

### LoadAnimation

```lua
luanoid:LoadAnimation(animation: Animation, name: string?) --> AnimationTrack
```

Loads an animation onto the Luanoid which can be played later by name.

### PlayAnimation

```lua
luanoid:PlayAnimation(name)
```

Plays an AnimationTrack previously created with `LoadAnimation()`.

### StopAnimation

```lua
luanoid:StopAnimation(name)
```

Stops an AnimationTrack previously started with `PlayAnimation()`

### StopAnimations

```lua
luanoid:StopAnimations()
```

Stops all currently playing AnimationTracks.

### UnloadAnimation

```lua
luanoid:UnloadAnimation(name)
```

Destroys an AnimationTrack previously created with `LoadAnimation()` from
`AnimationTracks`.

### UnloadAnimations

```lua
luanoid:UnloadAnimations()
```

Destroys all AnimationTracks in `AnimationTracks`.

### MoveTo

```lua
luanoid:MoveTo(target: Vector3|BasePart, timeout: number?, deadzoneRadius: number?)
```

Sets a target for the Luanoid to travel towards. In the default StateController
the Luanoid will take a direct path and not pathfind, this method will also
overwrite `MoveDirection`. If `timeout` is not defined it will default to 8
seconds. If `deadzoneRadius` is not defined it will default to a distance of
6 studs from the target's position to the HumanoidRootPart's position.

### CancelMoveTo

```lua
luanoid:CancelMoveTo()
```

Stops the Luanoid from travelling to a target previously defined by `MoveTo()`.

### TakeDamage

```lua
luanoid:TakeDamage(damage: number)
```

Reduces the Luanoid's health. If a negative value is provided the absolute
value will be used.

### AddAccessory

```lua
luanoid:AddAccessory(accessory: Accessory|Model|BasePart, base: Attachment?|BasePart?, pivot: CFrame?)
```

Mounts an accessory to the character model. If the accessory is an `Accessory`
it will use the first `Attachment` it can find as the `base`. If the accessory
is a `Model` or `BasePart` the `base` must be defined as an `Attachment`.
The pivot is always calculated automatically but can be overwritten if
necessary.

### RemoveAccessory

```lua
luanoid:RemoveAccessory(accessory: Accessory|Model|BasePart)
```

Destroys an accessory, must be a descendant of `luanoid.Character.Accessories`.

### GetAccessories

```lua
luanoid:GetAccessories()
```

Returns all children of `luanoid.Character.Accessories`.

### GetNetworkOwner

```lua
luanoid:GetNetworkOwner()
```

Returns the desired NetworkOwner defined by `SetNetworkowner()`. Luanoids use a
custom `GetNetworkOwner()` method due to the native method not allowed on the
client, instead this method will return an attribute set by the server of who
the NetworkOwner should be.

### SetNetworkOwner

```lua
luanoid:SetNetworkOwner(networkOwner: Player?)
```

Sets the Luanoid's desired `NetworkOwner`. Luanoids use a custom
`SetNetworkOwner()` method due to Roblox having no way to disable automatic
network ownership which can be problematic for NPCs that should be simulated
by the server. This method is also needed to set an attribute for
`GetNetworkOwner()` to be used on the client.

### ChangeState

```lua
luanoid:ChangeState(characterState: CharacterState)
```

Sets the Luanoid's new CharacterState.

### PauseSimulation

```lua
luanoid:PauseSimulation()
```

Ends simulation of the Luanoid.

### ResumeSimulation

```lua
luanoid:ResumeSimulation()
```

Starts or resumes simulation of the Luanoid. This entails binding to RunService
and calling `step()` on every frame.

## Events

### StateChanged

```lua
luanoid.StateChanged:Connect(function(newState: CharacterState, oldState: CharacterState)

end)
```

### HealthChanged

```lua
luanoid.HealthChanged:Connect(function(health: number)

end)
```

### AccessoryEquipped

```lua
luanoid.AccessoryEquipped:Connect(function(accessory: Accessory|Model|BasePart)

end)
```

### AccessoryUnequipping

```lua
luanoid.AccessoryUnequipping:Connect(function(accessory: Accessory|Model|BasePart)

end)
```

### MoveToFinished

```lua
luanoid.MoveToFinished:Connect(function(success: boolean)
    if success then
        print("Luanoid reached its target")
    else
        print("Luanoid hit an obstacle or timed out")
    end
end)
```

### Died

```lua
luanoid.Died:Connect(function(isDead: boolean)
    if isDead then
        print("Luanoid died")
    else
        print("Luanoid was revived")
    end
end)
```

### FreeFalling

```lua
luanoid.FreeFalling:Connect(function(isFalling: boolean)
    if isFalling then
        print("Luanoid is now falling")
    else
        print("Luanoid is no longer falling")
    end
end)
```

### Jumping

```lua
luanoid.Jumping:Connect(function(isJumping: boolean)
    if isJumping then
        print("Luanoid is jumping")
    else
        print("Luanoid is no longer jumping")
    end
end)
```
