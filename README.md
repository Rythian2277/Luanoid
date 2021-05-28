# Luanoid

A rewrite of the `Humanoid` class entirely in Luau!

For developers who want more precise control over how their avatars behave in their games.

Features:

- Entirely in Luau, making it easy to add/remove features as you wish!
- Supports Animations!
- Supports Pathfinding!
- Supports Custom Character Rigs!
- Supports Custom State Controllers!

Coming Soon:

- Tool Compatibility

## Demo

The `Demo` folder contains scripts found in this uncopylocked [demo place](https://www.roblox.com/games/6749296103/Luanoid-Test).

## API

Proper documentation page will be setup later.

### Luanoid

- Properties
  - `VectorForce`_mover: Levitates the Luanoid
  - `AlignOrientation`_aligner: Keeps the Luanoid upright
  - `RBXScriptConnection`_preSimConnection
  - `number`_moveToTickStart: Time `MoveTo()` was called
  - `Vector3`|`BasePart`_moveToTarget: MoveTo goal
  - `number`_moveToTimeout: Max time spent walking to target
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
- Methods
  - Destroy()
  - SetRig(`Model`rig)
  - RemoveRig()
  - LoadAnimation(`Animation`animation, `string?`animationName)
  - PlayAnimation(`string`animationName)
  - StopAnimation(`string`animationName)
  - StopAnimations()
  - UnloadAnimation(`string`animationName)
  - UnloadAnimations()
  - Jump()
  - TakeDamage(`number`)
  - MoveTo(`Vector3`|`BasePart`, `number?`)
  - CancelMoveTo()
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
  - MoveToFinished: `boolean`success
  - StateChanged: `Enum`newState, `Enum`previousState
  - AccessoryEquipped: `Instance`accessory
  - AccessoryUnequipping: `Instance`accessory

### StateController

All StateControllers require a `step()` method to be defined.

- Methods
  - step(`number`dt)

### CharacterState

- Physics
- Idling
- Walking
- Jumping
- Falling
- Dead
