---
name: crear-enemigo
description: Crea un tipo de enemigo nuevo en el tower defense (Godot 4.7). Usar cuando el usuario pida "crear/agregar un enemigo", "enemigo nuevo", "variante de enemigo", "jefe/boss", o un enemigo con stats particulares (rápido, tanque, etc.). Se hace con un .tscn que instancia enemy.tscn y sobreescribe stats, y se registra en WaveManager.
---

# Crear enemigo

## Arquitectura

- **Enemigo base**: `res://src/gameplay/enemies/enemy.tscn` (CharacterBody3D) con script
  `res://src/gameplay/enemies/enemy.gd` (`class_name Enemy`).
- El script tiene stats configurables vía `@export`: `move_speed`, `gravity`, `attack_range`,
  `aggro_range`, `attack_damage`, `attack_cooldown`, `attack_duration`, `knockback_force`,
  `knockback_decay`, `damage_flash_time`, `repath_interval`, `waypoint_distance`,
  `body_color`, `body_scale`, `max_health`, `reward`.
- En `_ready()` se añade al grupo `"enemies"` y conecta salud/daño.
- Los enemigos siguen rutas (`EnemyRoute`) o persiguen al jugador/base usando `NavigationGrid`.

## Pasos (variante con stats distintos)

1. **Crear `<nombre>_enemy.tscn`** en `res://src/gameplay/enemies/` que instancie el base:

```text
[gd_scene format=3 uid="uid://<uid_nuevo>"]

[ext_resource type="PackedScene" uid="uid://idwmj887361c" path="res://src/gameplay/enemies/enemy.tscn" id="1_base"]

[node name="<Nombre>Enemy" instance=ExtResource("1_base")]
move_speed = 5.5
attack_damage = 8.0
body_color = Color(1, 0.5, 0.15, 1)
body_scale = 0.7
max_health = 30.0
reward = 15
```

   - `uid://idwmj887361c` es el uid fijo de `enemy.tscn`. Solo se sobreescriben los stats que cambian.
   - Referencias: `enemy_fast.tscn` y `enemy_tank.tscn` siguen exactamente este patrón.

2. **Registrar en `res://src/core/main_game/wave_manager.gd`**:
   - Añadir `preload("res://src/gameplay/enemies/<nombre>_enemy.tscn")` al array `enemies` exportado.
   - Ajustar la selección en `_pick_enemy_scene(wave_number)` (probabilidades de `fast_chance`/`tank_chance`,
     o añadir tu propia probabilidad para la nueva variante, usando el índice correcto de `enemies`).

## Jefes (boss)

- Escena de jefe: `res://src/gameplay/enemies/boss_enemy.tscn`, referenciada por `WaveManager.BOSS_SCENE`.
- Un nivel es "de jefe" con `boss_level = true` en el `WaveManager`; el boss aparece en la última oleada.

## Enemigo con lógica propia (no solo stats)

Si el enemigo necesita comportamiento nuevo (no basta con sobreescribir exports), crear un `.gd`
que extienda `Enemy` (o `extends CharacterBody3D`) y asignarlo a una escena propia con la misma
estructura de nodos que `enemy.tscn`:
`CollisionShape3D`, `MeshInstance3D`, `HealthComponent`, `HitboxComponent`, `HealthBar`, `VisionComponent`.

## Checklist

- La nueva escena instancia `enemy.tscn` (o replica su estructura de nodos).
- El enemigo queda en el grupo `"enemies"` (automático si extiende el base).
- Está registrado en el array `enemies` de `wave_manager.gd` y aparece en `_pick_enemy_scene`.
- Abrir Godot una vez para generar `.uid` e importar.
