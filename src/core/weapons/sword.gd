extends Node3D
class_name SwordWeapon

@export var damage := 25.0
@export var attack_duration := 0.45

@onready var area: Area3D = $Area3D
@onready var debug_hitbox: MeshInstance3D = get_node_or_null("Area3D/DebugHitbox")

@onready var blade_mesh: MeshInstance3D = get_node_or_null("Blade")
@onready var guard_mesh: MeshInstance3D = get_node_or_null("Guard")
@onready var handle_mesh: MeshInstance3D = get_node_or_null("Handle")
@onready var grip_mesh: MeshInstance3D = get_node_or_null("Grip")
@onready var pommel_mesh: MeshInstance3D = get_node_or_null("Pommel")

var _tween: Tween
var _rest_rotation := Vector3(8.0, -12.0, -8.0)
var _rest_position := Vector3(0.28, -0.32, -0.45)

@onready var anim_player: AnimationPlayer = _find_animation_player(self)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var res := _find_animation_player(child)
		if res:
			return res
	return null

func _ready() -> void:
	if area == null:
		push_error("[Sword] No se encontro Area3D en $Area3D")
		return
	area.monitoring = false
	if not area.body_entered.is_connected(_on_area_body_entered):
		area.body_entered.connect(_on_area_body_entered)
	if debug_hitbox:
		debug_hitbox.visible = false

	# Set upright stance
	rotation_degrees = _rest_rotation
	position = _rest_position

	if anim_player:
		if anim_player.has_animation("Espada_Idle"):
			anim_player.play("Espada_Idle")
		elif anim_player.has_animation("Track_Idle"):
			anim_player.play("Track_Idle")

	if has_node("Model") or get_node_or_null("Espada_Medieval_Realista") != null:
		return

	_build_realistic_medieval_sword()

func _build_realistic_medieval_sword() -> void:
	# Materials for PBR rendering
	var mat_steel := StandardMaterial3D.new()
	mat_steel.resource_name = "PolishedSteel"
	mat_steel.albedo_color = Color(0.92, 0.94, 0.98)
	mat_steel.metallic = 1.0
	mat_steel.roughness = 0.14
	mat_steel.metallic_specular = 0.95
	mat_steel.clearcoat_enabled = true
	mat_steel.clearcoat = 0.6
	mat_steel.clearcoat_roughness = 0.06

	var mat_guard_iron := StandardMaterial3D.new()
	mat_guard_iron.resource_name = "ForgedIron"
	mat_guard_iron.albedo_color = Color(0.58, 0.60, 0.65)
	mat_guard_iron.metallic = 0.95
	mat_guard_iron.roughness = 0.25

	var mat_brass := StandardMaterial3D.new()
	mat_brass.resource_name = "AntiqueBrass"
	mat_brass.albedo_color = Color(0.88, 0.70, 0.30)
	mat_brass.metallic = 0.9
	mat_brass.roughness = 0.22

	var mat_leather := StandardMaterial3D.new()
	mat_leather.resource_name = "DarkLeather"
	mat_leather.albedo_color = Color(0.14, 0.08, 0.04)
	mat_leather.metallic = 0.0
	mat_leather.roughness = 0.75
	mat_leather.rim_enabled = true
	mat_leather.rim = 0.35

	# 1. DOUBLE-EDGED TAPERED BLADE (Aligned with cutting edge forward along -Z)
	var st_blade := SurfaceTool.new()
	st_blade.begin(Mesh.PRIMITIVE_TRIANGLES)

	var y_base := 0.0
	var y_mid := 0.72
	var y_tip := 0.96

	# Blade geometry scaled to fit screen FOV perfectly (10.4cm width base)
	var v_base := _get_blade_section(y_base, 0.052, 0.009, 0.016, 0.004)
	var v_mid  := _get_blade_section(y_mid, 0.034, 0.006, 0.010, 0.004)
	var pt_tip := Vector3(0, y_tip, 0)

	_add_quad_strip(st_blade, v_base, v_mid)
	_add_tip_fan(st_blade, v_mid, pt_tip)

	st_blade.generate_normals()
	var blade_mesh_res := st_blade.commit()

	if blade_mesh:
		blade_mesh.mesh = blade_mesh_res
		blade_mesh.material_override = mat_steel
		blade_mesh.position = Vector3.ZERO
		blade_mesh.rotation = Vector3.ZERO
		blade_mesh.scale = Vector3.ONE

	# 2. IMPOSING CRUCIFORM GUARD
	var st_guard := SurfaceTool.new()
	st_guard.begin(Mesh.PRIMITIVE_TRIANGLES)
	_build_medieval_guard(st_guard)
	st_guard.generate_normals()
	var guard_mesh_res := st_guard.commit()

	if guard_mesh:
		guard_mesh.mesh = guard_mesh_res
		guard_mesh.material_override = mat_guard_iron
		guard_mesh.position = Vector3.ZERO
		guard_mesh.rotation = Vector3.ZERO
		guard_mesh.scale = Vector3.ONE

	# 3. CONTOURED LEATHER GRIP (Extends DOWN along -Y)
	var st_grip := SurfaceTool.new()
	st_grip.begin(Mesh.PRIMITIVE_TRIANGLES)
	_build_contoured_grip(st_grip)
	st_grip.generate_normals()
	var grip_mesh_res := st_grip.commit()

	var target_grip: MeshInstance3D = grip_mesh if grip_mesh else handle_mesh
	if target_grip:
		target_grip.mesh = grip_mesh_res
		target_grip.material_override = mat_leather
		target_grip.position = Vector3.ZERO
		target_grip.rotation = Vector3.ZERO
		target_grip.scale = Vector3.ONE

	# 4. WHEEL POMMEL & PEEN (-Y)
	var st_pommel := SurfaceTool.new()
	st_pommel.begin(Mesh.PRIMITIVE_TRIANGLES)
	_build_wheel_pommel(st_pommel)
	st_pommel.generate_normals()
	var pommel_mesh_res := st_pommel.commit()

	if pommel_mesh:
		pommel_mesh.mesh = pommel_mesh_res
		pommel_mesh.material_override = mat_brass
		pommel_mesh.position = Vector3.ZERO
		pommel_mesh.rotation = Vector3.ZERO
		pommel_mesh.scale = Vector3.ONE

# Blade flat face on X (left/right wide), thin edge on Z (depth), tall on Y
func _get_blade_section(y: float, half_w: float, half_t: float, f_w: float, f_dep: float) -> Array[Vector3]:
	return [
		Vector3(-half_w, y, 0),
		Vector3(-f_w, y, half_t),
		Vector3(0, y, half_t - f_dep),
		Vector3(f_w, y, half_t),
		Vector3(half_w, y, 0),
		Vector3(f_w, y, -half_t),
		Vector3(0, y, -(half_t - f_dep)),
		Vector3(-f_w, y, -half_t)
	]

func _add_quad_strip(st: SurfaceTool, secA: Array[Vector3], secB: Array[Vector3]) -> void:
	var count := secA.size()
	for i in range(count):
		var next := (i + 1) % count
		st.set_uv(Vector2(0, 0))
		st.add_vertex(secA[i])
		st.set_uv(Vector2(0, 1))
		st.add_vertex(secB[i])
		st.set_uv(Vector2(1, 1))
		st.add_vertex(secA[next])

		st.set_uv(Vector2(1, 1))
		st.add_vertex(secA[next])
		st.set_uv(Vector2(0, 1))
		st.add_vertex(secB[i])
		st.set_uv(Vector2(1, 0))
		st.add_vertex(secB[next])

func _add_tip_fan(st: SurfaceTool, sec: Array[Vector3], tip: Vector3) -> void:
	var count := sec.size()
	for i in range(count):
		var next := (i + 1) % count
		st.set_uv(Vector2(0, 0))
		st.add_vertex(sec[i])
		st.set_uv(Vector2(0.5, 1))
		st.add_vertex(tip)
		st.set_uv(Vector2(1, 0))
		st.add_vertex(sec[next])

func _build_medieval_guard(st: SurfaceTool) -> void:
	var y_center := 0.0
	var g_width := 0.17 # 34cm total quillon span
	var arm_steps := 8

	var prev_ring: Array[Vector3] = []
	for i in range(arm_steps + 1):
		var t := float(i) / float(arm_steps)
		var x := -0.03 - t * (g_width - 0.03)
		var y_curve := y_center + sin(t * PI * 0.4) * 0.025
		var rad_z: float = lerp(0.014, 0.010, t)
		var rad_y: float = lerp(0.014, 0.011, t)

		var ring: Array[Vector3] = []
		for a in range(8):
			var angle := a * (2.0 * PI / 8.0)
			ring.append(Vector3(x, y_curve + sin(angle) * rad_y, cos(angle) * rad_z))

		if i > 0:
			for a in range(8):
				var next := (a + 1) % 8
				st.set_uv(Vector2(0, 0))
				st.add_vertex(prev_ring[a])
				st.add_vertex(ring[a])
				st.add_vertex(prev_ring[next])

				st.set_uv(Vector2(0, 0))
				st.add_vertex(prev_ring[next])
				st.add_vertex(ring[a])
				st.add_vertex(ring[next])
		prev_ring = ring

	prev_ring = []
	for i in range(arm_steps + 1):
		var t := float(i) / float(arm_steps)
		var x := 0.03 + t * (g_width - 0.03)
		var y_curve := y_center + sin(t * PI * 0.4) * 0.025
		var rad_z: float = lerp(0.014, 0.010, t)
		var rad_y: float = lerp(0.014, 0.011, t)

		var ring: Array[Vector3] = []
		for a in range(8):
			var angle := a * (2.0 * PI / 8.0)
			ring.append(Vector3(x, y_curve + sin(angle) * rad_y, cos(angle) * rad_z))

		if i > 0:
			for a in range(8):
				var next := (a + 1) % 8
				st.set_uv(Vector2(0, 0))
				st.add_vertex(prev_ring[a])
				st.add_vertex(prev_ring[next])
				st.add_vertex(ring[a])

				st.set_uv(Vector2(0, 0))
				st.add_vertex(prev_ring[next])
				st.add_vertex(ring[next])
				st.add_vertex(ring[a])
		prev_ring = ring

	var b_min := Vector3(-0.035, -0.020, -0.032)
	var b_max := Vector3(0.035, 0.020, 0.032)
	_add_box(st, b_min, b_max)

func _build_contoured_grip(st: SurfaceTool) -> void:
	var y_start := 0.0
	var y_end := -0.24
	var steps := 20
	var prev_ring: Array[Vector3] = []

	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var y: float = lerp(y_start, y_end, t)

		var waist := 1.0 - 0.22 * sin(t * PI)
		var rib := 1.0 + 0.06 * sin(t * PI * 14.0)
		var rx := 0.018 * waist * rib
		var rz := 0.022 * waist * rib

		var ring: Array[Vector3] = []
		for a in range(12):
			var angle := a * (2.0 * PI / 12.0)
			ring.append(Vector3(cos(angle) * rx, y, sin(angle) * rz))

		if i > 0:
			for a in range(12):
				var next := (a + 1) % 12
				st.set_uv(Vector2(0, 0))
				st.add_vertex(prev_ring[a])
				st.add_vertex(ring[a])
				st.add_vertex(prev_ring[next])

				st.set_uv(Vector2(0, 0))
				st.add_vertex(prev_ring[next])
				st.add_vertex(ring[a])
				st.add_vertex(ring[next])
		prev_ring = ring

func _build_wheel_pommel(st: SurfaceTool) -> void:
	var y_center := -0.28
	var radius := 0.035
	var half_thickness := 0.014
	var sides := 16

	var ring_pos: Array[Vector3] = []
	var ring_neg: Array[Vector3] = []

	for i in range(sides):
		var angle := i * (2.0 * PI / float(sides))
		var dx := cos(angle) * radius
		var dy := y_center + sin(angle) * radius
		ring_pos.append(Vector3(dx, dy, half_thickness))
		ring_neg.append(Vector3(dx, dy, -half_thickness))

	for i in range(sides):
		var next := (i + 1) % sides
		st.set_uv(Vector2(0, 0))
		st.add_vertex(ring_pos[i])
		st.add_vertex(ring_neg[i])
		st.add_vertex(ring_pos[next])

		st.set_uv(Vector2(0, 0))
		st.add_vertex(ring_pos[next])
		st.add_vertex(ring_neg[i])
		st.add_vertex(ring_neg[next])

	var boss_center_pos := Vector3(0, y_center, half_thickness + 0.005)
	var boss_center_neg := Vector3(0, y_center, -(half_thickness + 0.005))

	for i in range(sides):
		var next := (i + 1) % sides
		st.set_uv(Vector2(0, 0))
		st.add_vertex(boss_center_pos)
		st.add_vertex(ring_pos[i])
		st.add_vertex(ring_pos[next])

		st.set_uv(Vector2(0, 0))
		st.add_vertex(boss_center_neg)
		st.add_vertex(ring_neg[next])
		st.add_vertex(ring_neg[i])

	var p_min := Vector3(-0.010, y_center - radius - 0.014, -0.010)
	var p_max := Vector3(0.010, y_center - radius, 0.010)
	_add_box(st, p_min, p_max)

func _add_box(st: SurfaceTool, min_p: Vector3, max_p: Vector3) -> void:
	var corners := [
		Vector3(min_p.x, min_p.y, min_p.z),
		Vector3(max_p.x, min_p.y, min_p.z),
		Vector3(max_p.x, max_p.y, min_p.z),
		Vector3(min_p.x, max_p.y, min_p.z),
		Vector3(min_p.x, min_p.y, max_p.z),
		Vector3(max_p.x, min_p.y, max_p.z),
		Vector3(max_p.x, max_p.y, max_p.z),
		Vector3(min_p.x, max_p.y, max_p.z)
	]
	var faces := [
		[0, 3, 2, 1],
		[5, 6, 7, 4],
		[4, 7, 3, 0],
		[1, 2, 6, 5],
		[3, 7, 6, 2],
		[4, 0, 1, 5]
	]
	for f in faces:
		st.set_uv(Vector2(0, 0))
		st.add_vertex(corners[f[0]])
		st.add_vertex(corners[f[1]])
		st.add_vertex(corners[f[2]])

		st.set_uv(Vector2(0, 0))
		st.add_vertex(corners[f[0]])
		st.add_vertex(corners[f[2]])
		st.add_vertex(corners[f[3]])

# ── SWORD SLASH ANIMATION ──────────────────────────────────────────────────
#
#  What the sketch shows:
#   • Sword is held HORIZONTAL at lower-right, blade pointing right/forward
#   • Attack sweeps in a HORIZONTAL arc from right → left
#   • Sword stays in the LOWER half of the screen the whole time
#   • Z-depth barely changes (no zooming in/out)
#   • Blade rolls from right-tilt to left-tilt as it sweeps across
#
#  Phases (total = attack_duration  ≈ 0.45 s):
#   1. Cock-back  15% – pull right, tip blade back
#   2. Raise      20% – bring sword to upper-right ready position
#   3. SLASH      40% – fast arc across screen (hitbox active)
#   4. Follow     10% – momentum carries it a touch further
#   5. Recovery   15% – smooth return to rest
# ─────────────────────────────────────────────────────────────────────────────
func attack() -> void:
	if anim_player:
		for anim_name in ["Espada_Ataque", "Track_Ataque", "Ataque"]:
			if anim_player.has_animation(anim_name):
				anim_player.play(anim_name)
				break

	if _tween and _tween.is_running():
		_tween.kill()

	var t := attack_duration
	_tween = create_tween()

	# 1. COCK-BACK — tiny pull to the right, blade tilts back
	#    pos: barely moves, stays low-right
	_tween.tween_property(self, "position",
		Vector3(0.32, -0.36, -0.43), t * 0.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "rotation_degrees",
		Vector3(5.0, -5.0, -20.0), t * 0.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# 2. RAISE — sword lifts to upper-right, cocked for the slash
	#    Y goes up but NOT above -0.10 (stays in bottom half)
	_tween.tween_property(self, "position",
		Vector3(0.34, -0.12, -0.45), t * 0.20)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "rotation_degrees",
		Vector3(-12.0, 8.0, -28.0), t * 0.20)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3. SLASH — fast diagonal arc: upper-right → lower-left
	#    • Z barely moves (-0.45 → -0.48), no zoom effect
	#    • Y drops gently to -0.38 (mid-low screen)
	#    • X sweeps left to -0.20
	#    • Z-rot rolls from -28° to +42° (blade tilts through the arc)
	#    • EXPO easing: starts fast, blade rockets across
	area.monitoring = true
	if debug_hitbox:
		debug_hitbox.visible = true
	_tween.tween_property(self, "position",
		Vector3(-0.20, -0.38, -0.48), t * 0.40)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	_tween.parallel().tween_property(self, "rotation_degrees",
		Vector3(12.0, -18.0, 42.0), t * 0.40)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	# 4. FOLLOW-THROUGH — momentum, sword dips slightly further
	_tween.tween_property(self, "position",
		Vector3(-0.26, -0.46, -0.46), t * 0.10)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "rotation_degrees",
		Vector3(16.0, -22.0, 52.0), t * 0.10)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 5. RECOVERY — smooth return to rest
	_tween.tween_property(self, "position",
		_rest_position, t * 0.15)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.parallel().tween_property(self, "rotation_degrees",
		_rest_rotation, t * 0.15)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	# Hitbox off after swing phase (15+20+40 = 75% of total duration)
	await get_tree().create_timer(t * 0.75).timeout
	area.monitoring = false
	if debug_hitbox:
		debug_hitbox.visible = false

func _on_area_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
