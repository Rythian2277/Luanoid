# Luanoid

A rewrite of the `Humanoid` class entirely in Luau!

For developers who want more precise control over how their avatars behave in their games.

Features:

- Entirely in Luau, making it easy to add/remove features as you wish!
- Supports Animations!
- Supports Pathfinding!
- Supports Custom Character Rigs!
- Supports Custom State Controllers

Coming Soon:

- Tool Compatibility

## API

Proper documentation page will be setup later.

### Luanoid

- Properties
  - `VectorForce`_mover: Levitates the Luanoid
  - `AlignOrientation`_aligner: Keeps the Luanoid upright
  - `RBXScriptConnection`_preSimConnection
  - `number`_walkToTickStart: Time `WalkTo()` was called
  - `Vector3`|`BasePart`_walkToTarget: WalkTo goal
  - `number`_walkToTimeout: Max time spent walking to target
  - `boolean`_jumpInput
  - `Model`Character
  - `Animator`Animator
  - `Part`RootPart: HumanoidRootPart
  - `BasePart`Floor: Instance the Luanoid is standing on
  - `List`RigParts
  - `Vector3`MoveDirection: Direction to walk towards
  - `Vector3`LookDirection: Direction to look towards
  - `Enum`LastState: Previous `CharacterState`
  - `Enum`State: Current `CharacterState`
  - `Dictionary`AnimationTracks
  - `number`Health
  - `number`MaxHealth
  - `number`WalkSpeed
  - `number`JumpPower
  - `number`HipHeight
  - `StateController`StateController
  - `boolean`AutoRotate: Look in the direction walking
  - `boolean`CanJump
  - `boolean`CanClimb
- Methods
  - Destroy()
  - SetRig(`Rig`rig)
  - RemoveRig()
  - LoadAnimation(`Animation`animation, `string?`animationName)
  - PlayAnimation(`string`animationName)
  - StopAnimation(`string`animationName)
  - StopAnimations()
  - UnloadAnimation(`string`animationName)
  - UnloadAnimations()
  - Jump()
  - WalkTo(`Vector3`|`BasePart`, `number?`)
  - CancelWalkTo()
  - AddAccessory(`BasePart`|`Model`|`Accessory`)
  - RemoveAccessory(`BasePart`|`Model`|`Accessory`)
  - RemoveAccessories()
  - GetAccessories()
  - GetNetworkOwner()
  - SetNetworkOwner(`Player?`player)
  - ChangeState(`Enum`state)
  - PauseSimulation()
  - ResumeSimulation()
- Events
  - WalkToFinished: `boolean`success
  - StateChanged: `Enum`newState, `Enum`previousState
  - AccessoryEquipped: `Instance`accessory
  - AccessoryUnequipping: `Instance`accessory

### StateController

All StateControllers require a `step()` method to be defined.

- Methods
  - step(`number`dt)

### Rig

- Properties
  - Parts `Model`
- Methods
  - BuildRigFromAttachments(`Model`rig)

### CharacterState

- Unsimulated
- Idling
- Walking
- Jumping
- Falling
