extends CharacterBody3D
class_name Enemy

enum EnemyState {
	IDLE,
	CHASING,
	ATTACKING,
	DEAD
}

@export var move_speed := 3.0
@export var gravity := 20.0
@export var attack_range := 2.0
@export var attack_damage := 10.0
@export var attack_cooldown := 1.2
@export var attack_duration := 0.3
@export var knockback_force := 6.0
@export var knockback_decay := 12.0
@export var damage_flash_time := 0.12
@export var repath_interval := 0.5
@export var waypoint_distance := 0.6

var state: EnemyState = EnemyState.IDLE

var _target: Node3D
var _attack_timer := 0.0
var _knockback_velocity := Vector3.ZERO
var _flash_tween: Tween
var _speed_modifiers: Dictionary = {}
var _vertical_impulse := 0.0
var _navigation: NavigationGrid
var _current_path := PackedVector3Array()
var _path_index := 0
var _repath_timer := 0.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var mesh: MeshInstance3D = $MeshInstance3D

var _damage_material := StandardMaterial3D.new()

@onready var player_cerca = false

func _ready() -> void:
	add_to_group("enemies")
	health_component.died.connect(_on_died)
	health_component.damaged.connect(_on_damaged)

	_damage_material.albedo_color = Color(1.0, 0.1, 0.1)
	_damage_material.emission = Color(1.0, 0.1, 0.1)
	_damage_material.emission_energy_multiplier = 1.5


func _physics_process(delta: float) -> void:
	if state == EnemyState.DEAD:
		return

	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_repath_timer = maxf(_repath_timer - delta, 0.0)
	_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, knockback_decay * delta)

	if _knockback_velocity.length() > 0.01 or _vertical_impulse > 0.0:
		velocity.x = _knockback_velocity.x
		velocity.z = _knockback_velocity.z
		_apply_gravity(delta)
		velocity.y += _knockback_velocity.y
		if _vertical_impulse > 0.0:
			velocity.y = _vertical_impulse
			_vertical_impulse = 0.0
		move_and_slide()
		return

	_find_target()
	_apply_gravity(delta)

	if _target == null:
		velocity.x = 0.0
		velocity.z = 0.0
		set_state(EnemyState.IDLE)
		move_and_slide()
		return

	var distance := global_position.distance_to(_target.global_position)

	if distance <= attack_range:
		velocity.x = 0.0
		velocity.z = 0.0
		set_state(EnemyState.ATTACKING)
		_try_attack()
	else:
		set_state(EnemyState.CHASING)
		_chase()

	move_and_slide()


func _find_target() -> void:
	if player_cerca == false:
		var base := get_tree().get_first_node_in_group("base") as Node3D
		if base != null:
			_target = base
			return
	else:
		_target = get_tree().get_first_node_in_group("player") as Node3D
		
	if _target == null:
		push_error("Couldnt find the target, the base is not in the tree or the player is not in range and couldnt loaded")
	return

func _chase() -> void:
	if _target == null:
		return

	_update_path()
	var direction := _get_path_direction()
	velocity.x = direction.x * get_effective_speed()
	velocity.z = direction.z * get_effective_speed()
	if direction.length() > 0.01:
		_face_direction(direction)


func _update_path() -> void:
	if _navigation == null:
		_navigation = get_tree().get_first_node_in_group("navigation") as NavigationGrid
	if _navigation == null:
		_current_path = PackedVector3Array()
		return
	if _repath_timer > 0.0 and not _current_path.is_empty():
		return
	_repath_timer = repath_interval
	_current_path = _navigation.find_path(global_position, _target.global_position)
	_path_index = 0


func _get_path_direction() -> Vector3:
	if _current_path.is_empty():
		return _direction_to_target()

	while _path_index < _current_path.size():
		var waypoint := _current_path[_path_index]
		var to_waypoint := waypoint - global_position
		to_waypoint.y = 0.0
		if to_waypoint.length() <= waypoint_distance:
			_path_index += 1
			continue
		return to_waypoint.normalized()

	return _direction_to_target()


func _direction_to_target() -> Vector3:
	if _target == null:
		return Vector3.ZERO
	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	if to_target.length() < 0.01:
		return Vector3.ZERO
	return to_target.normalized()


func _face_direction(direction: Vector3) -> void:
	look_at(global_position + direction, Vector3.UP)


func _try_attack() -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = attack_cooldown

	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	if to_target.length() > 0.01:
		_face_direction(to_target.normalized())

	hitbox_component.activate(attack_damage)
	await get_tree().create_timer(attack_duration).timeout
	if not is_inside_tree():
		return
	hitbox_component.deactivate()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0


func take_damage(amount: float) -> void:
	health_component.take_damage(amount)
	_apply_knockback()


func take_trap_damage(amount: float) -> void:
	health_component.take_damage(amount)


func apply_speed_modifier(modifier_id: String, factor: float) -> void:
	_speed_modifiers[modifier_id] = factor


func remove_speed_modifier(modifier_id: String) -> void:
	_speed_modifiers.erase(modifier_id)


func get_effective_speed() -> float:
	var multiplier := 1.0
	for factor in _speed_modifiers.values():
		multiplier *= factor
	return move_speed * maxf(multiplier, 0.0)


func launch_up(force: float) -> void:
	_vertical_impulse = force


func push(direction: Vector3, force: float) -> void:
	_knockback_velocity = direction.normalized() * force


func knock_back(direction: Vector3, force: float) -> void:
	var dir := direction
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	_knockback_velocity = dir.normalized() * force


func _apply_knockback() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var direction := global_position - player.global_position
	direction.y = 0.0
	if direction.length() < 0.01:
		return
	_knockback_velocity = direction.normalized() * knockback_force


func _on_damaged(_amount: float) -> void:
	_flash_damage()


func _flash_damage() -> void:
	if mesh == null:
		return
	if _flash_tween:
		_flash_tween.kill()
	mesh.material_override = _damage_material
	_flash_tween = create_tween()
	_flash_tween.tween_interval(damage_flash_time)
	_flash_tween.tween_callback(func() -> void: mesh.material_override = null)


func set_state(new_state: EnemyState) -> void:
	if state == new_state:
		return
	state = new_state


func _on_died() -> void:
	set_state(EnemyState.DEAD)
	hitbox_component.deactivate()
	queue_free()


func _on_vision_component_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_cerca = true


func _on_vision_component_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_cerca = false
