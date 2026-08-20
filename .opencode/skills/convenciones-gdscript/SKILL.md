---
name: convenciones-gdscript
description: Convenciones y estilo de GDScript del proyecto (Godot 4.7 tower defense). Usar al escribir o editar cualquier script .gd, o cuando el usuario pida seguir el estilo del proyecto. Cubre naming, extends/class_name, typing, señales, @export/@onready, autoloads, grupos y formato.
---

# Convenciones GDScript del proyecto

## Estructura de archivos

- `extends X` en la primera línea, `class_name X` en la segunda.
- Los nodos raíz de las trampas usan `extends Trap`; los niveles `extends BaseLevel`; los enemigos
  `extends CharacterBody3D` (clase `Enemy`).
- Archivos y carpetas en `snake_case`; `class_name` en `PascalCase`.

## Naming y formato

- Variables y métodos en `snake_case`. Métodos privados con `_` al inicio (ej. `_apply_stats`).
- Constantes en `SCREAMING_SNAKE` (ej. `TRAPS`, `SLOT_KEYS`, `INITIAL_MONEY`).
- Tipado estático: usa `:=` para inferencia y tipos explícitos en parámetros y retornos
  (`func add_money(amount: int) -> void`).
- Enums para estados (`enum EnemyState`, `enum GameState`, `enum SurfaceOrientation`).
- Señales declaradas al principio del script: `signal wave_started(wave_number: int)`.
- `@export` para lo configurable, `@export_category("...")` para agrupar (ver `TrapData.gd`).
- `@onready var x := $NodoHijo` para referencias a hijos.
- Dos líneas en blanco entre funciones y bloques `const` (estilo del repo).
- Código sin comentarios innecesarios; solo comentar lógica no obvia si hace falta.

## Autoloads (accesibles globalmente)

Declarados en `project.godot` → `[autoload]`:
- `Debug` → `res://src/core/debug/debug.gd` (`Debug.debug_enabled`, `Debug.toggle_debug()`).
- `Economy` → `res://src/core/economy/economy.gd` (`Economy.add_money`, `spend_money`, `can_afford`, `reset`).
- `Settings` → `res://src/core/settings/settings.gd` (volúmenes, video, remapeo de teclas; se guarda en `user://settings.cfg`).
- `Music` → `res://src/core/music/music.gd` (música procedural, bus `Music`, escucha `Settings.audio_changed`).

## Grupos (get_tree().get_nodes_in_group / is_in_group)

`"player"`, `"base"`, `"enemies"`, `"spawner"`, `"traps"`, `"colocable"`,
`"enemy_routes"`, `"navigation"`, `"wave_manager"`, `"current_level"`.

## Capas de física (project.godot → [layer_names])

- 3d_physics layer 1 = World, 2 = Player, 3 = Enemy, 4 = Interactable.
- Los `DamageAreaComponent` de trampas usan `collision_mask = 4` (Enemy).
- El `GridMap` colocar usa `collision_mask = 7` (World|Player|Enemy).
- El enemigo base usa `collision_layer = 4`, `collision_mask = 11`.

## Patrones de daño y señales

- Los enemigos exponen `take_damage(amount)` y `take_trap_damage(amount)`.
- El daño en área usa `DamageAreaComponent`; el daño por hit usa `HitboxComponent`.
- Conectar señales en `_ready()` con `_on_<nodo>_<señal>` como nombre de handler.
- `class_name` registrado para tipar (`as Trap`, `as Enemy`, `as WaveManager`).
