"""
===============================================================================
GENERADOR DE ESPADA MEDIEVAL REALISTA CON RIGGING Y ANIMACIONES PARA BLENDER
===============================================================================
Este script crea un modelo 3D detallado y semi-realista de una Espada Medieval,
la riggea con un Armature (esqueleto) y genera 3 animaciones keyframeadas:
  1. Espada_Idle (balanceo sutil de descanso)
  2. Espada_Ataque (tajo diagonal rápido)
  3. Espada_Bloqueo (parada/defensa de choque)

Las animaciones se exportan dentro del archivo GLTF/GLB para ser reproducidas
directamente por el AnimationPlayer de Godot Engine.

Compatibilidad: Blender 4.x / 5.x
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
# 2. SISTEMA DE MATERIALES PBR PROCEDURALES
# -----------------------------------------------------------------------------
def crear_material_acero_hoja():
    mat = bpy.data.materials.new(name="M_Acero_Hoja")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links

    bsdf = nodes.get("Principled BSDF")

    if 'Base Color' in bsdf.inputs:
        bsdf.inputs['Base Color'].default_value = (0.75, 0.77, 0.80, 1.0)
    if 'Metallic' in bsdf.inputs:
        bsdf.inputs['Metallic'].default_value = 0.95
    if 'Roughness' in bsdf.inputs:
        bsdf.inputs['Roughness'].default_value = 0.18

    tex_noise = nodes.new(type='ShaderNodeTexNoise')
    tex_noise.location = (-400, 100)
    tex_noise.inputs['Scale'].default_value = 150.0
    tex_noise.inputs['Detail'].default_value = 4.0

    bump = nodes.new(type='ShaderNodeBump')
    bump.location = (-150, 100)
    bump.inputs['Strength'].default_value = 0.03
    
    links.new(tex_noise.outputs['Fac'], bump.inputs['Height'])
    if 'Normal' in bsdf.inputs:
        links.new(bump.outputs['Normal'], bsdf.inputs['Normal'])

    return mat


def crear_material_guardapomo():
    mat = bpy.data.materials.new(name="M_Acero_Oscuro")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        if 'Base Color' in bsdf.inputs:
            bsdf.inputs['Base Color'].default_value = (0.4, 0.42, 0.45, 1.0)
        if 'Metallic' in bsdf.inputs:
            bsdf.inputs['Metallic'].default_value = 0.90
        if 'Roughness' in bsdf.inputs:
            bsdf.inputs['Roughness'].default_value = 0.30
    return mat


def crear_material_cuero():
    mat = bpy.data.materials.new(name="M_Cuero_Empunadura")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links

    bsdf = nodes.get("Principled BSDF")

    if 'Base Color' in bsdf.inputs:
        bsdf.inputs['Base Color'].default_value = (0.12, 0.07, 0.04, 1.0)
    if 'Metallic' in bsdf.inputs:
        bsdf.inputs['Metallic'].default_value = 0.0
    if 'Roughness' in bsdf.inputs:
        bsdf.inputs['Roughness'].default_value = 0.65

    tex_noise = nodes.new(type='ShaderNodeTexNoise')
    tex_noise.location = (-400, 0)
    tex_noise.inputs['Scale'].default_value = 80.0
    tex_noise.inputs['Detail'].default_value = 8.0

    bump = nodes.new(type='ShaderNodeBump')
    bump.location = (-150, 0)
    bump.inputs['Strength'].default_value = 0.12

    links.new(tex_noise.outputs['Fac'], bump.inputs['Height'])
    if 'Normal' in bsdf.inputs:
        links.new(bump.outputs['Normal'], bsdf.inputs['Normal'])

    return mat


def crear_material_laton():
    mat = bpy.data.materials.new(name="M_Laton_Detalles")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        if 'Base Color' in bsdf.inputs:
            bsdf.inputs['Base Color'].default_value = (0.85, 0.68, 0.28, 1.0)
        if 'Metallic' in bsdf.inputs:
            bsdf.inputs['Metallic'].default_value = 0.95
        if 'Roughness' in bsdf.inputs:
            bsdf.inputs['Roughness'].default_value = 0.25
    return mat

# -----------------------------------------------------------------------------
# 3. MODELADO DE COMPONENTES DE LA ESPADA
# -----------------------------------------------------------------------------

def construir_hoja(mat_acero):
    mesh = bpy.data.meshes.new("Mesh_Hoja")
    obj = bpy.data.objects.new("Espada_Hoja", mesh)
    bpy.context.collection.objects.link(obj)

    sections = [
        {"z": 0.00, "w_edge": 0.055, "th_mid": 0.015, "th_fuller": 0.009, "w_fuller": 0.018},
        {"z": 0.15, "w_edge": 0.052, "th_mid": 0.014, "th_fuller": 0.008, "w_fuller": 0.017},
        {"z": 0.70, "w_edge": 0.045, "th_mid": 0.012, "th_fuller": 0.006, "w_fuller": 0.014},
        {"z": 1.10, "w_edge": 0.035, "th_mid": 0.009, "th_fuller": 0.005, "w_fuller": 0.010},
        {"z": 1.35, "w_edge": 0.025, "th_mid": 0.007, "th_fuller": 0.007, "w_fuller": 0.000},
        {"z": 1.55, "w_edge": 0.012, "th_mid": 0.004, "th_fuller": 0.004, "w_fuller": 0.000},
        {"z": 1.68, "w_edge": 0.001, "th_mid": 0.001, "th_fuller": 0.001, "w_fuller": 0.000},
    ]

    verts = []
    faces = []

    for s in sections:
        z = s["z"]
        w = s["w_edge"]
        tm = s["th_mid"]
        tf = s["th_fuller"]
        wf = s["w_fuller"]

        if w <= 0.002:
            verts.append((0, 0, z))
        else:
            ring = [
                ( w, 0.0, z),
                ( wf,  tm, z),
                ( 0.0, tf, z),
                (-wf,  tm, z),
                (-w, 0.0, z),
                (-wf, -tm, z),
                ( 0.0,-tf, z),
                ( wf, -tm, z)
            ]
            verts.extend(ring)

    num_full_rings = len(sections) - 1
    for r in range(num_full_rings - 1):
        b1 = r * 8
        b2 = (r + 1) * 8
        for i in range(8):
            nxt = (i + 1) % 8
            faces.append([b1 + i, b1 + nxt, b2 + nxt, b2 + i])

    tip_idx = (num_full_rings - 1) * 8 + 8
    b_last = (num_full_rings - 1) * 8
    for i in range(8):
        nxt = (i + 1) % 8
        faces.append([b_last + i, b_last + nxt, tip_idx])

    faces.append([0, 7, 6, 5, 4, 3, 2, 1])

    mesh.from_pydata(verts, [], faces)
    mesh.update()

    for poly in mesh.polygons:
        poly.use_smooth = True

    obj.data.materials.append(mat_acero)
    return obj


def construir_guarda(mat_oscuro, mat_laton):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, -0.015))
    guarda = bpy.context.active_object
    guarda.name = "Espada_Guarda"
    guarda.scale = (0.36, 0.045, 0.035)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

    bevel = guarda.modifiers.new(name="Bisel", type='BEVEL')
    bevel.width = 0.005
    bevel.segments = 3

    guarda.data.materials.append(mat_oscuro)

    for sign in [-1, 1]:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.022, location=(sign * 0.18, 0, -0.015))
        remate = bpy.context.active_object
        remate.name = f"Guarda_Remate_{sign}"
        remate.data.materials.append(mat_laton)

    return guarda


def construir_empunadura(mat_cuero, mat_laton):
    bpy.ops.mesh.primitive_cylinder_add(radius=0.022, depth=0.24, location=(0, 0, -0.14))
    emp = bpy.context.active_object
    emp.name = "Espada_Empunadura"
    emp.scale = (0.7, 1.0, 1.0)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

    emp.data.materials.append(mat_cuero)

    bpy.ops.mesh.primitive_torus_add(major_radius=0.022, minor_radius=0.004, location=(0, 0, -0.14))
    anillo = bpy.context.active_object
    anillo.name = "Empunadura_Anillo"
    anillo.scale = (0.75, 1.05, 1.0)
    anillo.data.materials.append(mat_laton)

    return emp


def construir_pomo(mat_oscuro, mat_laton):
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.045, depth=0.04, location=(0, 0, -0.28))
    pomo = bpy.context.active_object
    pomo.name = "Espada_Pomo"
    pomo.rotation_euler = Euler((math.radians(90), 0, 0), 'XYZ')
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    pomo.data.materials.append(mat_oscuro)

    bpy.ops.mesh.primitive_cylinder_add(radius=0.025, depth=0.046, location=(0, 0, -0.28))
    medallon = bpy.context.active_object
    medallon.name = "Pomo_Medallon"
    medallon.rotation_euler = Euler((math.radians(90), 0, 0), 'XYZ')
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    medallon.data.materials.append(mat_laton)

    bpy.ops.mesh.primitive_cone_add(radius1=0.012, radius2=0.006, depth=0.02, location=(0, 0, -0.31))
    remache = bpy.context.active_object
    remache.name = "Pomo_Remache"
    remache.rotation_euler = Euler((math.radians(180), 0, 0), 'XYZ')
    remache.data.materials.append(mat_oscuro)

    return pomo

# -----------------------------------------------------------------------------
# 4. RIGGING Y ANIMACIONES KEYFRAME
# -----------------------------------------------------------------------------
def crear_rig_y_animaciones(espada):
    print("[Armature] Creando esqueleto de control...")
    bpy.ops.object.select_all(action='DESELECT')
    
    # Crear esqueleto (Armature)
    arm_data = bpy.data.armatures.new("Espada_ArmatureData")
    arm_obj = bpy.data.objects.new("Espada_Armature", arm_data)
    bpy.context.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj

    bpy.ops.object.mode_set(mode='EDIT')

    # Hueso de la empuñadura
    bone_handle = arm_data.edit_bones.new("Bone_Handle")
    bone_handle.head = Vector((0, 0, -0.28))
    bone_handle.tail = Vector((0, 0, 0.0))

    # Hueso de la hoja
    bone_blade = arm_data.edit_bones.new("Bone_Blade")
    bone_blade.head = Vector((0, 0, 0.0))
    bone_blade.tail = Vector((0, 0, 1.68))
    bone_blade.parent = bone_handle

    bpy.ops.object.mode_set(mode='OBJECT')

    # Parent mesh to armature with auto weights
    bpy.ops.object.select_all(action='DESELECT')
    espada.select_set(True)
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.parent_set(type='ARMATURE_AUTO')

    print("[Anim] Generando NLA Action Tracks (Idle, Ataque, Bloqueo)...")
    arm_obj.animation_data_create()

    # --- 1. ANIMACIÓN IDLE (Balanceo sutil) ---
    action_idle = bpy.data.actions.new(name="Espada_Idle")
    arm_obj.animation_data.action = action_idle
    bpy.ops.object.mode_set(mode='POSE')
    pbone = arm_obj.pose.bones.get("Bone_Handle")

    keyframes_idle = [
        (1,  (0, 0, 0), (0, 0, 0)),
        (15, (0, 0.005, -0.005), (math.radians(2), 0, math.radians(1))),
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
    track1.strips.new(name="Idle", start=1, action=action_idle)

    # --- 2. ANIMACIÓN ATAQUE (Tajo diagonal contundente) ---
    action_atk = bpy.data.actions.new(name="Espada_Ataque")
    arm_obj.animation_data.action = action_atk

    keyframes_atk = [
        (1,  (0, 0, 0), (0, 0, 0)),
        (4,  (0.05, -0.05, 0.05), (math.radians(-15), math.radians(10), math.radians(-20))), # Cargar golpe
        (10, (-0.1, 0.1, -0.05), (math.radians(35), math.radians(-30), math.radians(45))),   # Impacto
        (15, (-0.12, 0.08, -0.08), (math.radians(40), math.radians(-35), math.radians(50))), # Inercia
        (20, (0, 0, 0), (0, 0, 0)) # Retorno
    ]
    for frame, loc, rot in keyframes_atk:
        bpy.context.scene.frame_set(frame)
        pbone.location = Vector(loc)
        pbone.rotation_euler = Euler(rot, 'XYZ')
        pbone.keyframe_insert(data_path="location", frame=frame)
        pbone.keyframe_insert(data_path="rotation_euler", frame=frame)

    track2 = arm_obj.animation_data.nla_tracks.new()
    track2.name = "Track_Ataque"
    track2.strips.new(name="Ataque", start=1, action=action_atk)

    # --- 3. ANIMACIÓN BLOQUEO (Parada defensiva) ---
    action_blk = bpy.data.actions.new(name="Espada_Bloqueo")
    arm_obj.animation_data.action = action_blk

    keyframes_blk = [
        (1,  (0, 0, 0), (0, 0, 0)),
        (5,  (0.02, 0.08, 0.1), (math.radians(-45), math.radians(45), math.radians(20))),
        (12, (0.02, 0.08, 0.1), (math.radians(-45), math.radians(45), math.radians(20))),
        (15, (0, 0, 0), (0, 0, 0))
    ]
    for frame, loc, rot in keyframes_blk:
        bpy.context.scene.frame_set(frame)
        pbone.location = Vector(loc)
        pbone.rotation_euler = Euler(rot, 'XYZ')
        pbone.keyframe_insert(data_path="location", frame=frame)
        pbone.keyframe_insert(data_path="rotation_euler", frame=frame)

    track3 = arm_obj.animation_data.nla_tracks.new()
    track3.name = "Track_Bloqueo"
    track3.strips.new(name="Bloqueo", start=1, action=action_blk)

    bpy.ops.object.mode_set(mode='OBJECT')
    print("✓ Armature y 3 acciones creadas exitosamente.")
    return arm_obj

# -----------------------------------------------------------------------------
# 5. ENSAMBLE Y EXPORTACIÓN
# -----------------------------------------------------------------------------
def generar_espada_completa():
    print("[1/5] Limpiando escena...")
    limpiar_escena()

    print("[2/5] Creando materiales PBR...")
    mat_acero = crear_material_acero_hoja()
    mat_oscuro = crear_material_guardapomo()
    mat_cuero = crear_material_cuero()
    mat_laton = crear_material_laton()

    print("[3/5] Generando componentes 3D...")
    hoja = construir_hoja(mat_acero)
    guarda = construir_guarda(mat_oscuro, mat_laton)
    empunadura = construir_empunadura(mat_cuero, mat_laton)
    pomo = construir_pomo(mat_oscuro, mat_laton)

    print("[4/5] Uniendo malla y configurando origen...")
    bpy.ops.object.select_all(action='DESELECT')
    for obj in bpy.data.objects:
        if obj.type == 'MESH':
            obj.select_set(True)

    bpy.context.view_layer.objects.active = hoja
    bpy.ops.object.join()

    espada = bpy.context.active_object
    espada.name = "Espada_Medieval_Realista"

    bpy.context.scene.cursor.location = (0, 0, -0.14)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.context.scene.cursor.location = (0, 0, 0)

    print("[5/5] Rigging y creando animaciones keyframe...")
    crear_rig_y_animaciones(espada)

    print("\n✓ Espada medieval riggeada y animada con exito!")
    return espada


def exportar_modelo():
    output_dir = os.path.join(os.getcwd(), "assets")
    os.makedirs(output_dir, exist_ok=True)

    glb_path = os.path.join(output_dir, "espada_realista.glb")
    blend_path = os.path.join(output_dir, "espada_realista.blend")

    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format='GLB',
        use_selection=False,
        export_apply=True,
        export_animations=True
    )
    print(f"✓ Modelo GLTF animado exportado en: {glb_path}")

    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print(f"✓ Archivo Blender guardado en: {blend_path}")


if __name__ == "__main__":
    generar_espada_completa()
    exportar_modelo()
