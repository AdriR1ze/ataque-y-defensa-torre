extends Node
class_name WeaponComponent

const SWORD_SCENE := preload("res://src/core/weapons/sword.tscn")
const BOW_SCENE := preload("res://src/core/weapons/bow.tscn")

@export var attack_recovery := 0.4

var current_weapon: Node3D
var _attacking := false

@onready var player: Player = get_parent()
@onready var weapon_marker: Marker3D = get_node("../CameraComponent/Camera3D/WeaponMarker")

func _ready() -> void:
	if weapon_marker == null:
		push_error("[WeaponComponent] No se encontro WeaponMarker en CameraComponent/Camera3D")
		return
	equip_weapon(player.current_weapon)

func _process(_delta: float) -> void:
	if player.state == Player.PlayerState.DEAD:
		return
	if Input.is_action_just_pressed("attacking"):
		_handle_attack()
	if Input.is_action_just_pressed("interact"):
		switch_weapon()

func _handle_attack() -> void:
	if _attacking:
		return
	_attacking = true

	if current_weapon == null:
		push_error("[WeaponComponent] No hay arma equipada al atacar")
		_attacking = false
		return

	if not current_weapon.has_method("attack"):
		push_error("[WeaponComponent] El arma actual no tiene metodo attack()")
		_attacking = false
		return

	player.set_state(Player.PlayerState.ATTACKING)
	current_weapon.attack()
	await get_tree().create_timer(attack_recovery).timeout

	if player.state == Player.PlayerState.ATTACKING:
		player.set_state(Player.PlayerState.IDLE)

	_attacking = false

func equip_weapon(type: Player.WeaponType) -> void:
	if current_weapon:
		current_weapon.queue_free()

	match type:
		Player.WeaponType.SWORD:
			current_weapon = SWORD_SCENE.instantiate()
		Player.WeaponType.BOW:
			current_weapon = BOW_SCENE.instantiate()

	weapon_marker.add_child(current_weapon)
	current_weapon.position = Vector3.ZERO
	current_weapon.rotation = Vector3.ZERO

func switch_weapon() -> void:
	if player.current_weapon == Player.WeaponType.SWORD:
		player.current_weapon = Player.WeaponType.BOW
	else:
		player.current_weapon = Player.WeaponType.SWORD
	equip_weapon(player.current_weapon)
