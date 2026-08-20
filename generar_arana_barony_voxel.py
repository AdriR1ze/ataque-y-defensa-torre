"""
===============================================================================
GENERATOR DE ARAÑA VOXEL FIEL A BARONY (PROPORCIONES AJUSTADAS)
===============================================================================
Ajuste de proporciones para que la cabeza/cefalotórax sea compacta y estilizada,
evitando el efecto de "cuadrado gigante":
  - Cabeza/Cefalotórax compacto y rebajado: (0.45, 0.48, 0.28).
  - Abdomen proporcionalmente más grande y elevado: (0.68, 0.82, 0.52).
  - Quelíceros/Colmillos refinados en el hocico frontal.
  - 8 Ojos Voxel pequeños alineados en el frente.
  - 8 Patas articuladas en 3 segmentos delgados en cuadrícula Voxel.

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
# 2. MATERIALES VOXEL EXACTOS DE BARONY
# -----------------------------------------------------------------------------
def crear_materiales_voxel():
    mat_quitina = bpy.data.materials.new(name="M_Voxel_Quitina")
    mat_quitina.use_nodes = True
    bsdf_q = mat_quitina.node_tree.nodes.get("Principled BSDF")
    if bsdf_q:
        if 'Base Color' in bsdf_q.inputs:
            bsdf_q.inputs['Base Color'].default_value = (0.08, 0.05, 0.03, 1.0)
        if 'Roughness' in bsdf_q.inputs:
            bsdf_q.inputs['Roughness'].default_value = 0.4

    mat_abdomen = bpy.data.materials.new(name="M_Voxel_Abdomen")
    mat_abdomen.use_nodes = True
    bsdf_a = mat_abdomen.node_tree.nodes.get("Principled BSDF")
    if bsdf_a:
        if 'Base Color' in bsdf_a.inputs:
            bsdf_a.inputs['Base Color'].default_value = (0.22, 0.12, 0.06, 1.0)
        if 'Roughness' in bsdf_a.inputs:
            bsdf_a.inputs['Roughness'].default_value = 0.5

    mat_ojos = bpy.data.materials.new(name="M_Voxel_Ojos")
    mat_ojos.use_nodes = True
    bsdf_o = mat_ojos.node_tree.nodes.get("Principled BSDF")
    if bsdf_o:
        if 'Base Color' in bsdf_o.inputs:
            bsdf_o.inputs['Base Color'].default_value = (1.0, 0.0, 0.0, 1.0)
        if 'Emission Color' in bsdf_o.inputs:
            bsdf_o.inputs['Emission Color'].default_value = (1.0, 0.0, 0.0, 1.0)
        elif 'Emission' in bsdf_o.inputs:
            bsdf_o.inputs['Emission'].default_value = (1.0, 0.0, 0.0, 1.0)
        if 'Emission Strength' in bsdf_o.inputs:
            bsdf_o.inputs['Emission Strength'].default_value = 6.0

    mat_hueso = bpy.data.materials.new(name="M_Voxel_Hueso")
    mat_hueso.use_nodes = True
    bsdf_h = mat_hueso.node_tree.nodes.get("Principled BSDF")
    if bsdf_h:
        if 'Base Color' in bsdf_h.inputs:
            bsdf_h.inputs['Base Color'].default_value = (0.85, 0.80, 0.65, 1.0)
        if 'Roughness' in bsdf_h.inputs:
            bsdf_h.inputs['Roughness'].default_value = 0.3

    mat_veneno = bpy.data.materials.new(name="M_Voxel_Veneno")
    mat_veneno.use_nodes = True
    bsdf_v = mat_veneno.node_tree.nodes.get("Principled BSDF")
    if bsdf_v:
        if 'Base Color' in bsdf_v.inputs:
            bsdf_v.inputs['Base Color'].default_value = (0.0, 1.0, 0.2, 1.0)
        if 'Emission Color' in bsdf_v.inputs:
            bsdf_v.inputs['Emission Color'].default_value = (0.0, 1.0, 0.2, 1.0)
        elif 'Emission' in bsdf_v.inputs:
            bsdf_v.inputs['Emission'].default_value = (0.0, 1.0, 0.2, 1.0)
        if 'Emission Strength' in bsdf_v.inputs:
            bsdf_v.inputs['Emission Strength'].default_value = 3.0

    return mat_quitina, mat_abdomen, mat_ojos, mat_hueso, mat_veneno


def crear_bloque_voxel(nombre, loc, scale, mat):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    obj = bpy.context.active_object
    obj.name = nombre
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)

    for poly in obj.data.polygons:
        poly.use_smooth = False

    return obj

# -----------------------------------------------------------------------------
# 3. ARAÑA BARONY VOXEL CON PROPORCIONES EXACTAS
# -----------------------------------------------------------------------------
def construir_arana_barony_proporcionada(mat_q, mat_a, mat_o, mat_h, mat_v):
    partes = []

    # A. Cefalotórax / Cabeza (Compacto y rebajado)
    head = crear_bloque_voxel("Barony_Thorax_Voxel", (0, -0.22, 0.32), (0.45, 0.48, 0.28), mat_q)
    partes.append(head)

    # Hocico frontal rebajado (Snout)
    snout = crear_bloque_voxel("Barony_Snout_Voxel", (0, -0.47, 0.26), (0.35, 0.12, 0.20), mat_q)
    partes.append(snout)

    # B. Abdomen (Prominente, más grande que la cabeza)
    abd_main = crear_bloque_voxel("Barony_Abdomen_Voxel", (0, 0.42, 0.45), (0.68, 0.82, 0.52), mat_a)
    partes.append(abd_main)

    # Franja dorsal del abdomen
    abd_stripe = crear_bloque_voxel("Barony_Abdomen_Stripe", (0, 0.42, 0.72), (0.42, 0.65, 0.08), mat_q)
    partes.append(abd_stripe)

    # C. 8 Ojos Voxel pequeños bien posicionados en el frente
    ojos_coords = [
        # Ojos centrales principales
        (-0.10, -0.53, 0.30, (0.07, 0.03, 0.07)), (0.10, -0.53, 0.30, (0.07, 0.03, 0.07)),
        # Ojos superiores
        (-0.16, -0.53, 0.36, (0.05, 0.03, 0.05)), (0.16, -0.53, 0.36, (0.05, 0.03, 0.05)),
        # Ojos laterales
        (-0.23, -0.45, 0.30, (0.03, 0.06, 0.05)), (0.23, -0.45, 0.30, (0.03, 0.06, 0.05)),
        # Ojos inferiores
        (-0.06, -0.53, 0.22, (0.05, 0.03, 0.05)), (0.06, -0.53, 0.22, (0.05, 0.03, 0.05)),
    ]
    for idx, (x, y, z, sc) in enumerate(ojos_coords):
        ojo = crear_bloque_voxel(f"Ojo_Voxel_{idx+1}", (x, y, z), sc, mat_o)
        partes.append(ojo)

    # D. Quelíceros / Colmillos Voxel delgados
    for sign in [-1, 1]:
        fang_base = crear_bloque_voxel(f"Fang_Base_{sign}", (sign * 0.09, -0.54, 0.16), (0.07, 0.14, 0.10), mat_h)
        partes.append(fang_base)

        fang_tip = crear_bloque_voxel(f"Fang_Tip_{sign}", (sign * 0.09, -0.61, 0.11), (0.05, 0.08, 0.06), mat_v)
        partes.append(fang_tip)

    # E. 8 Patas Articuladas delgadas en cuadrícula Voxel
    patas_config = [
        (-1, 0, -0.35, math.radians(-55)),
        (-1, 1, -0.18, math.radians(-20)),
        (-1, 2,  0.02, math.radians(20)),
        (-1, 3,  0.22, math.radians(55)),
        (1,  0, -0.35, math.radians(55)),
        (1,  1, -0.18, math.radians(20)),
        (1,  2,  0.02, math.radians(-20)),
        (1,  3,  0.22, math.radians(-55)),
    ]

    for side, num, py, angle_y in patas_config:
        bx = side * 0.23
        bz = 0.32

        # Fémur Voxel
        f_mid_x = bx + side * 0.20 * math.cos(angle_y)
        f_mid_y = py + 0.20 * math.sin(angle_y)
        f_mid_z = bz + 0.16

        femur = crear_bloque_voxel(f"Leg_{side}_{num}_Femur", (f_mid_x, f_mid_y, f_mid_z), (0.05, 0.05, 0.36), mat_q)
        femur.rotation_euler = Euler((math.radians(-22), angle_y, side * math.radians(-12)), 'XYZ')
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        partes.append(femur)

        # Tibia Voxel
        t_end_x = f_mid_x + side * 0.24 * math.cos(angle_y)
        t_end_y = f_mid_y + 0.24 * math.sin(angle_y)
        t_mid_z = 0.15

        tibia = crear_bloque_voxel(f"Leg_{side}_{num}_Tibia", (t_end_x, t_end_y, t_mid_z), (0.04, 0.04, 0.42), mat_q)
        tibia.rotation_euler = Euler((math.radians(18), angle_y, side * math.radians(8)), 'XYZ')
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        partes.append(tibia)

    # Fusionar malla
    bpy.ops.object.select_all(action='DESELECT')
    for p in partes:
        p.select_set(True)

    bpy.context.view_layer.objects.active = head
    bpy.ops.object.join()

    arana = bpy.context.active_object
    arana.name = "Arana_Barony_Voxel_Mesh"

    for poly in arana.data.polygons:
        poly.use_smooth = False

    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')

    return arana

# -----------------------------------------------------------------------------
# 4. RIGGING Y ANIMACIONES
# -----------------------------------------------------------------------------
def crear_rig_y_animaciones_barony(arana):
    print("[Armature] Creando esqueleto de control Voxel...")
    bpy.ops.object.select_all(action='DESELECT')

    arm_data = bpy.data.armatures.new("Arana_Barony_ArmatureData")
    arm_obj = bpy.data.objects.new("Arana_Barony_Armature", arm_data)
    bpy.context.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj

    bpy.ops.object.mode_set(mode='EDIT')

    bone_body = arm_data.edit_bones.new("Bone_Body")
    bone_body.head = Vector((0, 0, 0.32))
    bone_body.tail = Vector((0, 0.45, 0.50))

    bpy.ops.object.mode_set(mode='OBJECT')

    arana.select_set(True)
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.parent_set(type='ARMATURE_AUTO')

    arm_obj.animation_data_create()
    pbone = arm_obj.pose.bones.get("Bone_Body")

    # 1. IDLE
    action_idle = bpy.data.actions.new(name="Arana_Idle")
    arm_obj.animation_data.action = action_idle
    bpy.ops.object.mode_set(mode='POSE')

    keyframes_idle = [
        (1,  (0, 0, 0), (0, 0, 0)),
        (15, (0, 0, -0.04), (math.radians(2), 0, 0)),
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

    # 2. CAMINAR
    action_walk = bpy.data.actions.new(name="Arana_Caminar")
    arm_obj.animation_data.action = action_walk

    keyframes_walk = [
        (1,  (0, 0, 0), (0, 0, 0)),
        (5,  (0.04, 0.06, 0.03), (math.radians(-2), math.radians(4), math.radians(-3))),
        (10, (0, 0.12, 0), (0, 0, 0)),
        (15, (-0.04, 0.06, 0.03), (math.radians(2), math.radians(-4), math.radians(3))),
        (20, (0, 0, 0), (0, 0, 0))
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

    # 3. ATAQUE
    action_atk = bpy.data.actions.new(name="Arana_Ataque")
    arm_obj.animation_data.action = action_atk

    keyframes_atk = [
        (1,  (0, 0, 0), (0, 0, 0)),
        (4,  (0, -0.14, 0.10), (math.radians(-25), 0, 0)),
        (8,  (0, 0.32, 0.05),  (math.radians(32), 0, 0)),
        (14, (0, 0.18, -0.03), (math.radians(12), 0, 0)),
        (18, (0, 0, 0), (0, 0, 0))
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
    print("✓ Araña Barony Voxel proporcionada riggeada y animada con éxito!")
    return arm_obj

# -----------------------------------------------------------------------------
# 5. GENERACIÓN Y EXPORTACIÓN
# -----------------------------------------------------------------------------
def generar_y_exportar():
    print("[1/4] Limpiando escena...")
    limpiar_escena()

    print("[2/4] Creando materiales Voxel de Barony...")
    mat_q, mat_a, mat_o, mat_h, mat_v = crear_materiales_voxel()

    print("[3/4] Construyendo araña Voxel proporcionada...")
    arana = construir_arana_barony_proporcionada(mat_q, mat_a, mat_o, mat_h, mat_v)
    crear_rig_y_animaciones_barony(arana)

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

    print(f"\n✓ Araña Barony Voxel ajustada exportada exitosamente en:")
    print(f"  - GLB: {glb_path}")
    print(f"  - BLEND: {blend_path}")

if __name__ == "__main__":
    generar_y_exportar()
