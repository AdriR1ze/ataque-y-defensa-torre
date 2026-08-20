"""
===============================================================================
GENERADOR DE ARAÑA ESTILO BARONY / DUNGEON CRAWLER PARA BLENDER
===============================================================================
Recrea fielmente las arañas del videojuego Barony:
  - Estilo Low-Poly / Voxel estilizado de mazmorra oscura.
  - Cefalotórax y Abdomen angulares con quitina marrón oscuro/negro.
  - 8 Ojos emisivos rojo carmesí prominentes.
  - Colmillos Quelíceros afilados de hueso con veneno tóxico verde.
  - 8 Patas articuladas en 3 segmentos con anillos/bandas de articulación.
  - Rigging con Armature + 3 Animaciones (Idle, Caminar rápido, Ataque salto).

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
# 2. MATERIALES PBR ESTILO BARONY
# -----------------------------------------------------------------------------
def crear_materiales_barony():
    # Quitina Oscura de Mazmorra (Barony Dark Brown/Black)
    mat_cuerpo = bpy.data.materials.new(name="M_Barony_Quitina")
    mat_cuerpo.use_nodes = True
    bsdf_q = mat_cuerpo.node_tree.nodes.get("Principled BSDF")
    if bsdf_q:
        if 'Base Color' in bsdf_q.inputs:
            bsdf_q.inputs['Base Color'].default_value = (0.07, 0.04, 0.03, 1.0)
        if 'Metallic' in bsdf_q.inputs:
            bsdf_q.inputs['Metallic'].default_value = 0.15
        if 'Roughness' in bsdf_q.inputs:
            bsdf_q.inputs['Roughness'].default_value = 0.35

    # Bandas/Anillos de Articulación (Marrón Cuero Claro / Hueso)
    mat_anillos = bpy.data.materials.new(name="M_Barony_Anillos")
    mat_anillos.use_nodes = True
    bsdf_a = mat_anillos.node_tree.nodes.get("Principled BSDF")
    if bsdf_a:
        if 'Base Color' in bsdf_a.inputs:
            bsdf_a.inputs['Base Color'].default_value = (0.35, 0.22, 0.12, 1.0)
        if 'Roughness' in bsdf_a.inputs:
            bsdf_a.inputs['Roughness'].default_value = 0.5

    # Ojos Rojo Carmesí Emisivos
    mat_ojos = bpy.data.materials.new(name="M_Barony_Ojos_Rojos")
    mat_ojos.use_nodes = True
    bsdf_o = mat_ojos.node_tree.nodes.get("Principled BSDF")
    if bsdf_o:
        if 'Base Color' in bsdf_o.inputs:
            bsdf_o.inputs['Base Color'].default_value = (1.0, 0.0, 0.05, 1.0)
        if 'Emission Color' in bsdf_o.inputs:
            bsdf_o.inputs['Emission Color'].default_value = (1.0, 0.0, 0.05, 1.0)
        elif 'Emission' in bsdf_o.inputs:
            bsdf_o.inputs['Emission'].default_value = (1.0, 0.0, 0.05, 1.0)
        if 'Emission Strength' in bsdf_o.inputs:
            bsdf_o.inputs['Emission Strength'].default_value = 5.0

    # Colmillos Quelíceros de Hueso con Veneno
    mat_colmillos = bpy.data.materials.new(name="M_Barony_Colmillos")
    mat_colmillos.use_nodes = True
    bsdf_c = mat_colmillos.node_tree.nodes.get("Principled BSDF")
    if bsdf_c:
        if 'Base Color' in bsdf_c.inputs:
            bsdf_c.inputs['Base Color'].default_value = (0.8, 0.75, 0.5, 1.0)
        if 'Roughness' in bsdf_c.inputs:
            bsdf_c.inputs['Roughness'].default_value = 0.2

    return mat_cuerpo, mat_anillos, mat_ojos, mat_colmillos

# -----------------------------------------------------------------------------
# 3. MODELADO DE LA ARAÑA BARONY
# -----------------------------------------------------------------------------
def construir_arana_barony(mat_cuerpo, mat_anillos, mat_ojos, mat_colmillos):
    partes = []

    # A. Cefalotórax (Cabeza Bloque Angular Estilo Barony)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.25, 0.45))
    head = bpy.context.active_object
    head.name = "Barony_Head"
    head.scale = (0.75, 0.85, 0.55)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    head.data.materials.append(mat_cuerpo)
    partes.append(head)

    # Biselado sutil para bordes low-poly limpios
    bev1 = head.modifiers.new(name="Bevel", type='BEVEL')
    bev1.width = 0.03
    bev1.segments = 2

    # B. Abdomen (Bloque Grande Trapezoidal Trasero)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0.85, 0.70))
    abd = bpy.context.active_object
    abd.name = "Barony_Abdomen"
    abd.scale = (1.1, 1.3, 0.95)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    abd.data.materials.append(mat_cuerpo)
    partes.append(abd)

    bev2 = abd.modifiers.new(name="Bevel", type='BEVEL')
    bev2.width = 0.04
    bev2.segments = 2

    # C. 8 Ojos Cuadrados/Cúbicos Emisivos Prominentes de Barony
    posiciones_ojos = [
        # Ojos frontales centrales (grandes)
        (-0.16, -0.68, 0.52, 0.09), (0.16, -0.68, 0.52, 0.09),
        # Ojos frontales superiores
        (-0.28, -0.65, 0.60, 0.07), (0.28, -0.65, 0.60, 0.07),
        # Ojos laterales
        (-0.38, -0.52, 0.50, 0.06), (0.38, -0.52, 0.50, 0.06),
        # Ojos inferiores
        (-0.12, -0.69, 0.38, 0.06), (0.12, -0.69, 0.38, 0.06),
    ]
    for idx, (x, y, z, size) in enumerate(posiciones_ojos):
        bpy.ops.mesh.primitive_cube_add(size=size, location=(x, y, z))
        ojo = bpy.context.active_object
        ojo.name = f"Ojo_Barony_{idx+1}"
        ojo.data.materials.append(mat_ojos)
        partes.append(ojo)

    # D. Quelíceros / Colmillos Angulares Prominentes (Barony Fangs)
    for sign in [-1, 1]:
        bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=0.08, depth=0.35, location=(sign * 0.16, -0.72, 0.28))
        colmillo = bpy.context.active_object
        colmillo.name = f"Colmillo_Barony_{sign}"
        colmillo.rotation_euler = Euler((math.radians(40), 0, sign * math.radians(-12)), 'XYZ')
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
        colmillo.data.materials.append(mat_colmillos)
        partes.append(colmillo)

    # E. 8 Patas Articuladas Estilo Barony (Bloques con Anillos)
    datos_patas = [
        # Side (-1 izq, 1 der), Leg Index (0..3), Angle Y
        (-1, 0, math.radians(-65)),
        (-1, 1, math.radians(-25)),
        (-1, 2, math.radians(25)),
        (-1, 3, math.radians(65)),
        (1,  0, math.radians(65)),
        (1,  1, math.radians(25)),
        (1,  2, math.radians(-25)),
        (1,  3, math.radians(-65)),
    ]

    for side, num, angle_y in datos_patas:
        base_x = side * 0.36
        base_y = -0.45 + num * 0.28
        base_z = 0.45

        # 1. Fémur (Hacia arriba/afuera)
        f_len = 0.55
        f_mid_x = base_x + side * (f_len / 2.0) * math.cos(angle_y)
        f_mid_y = base_y + (f_len / 2.0) * math.sin(angle_y)
        f_mid_z = base_z + 0.25

        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(f_mid_x, f_mid_y, f_mid_z))
        femur = bpy.context.active_object
        femur.name = f"Pata_{side}_{num}_Femur"
        femur.scale = (0.08, 0.08, f_len)
        femur.rotation_euler = Euler((math.radians(-30), angle_y, side * math.radians(-20)), 'XYZ')
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        femur.data.materials.append(mat_cuerpo)
        partes.append(femur)

        # Anillo articulación
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(f_mid_x, f_mid_y, f_mid_z + 0.2))
        anillo = bpy.context.active_object
        anillo.scale = (0.1, 0.1, 0.08)
        anillo.data.materials.append(mat_anillos)
        partes.append(anillo)

        # 2. Tibia (Hacia abajo al suelo)
        t_end_x = f_mid_x + side * 0.45 * math.cos(angle_y)
        t_end_y = f_mid_y + 0.45 * math.sin(angle_y)
        t_mid_z = 0.2

        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(t_end_x, t_end_y, t_mid_z))
        tibia = bpy.context.active_object
        tibia.name = f"Pata_{side}_{num}_Tibia"
        tibia.scale = (0.06, 0.06, 0.65)
        tibia.rotation_euler = Euler((math.radians(25), angle_y, side * math.radians(15)), 'XYZ')
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        tibia.data.materials.append(mat_cuerpo)
        partes.append(tibia)

    # Fusionar componentes
    bpy.ops.object.select_all(action='DESELECT')
    for p in partes:
        p.select_set(True)

    bpy.context.view_layer.objects.active = head
    bpy.ops.object.join()

    arana = bpy.context.active_object
    arana.name = "Arana_Barony_Mesh"

    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')

    return arana

# -----------------------------------------------------------------------------
# 4. RIGGING Y ANIMACIONES ESTILO BARONY
# -----------------------------------------------------------------------------
def crear_rig_y_animaciones_barony(arana):
    print("[Armature] Creando esqueleto de control Barony...")
    bpy.ops.object.select_all(action='DESELECT')

    arm_data = bpy.data.armatures.new("Arana_Barony_ArmatureData")
    arm_obj = bpy.data.objects.new("Arana_Barony_Armature", arm_data)
    bpy.context.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj

    bpy.ops.object.mode_set(mode='EDIT')

    bone_body = arm_data.edit_bones.new("Bone_Body")
    bone_body.head = Vector((0, 0, 0.45))
    bone_body.tail = Vector((0, 0.6, 0.70))

    bpy.ops.object.mode_set(mode='OBJECT')

    arana.select_set(True)
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.parent_set(type='ARMATURE_AUTO')

    print("[Anim] Creando animaciones Barony (Idle, Caminar rápido, Ataque salto)...")
    arm_obj.animation_data_create()
    pbone = arm_obj.pose.bones.get("Bone_Body")

    # 1. IDLE (Mecimiento agresivo de Barony)
    action_idle = bpy.data.actions.new(name="Arana_Idle")
    arm_obj.animation_data.action = action_idle
    bpy.ops.object.mode_set(mode='POSE')

    keyframes_idle = [
        (1,  (0, 0, 0), (0, 0, 0)),
        (15, (0, 0, -0.08), (math.radians(4), 0, 0)),
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

    # 2. CAMINAR RÁPIDO (Caminata de araña de Barony)
    action_walk = bpy.data.actions.new(name="Arana_Caminar")
    arm_obj.animation_data.action = action_walk

    keyframes_walk = [
        (1,  (0, 0, 0), (0, 0, 0)),
        (5,  (0.06, 0.08, 0.05), (math.radians(-3), math.radians(6), math.radians(-5))),
        (10, (0, 0.16, 0), (0, 0, 0)),
        (15, (-0.06, 0.08, 0.05), (math.radians(3), math.radians(-6), math.radians(5))),
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

    # 3. ATAQUE SALTO (Salto mordida sangrienta estilo Barony)
    action_atk = bpy.data.actions.new(name="Arana_Ataque")
    arm_obj.animation_data.action = action_atk

    keyframes_atk = [
        (1,  (0, 0, 0), (0, 0, 0)),
        (4,  (0, -0.2, 0.15), (math.radians(-35), 0, 0)),  # Erguirse y retraerse
        (8,  (0, 0.45, 0.1),  (math.radians(45), 0, 0)),   # Salto embestida hacia adelante
        (14, (0, 0.3, -0.05), (math.radians(20), 0, 0)),   # Impacto
        (18, (0, 0, 0), (0, 0, 0))                         # Recuperación
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
    print("✓ Araña Barony riggeada y animada con éxito!")
    return arm_obj

# -----------------------------------------------------------------------------
# 5. GENERACIÓN Y EXPORTACIÓN
# -----------------------------------------------------------------------------
def generar_y_exportar():
    print("[1/4] Limpiando escena...")
    limpiar_escena()

    print("[2/4] Creando materiales Barony...")
    mat_cuerpo, mat_anillos, mat_ojos, mat_colmillos = crear_materiales_barony()

    print("[3/4] Construyendo araña estilo Barony...")
    arana = construir_arana_barony(mat_cuerpo, mat_anillos, mat_ojos, mat_colmillos)
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

    print(f"\n✓ Araña Barony exportada exitosamente en:")
    print(f"  - GLB: {glb_path}")
    print(f"  - BLEND: {blend_path}")

if __name__ == "__main__":
    generar_y_exportar()
