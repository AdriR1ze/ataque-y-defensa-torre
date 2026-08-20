---
name: crear-trampa
description: Crea una trampa nueva en el tower defense (Godot 4.7). Usar cuando el usuario pida "crear/agregar/añadir una trampa", "nueva trampa", "trampa de X", o describa un comportamiento de trampa (daño en área, proyectiles, trampa con cooldown). Genera un .gd (extends Trap), un .tscn y un .tres (TrapData), y la registra en TrapManager.
---

# Crear trampa

Cada trampa vive en `res://src/gameplay/traps/<nombre>_trap/` con tres archivos:
`<nombre>_trap.gd`, `<nombre>_trap.tscn` y `<nombre>_trap.tres`.

## Arquitectura

- **Clase base**: `res://src/gameplay/traps/trap.gd` (`class_name Trap`, `extends Node3D`).
  Exports disponibles: `display_name`, `snap_rotation_degrees`, `allow_free_rotation`,
  `min_normal_dot`, `surface_orientation` (enum `ANY/FLOOR/WALL/CEILING`), `footprint_radius`.
  Métodos: `set_active(bool)`, `is_surface_valid(normal)`.
- **Datos**: `res://src/gameplay/traps/TrapData.gd` (Resource). El `.tres` guarda
  `id`, `trap_name`, `description`, `icon`, `cost`, `damage`, `cooldown`, `range`, `scene`.
- **Daño en área**: componente `DamageAreaComponent` (`res://src/core/components/damage_area_component.gd`),
  un `Area3D` con `damage_per_second` y `tick_interval`. Llama a `take_trap_damage()` (o `take_damage()`) en cada body.
- **Colocación/venta** lo maneja `TrapBuildController.gd`. Al colocar, setea `trap.cost` y `trap.trap_id`
  y añade el nodo al grupo `"traps"`. No hace falta tocarlo para añadir trampas.

## Pasos

1. **Crear carpeta** `res://src/gameplay/traps/<nombre>_trap/`.

2. **Crear `<nombre>_trap.gd`** que extienda `Trap`:
   - `extends Trap` / `class_name <Nombre>Trap`.
   - Declarar stats con `@export` (damage, range, cooldown, etc.).
   - Referenciar hijos con `@onready var x := $NombreNodo`.
   - Lógica en `_physics_process(delta)` con guard `if not active: return`.

3. **Crear `<nombre>_trap.tscn`**:
   - Nodo raíz `Node3D` con el script `.gd` y los exports del base (`display_name`, `surface_orientation`, etc.).
   - Meshes hijos (`MeshInstance3D`) con `StandardMaterial3D`.
   - Para daño en área: un `Area3D` hijo con script `DamageAreaComponent`, `collision_layer = 0`,
     `collision_mask = 4` (layer Enemy), y un `CollisionShape3D` con su `shape`.
   - Para trampas con proyectil, ver patrón en `spike_launcher_trap.gd` / `ghost_ball_trower.gd`
     (preload de `res://src/gameplay/traps/bullets/*.tscn` y nodo `Muzzle`).

4. **Crear `<nombre>_trap.tres`** (TrapData). Copiar el formato de `spikes_trap.tres`:
   - `script = ExtResource(...)` apuntando a `TrapData.gd` con uid `uid://6mllp02vdl7t`.
   - `metadata/_custom_type_script = "uid://6mllp02vdl7t"`.
   - Asignar el siguiente `id` libre (hoy el máximo es 13 → usar 14, 15...).
   - `scene` apunta al `.tscn` de la trampa.

5. **Registrar en `res://src/gameplay/traps/trap_manager.gd`**: añadir al dict `TRAPS`
   `id: preload("res://src/gameplay/traps/<nombre>_trap/<nombre>_trap.tres")`.

## Checklist de verificación

- El `.gd` usa `extends Trap` y `class_name`.
- El `DamageAreaComponent` tiene `collision_mask = 4`.
- El `.tres` tiene `id` único no usado y `metadata/_custom_type_script = "uid://6mllp02vdl7t"`.
- La trampa está en el dict `TRAPS` de `trap_manager.gd`.
- Abrir el editor Godot una vez para que genere el `.uid` e importe los recursos.
