# Player Weapons

This is the resources for in game weapons that the player is able to pick-up and weild.

## Creating a weapon

A weapon is just a scene, it requires:
  - Some form of mesh so that it's clear the player is carrying something
    - If intending to create a spawner, then the mesh should be (or be made into) an external `.tres` file so that it can be reused for the spawn icon.
  - A script on the route node that implements the `perform_attack()` function.

A weapon will otherwise be depended on the type; AnimationPlayers are likely required, Damage overlaps will be needed to apply melee damage or for projectile damage, Raycasts are required for hitscan weapons.

## Creating a Weapon Spawner

To create a spawner for a weapon the player can use:

1. Make sure the weapon mesh is available as a `.tres` file - even build-in meshes can be saved to file.
1. From the main menu click `Scene` -> `New Inherited Scene...`.
1. Select the `res://Player/Weapons/WeaponPickup.tscn` file.
1. Rename the root node to `<WeaponType>Pickup` or similar.
1. Select the root node, then drag the actual weapon scene onto the value for the `Weapon` Script Variable on the Inspector frame.
1. Select the MeshInstance node, then drag the mesh `.tres` file onto the value for the `Mesh` in the Inspector frame.
1. Save the scene - it can now be dragged into a world scene to place it.
