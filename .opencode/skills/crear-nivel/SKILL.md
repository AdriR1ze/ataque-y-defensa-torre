---
name: crear-nivel
description: Crea un nivel nuevo en el tower defense (Godot 4.7). Usar cuando el usuario pida "crear/agregar un nivel", "nuevo nivel", "level N", o "mazmorra/escenario nuevo". Genera un .gd que extiende BaseLevel y un .tscn con WaveManager, GridMap, spawner, rutas de enemigos y NavigationGrid, y lo registra en main_game.
---

# Crear nivel

## Arquitectura

- **Clase base**: `res://src/levels/base_level.gd` (`class_name BaseLevel`, `extends Node3D`).
  Emite `level_completed`, se añade al grupo `"current_level"` y provee `get_default_player_spawn()`.
- El `WaveManager` (`res://src/core/main_game/wave_manager.gd`) es hijo del nivel y espera un nodo
  hermano llamado `Spawner` (`@onready var level_spawner = $"../Spawner"`).
- Las rutas usan `res://src/gameplay/enemies/enemy_route.gd` (grupo `"enemy_routes"`), con hijos `Marker3D` como waypoints.
- La navegación usa `res://src/core/navigation/navigation_grid.gd` (grupo `"navigation"`).
- El tilemap es un `GridMap` con `mesh_library = res://src/resources/dungeon_tiles.tres` y grupo `"colocable"`.

## Pasos

1. **Crear `res://src/levels/level_N.gd`**:

```gdscript
extends BaseLevel

@onready var player_spawn = $PlayerSpawner
@export var nombre_level : String = "null"

func _ready() -> void:
	super._ready()
	player_spawn = player_spawn.global_position

func get_default_player_spawn():
	return player_spawn

func _to_string() -> String:
	return nombre_level
```

2. **Crear `res://src/levels/level_N.tscn`** con esta estructura (copiar `level_1.tscn` como plantilla):
   - Nodo raíz `LevelN` (`Node3D`) con el script y `nombre_level`.
   - Hijo `WaveManager` (`Node`) con script `wave_manager.gd` (configurar `max_waves`, `boss_level`, etc.).
   - `WorldEnvironment` + luces (`DirectionalLight3D`, `OmniLight3D`) para el ambiente.
   - `Base` (instancia de `res://src/gameplay/enemies/base.tscn`), grupo `"base"`.
   - `GridMap` con `mesh_library = res://src/resources/dungeon_tiles.tres`, `cell_size = Vector3(1,1,1)`,
     `collision_mask = 7` y grupo `"colocable"`. Pintar celdas en `data`.
   - `Spawner` (`Marker3D`) con grupo `"spawner"`.
   - `NavigationGrid` (`Node`) con script `navigation_grid.gd`.
   - `PlayerSpawner` (`Marker3D`).
   - `EnemyRoutes` (`Node3D`) con una o varias rutas (script `enemy_route.gd`), cada una con `Marker3D` hijos
     (WP1, WP2, ...) en orden.

3. **Registrar en `res://src/core/main_game/main_game.gd`**: añadir `"res://src/levels/level_N.tscn"`
   al array `LEVELS` (el orden define la progresión; `load_next_level` avanza por índice).

## Checklist

- El `.gd` extiende `BaseLevel` y sobrescribe `get_default_player_spawn()`.
- Existe nodo `Spawner` (grupo `"spawner"`) y `PlayerSpawner` en la escena.
- Hay al menos una ruta `EnemyRoute` (grupo `"enemy_routes"`) con waypoints.
- Hay `NavigationGrid` (grupo `"navigation"`) y `Base` (grupo `"base"`).
- El nivel está en el array `LEVELS` de `main_game.gd`.
- Abrir Godot una vez para generar `.uid` e importar.
