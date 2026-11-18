class_name PhysicsLayers
## Bit values for the named 3D physics layers in project.godot. Use these
## instead of raw numbers, e.g. collision_mask = PhysicsLayers.WORLD | PhysicsLayers.ENEMY.

## Layer 1 "wereld": terrain, buildings and props.
const WORLD: int = 1 << 0
## Layer 2 "speler": the player's body.
const PLAYER: int = 1 << 1
## Layer 3 "vijand": enemy and boss bodies.
const ENEMY: int = 1 << 2
## Layer 4 "speler_hitbox": the player's weapon and arrow hitboxes.
const PLAYER_HITBOX: int = 1 << 3
## Layer 5 "vijand_hitbox": enemy and boss attack hitboxes.
const ENEMY_HITBOX: int = 1 << 4
## Layer 6 "interactie": things you can use with E (Klaas, doors, chests).
const INTERACTION: int = 1 << 5
## Layer 7 "tornado_grens": the tornado wall around Elst.
const TORNADO_BORDER: int = 1 << 6
