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
  - _mover `VectorForce`
  - _aligner `AlignOrientation`
  - _preSimConnection `RBXScriptConnection`
  - _walkToTickStart `number`
  - _walkToTarget `Vector3`|`BasePart`
  - _walkToTimeout `number`
  - _jumpInput `boolean`
  - Character `Model`
  - Animator `Animator`
  - RootPart `Part`
  - Floor `Part`
  - RigParts `list`
  - MoveDirection `Vector3`
  - LookDirection `Vector3`
  - LastState `Enum`
  - State `Enum`
  - AnimationTracks `list`
  - Health `number`
  - MaxHealth `number`
  - WalkSpeed `number`
  - JumpPower `number`
  - HipHeight `number`
  - StateController `StateController`
  - AutoRotate `boolean`
  - CanJump `boolean`
  - CanClimb `boolean`
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
