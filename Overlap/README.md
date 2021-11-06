# Vunerable Boxes and Damage boxes

These scenes can in instanced within another scene to apply hurt boxes and hit boxes.
The names are slightly ambigious, so to differentiate:

- The collision in a Damage box is used to denote the area which will apply a damaging hit.
- The collision in a Vunerable box is used to mark out the shape that will take damage when hit by a Damage box.

### To apply a Vunerable box or a Damage box:

1. Select the relevant Node (probably the scene parent).
1. Right click the node and select "Instance Child Scene" (Or Ctrl-Shift-A).
1. Select the relevant scene to add as a child hit to create damage, hurt to accept damage.
1. Right click on the `res://Overlap/Vunerable` or `res://Overlap/Damage` and toggle on the "Editable Children" check box.
1. The collision shape can then be set on the `CollisionShape` under the `Vunerable` or `Damage`.
1. The `area_entered` signal on the Hurt/Hitbox can then be attached to a script within the scene (likely the scene root)

### To apply world collisions:

1. Create a CollisionShape (or Polygon) on the node that should be colliding with walls.
1. Set up the shade or polygon.
1. On the parent to the CollisionShape (or Polygon) set the collision Mask to enable World (1).
1. Colliders that shouldn't act as solid objects don't need to set on the World layer (just the mask).

### To enable player detection on an entity:

1. Select the relevant Node (probably the scene parent).
1. Right click the node and select "Instance Child Scene" (Or Ctrl-Shift-A).
1. Select `res://Overlap/PlayerDetectionZone.tscn`.
1. Right click on the `PlayerDetectionZone` and toggle on the "Editable Children" check box.
1. The collision shape can then be set on the `CollisionShape` under the `PlayerDetectionZone`.
   This can be as large as needed to detect the player entering any area.
1. The PlayerDetectionZone can then be used to detect if the player body has entered use `can_see_player()`.
1. The `player` attribute can be used to get the player body when seen.


# Collision Layers

The collision layers are named:

| Layer | Name            | Purpose                                                                           |
|-------|-----------------|-----------------------------------------------------------------------------------|
| 1     | World           | Collisions with the world, generally containing rather than damaging              |
| 2     | Player          | Used to detect the player entering an area to trigger events, etc                 |
| 3     | PlayerVunerable | Used to detect an player being hit by the appropriate hit box                     |
| 4     | Enemy           | Used to detect an enemy entering an area to trigger events, etc                   |
| 5     | EnemyVunerable  | Used to detect an enemy being hit by the appropriate hit box                      |
| 6     | SoftColliders   | Used repel enemies from each other and stop enemys from entering the player model |

### World Layer
- Tile maps with collisions should be on the layer.
- World furnature with collisions should be on this layer.

- The player movement and enemy movement bodies should be masked to this layer.

### Player Layer
- The player movement body (KinematicBody, etc) should be on this player.

- Nodes waiting for the player to enter should be masked to this layer.

### PlayerVunerable Layer
- The player damage area (traditionally referred to as the hit box ¯\\\_(ツ)_/¯ ) should be on this layer.

- The enemy where it gives damage and enemy projectiles that give the player damage should be masked to this layer.

### Enemy Layer
- Enemies should be on thie layer.

- Nodes waiting on an enemy to enter an area should be masked on this layer.

### EnemyVunerable Layer
- Enemies or items that can be damaged by the player should be on this layer.

- Items that can hurt an enemy should be masked to this layer.

### SoftColliders
- Enemies should have a collision shape on this layer *and act on collisions to move away*.

- Players, NPCs or other obstacles should have a collision shape on this layer, but may not act on collision.