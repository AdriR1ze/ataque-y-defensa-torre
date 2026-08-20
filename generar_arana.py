"""
===============================================================================
GENERADOR DE ARAÑA TURBIA / REALISTA PARA BLENDER
===============================================================================
Script en Python para Blender 4.x / 5.x que construye:
  1. Modelo 3D de Araña Turbia (Cefalotórax, Abdomen globoso, 8 Ojos emisivos,
     Colmillos venenosos, 8 Patas articuladas).
  2. Materiales PBR (Quitina oscura, Ojos emisivos rojos, Colmillos con veneno).
  3. Armature Esqueleto + 3 Animaciones (Arana_Idle, Arana_Caminar, Arana_Ataque).
  4. Exportación automática a GLTF (.glb) y .blend en la carpeta assets/.

Ejecución desde línea de comandos:
  blender --background --python generar_arana.py
===============================================================================
"""

import bpy
import math
import os
from mathutils import Vector, Euler

# -----------------------------------------------------------------------------
# 1. LIMPIEZA DE ESCENA
# -----------------------------------------------------------------------------
def limpiar_escena():
    if bpy.context.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for block in [bpy.data.meshes, bpy.data.materials, bpy.data.armatures, bpy.data.actions]:
        for item in list(block):
            block.remove(item)

# -----------------------------------------------------------------------------
# 2. MATERIALES PBR
# -----------------------------------------------------------------------------
def crear_materiales():
    # Material 1: Quitina Oscura de Araña
    mat_quitina = bpy.data.materials.new(name="M_Quitina_Arana")
    mat_quitina.use_nodes = True
    bsdf_q = mat_quitina.node_tree.nodes.get("Principled BSDF")
    if bsdf_q:
        if 'Base Color' in bsdf_q.inputs:
            bsdf_q.inputs['Base Color'].default_value = (0.08, 0.05, 0.07, 1.0)
        if 'Metallic' in bsdf_q.inputs:
            bsdf_q.inputs['Metallic'].default_value = 0.25
        if 'Roughness' in bsdf_q.inputs:
            bsdf_q.inputs['Roughness'].default_value = 0.22

    # Material 2: Ojos Rojos Emisivos Turbios
    mat_ojos = bpy.data.materials.new(name="M_Ojos_Emisivos")
    mat_ojos.use_nodes = True
    bsdf_o = mat_ojos.node_tree.nodes.get("Principled BSDF")
    if bsdf_o:
        if 'Base Color' in bsdf_o.inputs:
            bsdf_o.inputs['Base Color'].default_value = (1.0, 0.02, 0.05, 1.0)
        if 'Emission Color' in bsdf_o.inputs:
            bsdf_o.inputs['Emission Color'].default_value = (1.0, 0.02, 0.05, 1.0)
        elif 'Emission' in bsdf_o.inputs:
            bsdf_o.inputs['Emission'].default_value = (1.0, 0.02, 0.05, 1.0)
        if 'Emission Strength' in bsdf_o.inputs:
            bsdf_o.inputs['Emission Strength'].default_value = 4.0

    # Material 3: Colmillos con Veneno Verde
    mat_colmillos = bpy.data.materials.new(name="M_Colmillos_Veneno")
    mat_colmillos.use_nodes = True
    bsdf_c = mat_colmillos.node_tree.nodes.get("Principled BSDF")
    if bsdf_c:
        if 'Base Color' in bsdf_c.inputs:
            bsdf_c.inputs['Base Color'].default_value = (0.05, 0.85, 0.15, 1.0)
        if 'Roughness' in bsdf_c.inputs:
            bsdf_c.inputs['Roughness'].default_value = 0.1
        if 'Emission Color' in bsdf_c.inputs:
            bsdf_c.inputs['Emission Color'].default_value = (0.05, 0.85, 0.15, 1.0)
        if 'Emission Strength' in bsdf_c.inputs:
            bsdf_c.inputs['Emission Strength'].default_value = 1.5

    return mat_quitina, mat_ojos, mat_colmillos

# -----------------------------------------------------------------------------
# 3. MODELADO DE LA GEOMETRÍA DE LA ARAÑA
# -----------------------------------------------------------------------------
def construir_arana(mat_quitina, mat_ojos, mat_colmillos):
    partes = []

    # A. Cefalotórax (Cabeza/Tórax)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.45, location=(0, -0.2, 0.4))
    head = bpy.context.active_object
    head.name = "Arana_Head"
    head.scale = (0.9, 1.1, 0.75)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    head.data.materials.append(mat_quitina)
    partes.append(head)

    # B. Abdomen (Cuerpo trasero globoso turbio)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.75, location=(0, 0.8, 0.65))
    abd = bpy.context.active_object
    abd.name = "Arana_Abdomen"
    abd.scale = (1.0, 1.35, 1.1)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    abd.data.materials.append(mat_quitina)
    partes.append(abd)

    # C. 8 Ojos Múltiples Asimétricos
    posiciones_ojos = [
        (-0.12, -0.62, 0.48, 0.07), (0.12, -0.62, 0.48, 0.07),   # Ojos principales centro
        (-0.24, -0.58, 0.52, 0.05), (0.24, -0.58, 0.52, 0.05),   # Ojos superiores
        (-0.30, -0.54, 0.44, 0.04), (0.30, -0.54, 0.44, 0.04),   # Ojos laterales
        (-0.08, -0.64, 0.40, 0.04), (0.08, -0.64, 0.40, 0.04),   # Ojos inferiores
    ]
    for idx, (x, y, z, r) in enumerate(posiciones_ojos):
        bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=(x, y, z))
        ojo = bpy.context.active_object
        ojo.name = f"Ojo_{idx+1}"
        ojo.data.materials.append(mat_ojos)
        partes.append(ojo)

    # D. Colmillos / Quelíceros con Veneno
    for sign in [-1, 1]:
        bpy.ops.mesh.primitive_cone_add(radius1=0.07, depth=0.28, location=(sign * 0.12, -0.65, 0.26))
        colmillo = bpy.context.active_object
        colmillo.name = f"Colmillo_{sign}"
        colmillo.rotation_euler = Euler((math.radians(35), 0, sign * math.radians(-15)), 'XYZ')
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
        colmillo.data.materials.append(mat_colmillos)
        partes.append(colmillo)

    # E. 8 Patas Articuladas Largas
    # Cada pata tiene 3 segmentos: Femur, Tibia, Tarsus
    angulos_patas = [
        # L1, L2, L3, L4 (Izquierda)
        (-1, 0, math.radians(-65), 1.15),
        (-1, 1, math.radians(-30), 1.25),
        (-1, 2, math.radians(20),  1.20),
        (-1, 3, math.radians(60),  1.10),
        # R1, R2, R3, R4 (Derecha)
        (1, 0, math.radians(65),  1.15),
        (1, 1, math.radians(30),  1.25),
        (1, 2, math.radians(-20), 1.20),
        (1, 3, math.radians(-60), 1.10),
    ]

    for side, num, angle_y, length in angulos_patas:
        base_x = side * 0.35
        base_y = -0.4 + num * 0.25
        base_z = 0.4

        # Femur (hacia arriba y afuera)
        femur_end = (base_x + side * 0.45 * math.cos(angle_y), base_y + 0.45 * math.sin(angle_y), base_z + 0.45)
        bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=0.55, location=((base_x + femur_end[0])/2, (base_y + femur_end[1])/2, (base_z + femur_end[2])/2))
        femur = bpy.context.active_object
        femur.name = f"Pata_{side}_{num}_Femur"
        femur.data.materials.append(mat_quitina)
        partes.append(femur)

        # Tibia (hacia abajo y afuera)
        tibia_end = (femur_end[0] + side * 0.5 * math.cos(angle_y), femur_end[1] + 0.5 * math.sin(angle_y), 0.0)
        bpy.ops.mesh.primitive_cylinder_add(radius=0.03, depth=0.7, location=((femur_end[0] + tibia_end[0])/2, (femur_end[1] + tibia_end[1])/2, (femur_end[2] + tibia_end[2])/2))
        tibia = bpy.context.active_object
        tibia.name = f"Pata_{side}_{num}_Tibia"
        tibia.data.materials.append(mat_quitina)
        partes.append(tibia)

    # Fusionar mallas en una única malla de araña
    bpy.ops.object.select_all(action='DESELECT')
    for p in partes:
        p.select_set(True)

    bpy.context.view_layer.objects.active = head
    bpy.ops.object.join()

    arana = bpy.context.active_object
    arana.name = "Arana_Turbia_Mesh"

    # Centrar el origen en la base del suelo (Z=0)
    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')

    return arana

# -----------------------------------------------------------------------------
# 4. RIGGING Y ANIMACIONES
# -----------------------------------------------------------------------------
def crear_rig_y_animaciones(arana):
    print("[Armature] Creando esqueleto de control de la Araña...")
    bpy.ops.object.select_all(action='DESELECT')

    arm_data = bpy.data.armatures.new("Arana_ArmatureData")
    arm_obj = bpy.data.objects.new("Arana_Armature", arm_data)
    bpy.context.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj

    bpy.ops.object.mode_set(mode='EDIT')

    # Hueso raíz del cuerpo
    bone_body = arm_data.edit_bones.new("Bone_Body")
    bone_body.head = Vector((0, 0, 0.4))
    bone_body.tail = Vector((0, 0.5, 0.6))

    bpy.ops.object.mode_set(mode='OBJECT')

    # Parent mesh to armature
    arana.select_set(True)
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.parent_set(type='ARMATURE_AUTO')

    print("[Anim] Creando animaciones NLA para Araña...")
    arm_obj.animation_data_create()
    pbone = arm_obj.pose.bones.get("Bone_Body")

    # --- 1. ANIMACIÓN IDLE (Mecimiento amenazante) ---
    action_idle = bpy.data.actions.new(name="Arana_Idle")
    arm_obj.animation_data.action = action_idle
    bpy.ops.object.mode_set(mode='POSE')

    keyframes_idle = [
        (1,  (0, 0, 0), (0, 0, 0)),
        (15, (0, 0, -0.06), (math.radians(3), 0, 0)),
        (30, (0, 0, 0), (0, 0, 0))
    ]
    for frame, loc, rot in keyframes_idle:
        bpy.context.scene.frame_set(frame)
        pbone.location = Vector(loc)
        pbone.rotation_euler = Euler(rot, 'XYZ')
        pbone.keyframe_insert(data_path="location", frame=frame)
        pbone.keyframe_insert(data_path="rotation_euler", frame=frame)

    track1 = arm_obj.animation_data.nla_tracks.new()
    track1.name = "Track_Idle"
    track1.strips.new(name="Arana_Idle", start=1, action=action_idle)

    # --- 2. ANIMACIÓN CAMINAR (Caminata inquieta) ---
    action_walk = bpy.data.actions.new(name="Arana_Caminar")
    arm_obj.animation_data.action = action_walk

    keyframes_walk = [
        (1,  (0, 0, 0), (0, 0, 0)),
        (6,  (0.04, 0.05, 0.04), (math.radians(-2), math.radians(4), math.radians(-3))),
        (12, (0, 0.1, 0), (0, 0, 0)),
        (18, (-0.04, 0.05, 0.04), (math.radians(2), math.radians(-4), math.radians(3))),
        (24, (0, 0, 0), (0, 0, 0))
    ]
    for frame, loc, rot in keyframes_walk:
        bpy.context.scene.frame_set(frame)
        pbone.location = Vector(loc)
        pbone.rotation_euler = Euler(rot, 'XYZ')
        pbone.keyframe_insert(data_path="location", frame=frame)
        pbone.keyframe_insert(data_path="rotation_euler", frame=frame)

    track2 = arm_obj.animation_data.nla_tracks.new()
    track2.name = "Track_Caminar"
    track2.strips.new(name="Arana_Caminar", start=1, action=action_walk)

    # --- 3. ANIMACIÓN ATAQUE (Embestida con quelíceros) ---
    action_atk = bpy.data.actions.new(name="Arana_Ataque")
    arm_obj.animation_data.action = action_atk

    keyframes_atk = [
        (1,  (0, 0, 0), (0, 0, 0)),
        (5,  (0, -0.15, 0.12), (math.radians(-25), 0, 0)), # Erguirse
        (10, (0, 0.3, -0.05), (math.radians(35), 0, 0)),   # Mordida hacia adelante
        (15, (0, 0.2, 0.0), (math.radians(20), 0, 0)),    # Inercia
        (20, (0, 0, 0), (0, 0, 0))                         # Retorno
    ]
    for frame, loc, rot in keyframes_atk:
        bpy.context.scene.frame_set(frame)
        pbone.location = Vector(loc)
        pbone.rotation_euler = Euler(rot, 'XYZ')
        pbone.keyframe_insert(data_path="location", frame=frame)
        pbone.keyframe_insert(data_path="rotation_euler", frame=frame)

    track3 = arm_obj.animation_data.nla_tracks.new()
    track3.name = "Track_Ataque"
    track3.strips.new(name="Arana_Ataque", start=1, action=action_atk)

    bpy.ops.object.mode_set(mode='OBJECT')
    print("✓ Rigging y animaciones de araña completadas!")
    return arm_obj

# -----------------------------------------------------------------------------
# 5. GENERACIÓN Y EXPORTACIÓN
# -----------------------------------------------------------------------------
def generar_y_exportar():
    print("[1/4] Limpiando escena...")
    limpiar_escena()

    print("[2/4] Creando materiales PBR de araña...")
    mat_quitina, mat_ojos, mat_colmillos = crear_materiales()

    print("[3/4] Construyendo modelo 3D de araña...")
    arana = construir_arana(mat_quitina, mat_ojos, mat_colmillos)
    crear_rig_y_animaciones(arana)

    print("[4/4] Exportando a assets/arana.glb...")
    output_dir = os.path.join(os.getcwd(), "assets")
    os.makedirs(output_dir, exist_ok=True)

    glb_path = os.path.join(output_dir, "arana.glb")
    blend_path = os.path.join(output_dir, "arana.blend")

    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format='GLB',
        use_selection=False,
        export_apply=True,
        export_animations=True
    )
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)

    print(f"\n✓ Araña exportada exitosamente en:")
    print(f"  - GLB: {glb_path}")
    print(f"  - BLEND: {blend_path}")

if __name__ == "__main__":
    generar_y_exportar()
