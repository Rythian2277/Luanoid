# Home

Luanoids are an alternative to Roblox Humanoids originally written by
[LPGhatguy](https://github.com/LPGhatguy){target=new} as a
[2018 Hack Week project](https://github.com/LPGhatguy/luanoid){target=new}.

Due to the original project being archived this is a revival of it rebuilt
with new APIs that were not available in 2018.

## Limitations

The goal of the original project may have been to fully replace Humanoids while
the goal of this project is only partial replacement. The reason for this is
Roblox's Humanoids provide first-class support for characters such as R15 and
R6 which adds bloat for those who wish to use Humanoids for non-R15/R6 rigs.
As a result methods such as `GetBodyPartR15()` and `GetLimb()` will not be
implemented.

* **Clothing**:
  Support for clothing may be added if a modeler volunteers to UV
  wrap an R6 and R15 rig that will be provided in the main repository.
* **Swimming**:
  Support for swimming is under consideration due to not all character rigs
  needing to be able to swim and custom StateControllers are supported for
  those that need such states.
* **Climbing**:
  Same reason as Swimming
* **Sitting**:
  Same reason as Swimming
* **Tools**:
  Support for the `Tool` class may be added in the
  [demo place](https://www.roblox.com/games/6749296103/-). Reason against this
  would be providing higher support for R15/R6 rigs and majority of scripts in
  Tools would not be compatible due to lack of a Humanoid anyway. Until this
  may or may not be added it is advised to use `AddAccessory()` for custom
  tools.
