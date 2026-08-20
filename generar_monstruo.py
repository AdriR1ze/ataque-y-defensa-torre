"""
GENERADOR DE MONSTRUO + ANIMACIONES + OBJETOS
Ejecutar desde Blender: Scripting > Abrir > Run Script (Alt+P)
Genera un monstruo naranja estilo Monsters Inc con ojos en el pecho,
sin cuello, 2 manos, 2 pies, riggeado y animado.
Incluye espada y arco como objetos separados.
"""

import bpy
import math
from mathutils import Vector, Euler


# ──────────────────────────────────────────────────────────────
# CONFIGURACION
# ──────────────────────────────────────────────────────────────
COLOR_NARANJA = (1.0, 0.45, 0.05, 1.0)       # RGBA
COLOR_OJO_BLANCO = (1.0, 1.0, 1.0, 1.0)
COLOR_OJO_PUPILA = (0.05, 0.05, 0.05, 1.0)
COLOR_BOCA = (0.15, 0.05, 0.02, 1.0)
COLOR_METAL = (0.6, 0.6, 0.65, 1.0)
COLOR_MADERA = (0.55, 0.35, 0.15, 1.0)

# ──────────────────────────────────────────────────────────────
# HELPERS
# ──────────────────────────────────────────────────────────────

def limpiar_escena():
    if bpy.context.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for block in list(bpy.data.meshes):
        bpy.data.meshes.remove(block)
    for block in list(bpy.data.materials):
        bpy.data.materials.remove(block)
    for block in list(bpy.data.armatures):
        bpy.data.armatures.remove(block)
    for block in list(bpy.data.actions):
        bpy.data.actions.remove(block)
    for block in list(bpy.data.collections):
        if block.name != "Collection":
            bpy.data.collections.remove(block)


def crear_material(name, color_rgba):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs['Base Color'].default_value = color_rgba
        bsdf.inputs['Roughness'].default_value = 0.7
    return mat


def asignar_material(obj, mat):
    if obj.data.materials:
        obj.data.materials[0] = mat
    else:
        obj.data.materials.append(mat)


def crear_esfera(name, radius=1.0, location=(0,0,0)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=location)
    obj = bpy.context.active_object
    obj.name = name
    return obj


def crear_cilindro(name, radius=0.5, depth=1.0, location=(0,0,0), rotation=(0,0,0)):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, location=location)
    obj = bpy.context.active_object
    obj.name = name
    if rotation != (0,0,0):
        obj.rotation_euler = Euler(rotation, 'XYZ')
    return obj


def crear_cubo(name, size=1.0, location=(0,0,0)):
    bpy.ops.mesh.primitive_cube_add(size=size, location=location)
    obj = bpy.context.active_object
    obj.name = name
    return obj


# ──────────────────────────────────────────────────────────────
# 1. MATERIALES
# ──────────────────────────────────────────────────────────────

def crear_materiales():
    mat_piel = crear_material("M_Piel", COLOR_NARANJA)
    mat_ojo = crear_material("M_Ojo", COLOR_OJO_BLANCO)
    mat_pupila = crear_material("M_Pupila", COLOR_OJO_PUPILA)
    mat_boca = crear_material("M_Boca", COLOR_BOCA)
    mat_metal = crear_material("M_Metal", COLOR_METAL)
    mat_madera = crear_material("M_Madera", COLOR_MADERA)
    return mat_piel, mat_ojo, mat_pupila, mat_boca, mat_metal, mat_madera

# ──────────────────────────────────────────────────────────────
# 2. MODELO DEL MONSTRUO
# ──────────────────────────────────────────────────────────────

def crear_monstruo(mats):
    mat_piel, mat_ojo, mat_pupila, mat_boca, _, _ = mats

    # --- CUERPO: esfera achatada, mas ancha que alta ---
    cuerpo = crear_esfera("Cuerpo", radius=1.0, location=(0, 0, 1.1))
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    cuerpo.scale = (1.0, 0.65, 0.95)

    # --- CABEZA (fusionada al cuerpo, sin cuello) ---
    cabeza = crear_esfera("Cabeza", radius=0.55, location=(0, 0, 1.85))
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    cabeza.scale = (0.9, 0.65, 0.75)

    # --- OJOS EN EL PECHO (frente del cuerpo) ---
    ojo_izq = crear_esfera("Ojo_Izq", radius=0.18, location=(-0.18, 0.55, 1.25))
    ojo_der = crear_esfera("Ojo_Der", radius=0.18, location=(0.18, 0.55, 1.25))
    pupila_izq = crear_esfera("Pupila_Izq", radius=0.08, location=(-0.18, 0.73, 1.25))
    pupila_der = crear_esfera("Pupila_Der", radius=0.08, location=(0.18, 0.73, 1.25))

    # --- BOCA (debajo de los ojos, en el pecho) ---
    boca = crear_cubo("Boca", size=0.3, location=(0, 0.58, 0.95))
    boca.scale = (0.8, 0.15, 0.1)

    # --- BRAZO IZQUIERDO ---
    brazo_izq_sup = crear_cilindro("Brazo_Izq_Sup", radius=0.22, depth=0.65,
                                   location=(-0.7, 0.0, 1.45), rotation=(0, 0, math.radians(-30)))
    brazo_izq_inf = crear_cilindro("Brazo_Izq_Inf", radius=0.18, depth=0.55,
                                   location=(-1.05, 0.05, 1.05), rotation=(0, 0, math.radians(-15)))
    mano_izq = crear_esfera("Mano_Izq", radius=0.2, location=(-1.25, 0.1, 0.78))

    # --- BRAZO DERECHO ---
    brazo_der_sup = crear_cilindro("Brazo_Der_Sup", radius=0.22, depth=0.65,
                                   location=(0.7, 0.0, 1.45), rotation=(0, 0, math.radians(30)))
    brazo_der_inf = crear_cilindro("Brazo_Der_Inf", radius=0.18, depth=0.55,
                                   location=(1.05, 0.05, 1.05), rotation=(0, 0, math.radians(15)))
    mano_der = crear_esfera("Mano_Der", radius=0.2, location=(1.25, 0.1, 0.78))

    # --- PIERNA IZQUIERDA ---
    pierna_izq_sup = crear_cilindro("Pierna_Izq_Sup", radius=0.2, depth=0.5,
                                    location=(-0.3, -0.1, 0.35), rotation=(0, 0, 0))
    pierna_izq_inf = crear_cilindro("Pierna_Izq_Inf", radius=0.17, depth=0.45,
                                    location=(-0.3, -0.1, -0.05), rotation=(0, 0, 0))
    pie_izq = crear_cubo("Pie_Izq", size=0.35, location=(-0.3, 0.05, -0.3))
    pie_izq.scale = (0.6, 0.3, 0.2)

    # --- PIERNA DERECHA ---
    pierna_der_sup = crear_cilindro("Pierna_Der_Sup", radius=0.2, depth=0.5,
                                    location=(0.3, -0.1, 0.35), rotation=(0, 0, 0))
    pierna_der_inf = crear_cilindro("Pierna_Der_Inf", radius=0.17, depth=0.45,
                                    location=(0.3, -0.1, -0.05), rotation=(0, 0, 0))
    pie_der = crear_cubo("Pie_Der", size=0.35, location=(0.3, 0.05, -0.3))
    pie_der.scale = (0.6, 0.3, 0.2)

    # --- DEDOS DE LAS MANOS (3 por mano) ---
    crear_dedos("Izq", -1)
    crear_dedos("Der", 1)

    return locals()


def crear_dedos(lado, signo):
    mx = -1.35 if lado == "Izq" else 1.35
    base = (mx, 0.1, 0.68)
    offsets = [(-0.06, 0.08, 0.06), (0, 0.1, 0.03), (0.06, 0.08, 0.06)]
    for i, off in enumerate(offsets):
        crear_cilindro(f"Dedo_{lado}_{i+1}", radius=0.04, depth=0.15,
                       location=(base[0] + off[0], base[1] + off[1], base[2] + off[2]),
                       rotation=(math.radians(-10), 0, 0))

# ──────────────────────────────────────────────────────────────
# 3. UNIR MESH EN UN SOLO OBJETO
# ──────────────────────────────────────────────────────────────

def unir_monstruo(monstruo_parts, mats):
    mat_piel, mat_ojo, mat_pupila, mat_boca, _, _ = mats

    # Deseleccionar todo
    bpy.ops.object.select_all(action='DESELECT')

    partes_piel = ["Cuerpo", "Cabeza"]
    partes_brazos = ["Brazo_Izq_Sup", "Brazo_Izq_Inf", "Brazo_Der_Sup", "Brazo_Der_Inf"]
    partes_manos = ["Mano_Izq", "Mano_Der"]
    partes_piernas = ["Pierna_Izq_Sup", "Pierna_Izq_Inf", "Pierna_Der_Sup", "Pierna_Der_Inf"]
    partes_pies = ["Pie_Izq", "Pie_Der"]

    dedos = []
    for lado in ["Izq", "Der"]:
        for i in range(1, 4):
            dedos.append(f"Dedo_{lado}_{i}")

    # Seleccionar todas las partes del cuerpo principal (menos ojos)
    partes_cuerpo = (partes_piel + partes_brazos + partes_manos +
                     partes_piernas + partes_pies + dedos + ["Boca"])
    objetos_encontrados = []
    for name in partes_cuerpo:
        obj = bpy.data.objects.get(name)
        if obj:
            obj.select_set(True)
            objetos_encontrados.append(obj)

    if objetos_encontrados:
        bpy.context.view_layer.objects.active = objetos_encontrados[0]
        bpy.ops.object.join()
        cuerpo_unido = bpy.context.active_object
        cuerpo_unido.name = "Monstruo_Cuerpo"
        asignar_material(cuerpo_unido, mat_piel)

    # Unir ojos
    bpy.ops.object.select_all(action='DESELECT')
    obj_ojo_izq = bpy.data.objects.get("Ojo_Izq")
    obj_ojo_der = bpy.data.objects.get("Ojo_Der")
    if obj_ojo_izq and obj_ojo_der:
        obj_ojo_izq.select_set(True)
        obj_ojo_der.select_set(True)
        bpy.context.view_layer.objects.active = obj_ojo_izq
        bpy.ops.object.join()
        ojos = bpy.context.active_object
        ojos.name = "Monstruo_Ojos"
        asignar_material(ojos, mat_ojo)

    return bpy.data.objects.get("Monstruo_Cuerpo"), bpy.data.objects.get("Monstruo_Ojos")


def unir_pupilas():
    bpy.ops.object.select_all(action='DESELECT')
    p_izq = bpy.data.objects.get("Pupila_Izq")
    p_der = bpy.data.objects.get("Pupila_Der")
    if p_izq and p_der:
        p_izq.select_set(True)
        p_der.select_set(True)
        bpy.context.view_layer.objects.active = p_izq
        bpy.ops.object.join()
        pupilas = bpy.context.active_object
        pupilas.name = "Monstruo_Pupilas"
        return pupilas
    return None

# ──────────────────────────────────────────────────────────────
# 4. ARMATURE / ESQUELETO
# ──────────────────────────────────────────────────────────────

def crear_armature():
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    armature = bpy.context.active_object
    armature.name = "Armature_Monstruo"

    # Eliminar el bone default
    for bone in armature.data.edit_bones:
        armature.data.edit_bones.remove(bone)

    ebones = armature.data.edit_bones

    # --- ROOT ---
    root = ebones.new("Root")
    root.head = Vector((0, 0, 0))
    root.tail = Vector((0, 0, 0.2))

    # --- SPINE / CADERA ---
    spine = ebones.new("Spine")
    spine.head = Vector((0, 0, 0.2))
    spine.tail = Vector((0, 0, 1.3))
    spine.parent = root

    # --- CABEZA (fusionada) ---
    cabeza = ebones.new("Cabeza")
    cabeza.head = Vector((0, 0, 1.3))
    cabeza.tail = Vector((0, 0, 1.8))
    cabeza.parent = spine

    # --- BRAZO IZQUIERDO ---
    upper_arm_l = ebones.new("UpperArm_L")
    upper_arm_l.head = Vector((0, 0, 1.35))
    upper_arm_l.tail = Vector((-0.7, 0, 1.35))
    upper_arm_l.parent = spine

    lower_arm_l = ebones.new("LowerArm_L")
    lower_arm_l.head = Vector((-0.7, 0, 1.35))
    lower_arm_l.tail = Vector((-1.1, 0.1, 0.9))
    lower_arm_l.parent = upper_arm_l

    hand_l = ebones.new("Hand_L")
    hand_l.head = Vector((-1.1, 0.1, 0.9))
    hand_l.tail = Vector((-1.25, 0.1, 0.75))
    hand_l.parent = lower_arm_l

    # --- BRAZO DERECHO ---
    upper_arm_r = ebones.new("UpperArm_R")
    upper_arm_r.head = Vector((0, 0, 1.35))
    upper_arm_r.tail = Vector((0.7, 0, 1.35))
    upper_arm_r.parent = spine

    lower_arm_r = ebones.new("LowerArm_R")
    lower_arm_r.head = Vector((0.7, 0, 1.35))
    lower_arm_r.tail = Vector((1.1, 0.1, 0.9))
    lower_arm_r.parent = upper_arm_r

    hand_r = ebones.new("Hand_R")
    hand_r.head = Vector((1.1, 0.1, 0.9))
    hand_r.tail = Vector((1.25, 0.1, 0.75))
    hand_r.parent = lower_arm_r

    # --- PIERNA IZQUIERDA ---
    upper_leg_l = ebones.new("UpperLeg_L")
    upper_leg_l.head = Vector((-0.3, -0.05, 0.2))
    upper_leg_l.tail = Vector((-0.3, -0.1, -0.3))
    upper_leg_l.parent = root

    lower_leg_l = ebones.new("LowerLeg_L")
    lower_leg_l.head = Vector((-0.3, -0.1, -0.3))
    lower_leg_l.tail = Vector((-0.3, -0.1, -0.65))
    lower_leg_l.parent = upper_leg_l

    foot_l = ebones.new("Foot_L")
    foot_l.head = Vector((-0.3, -0.1, -0.65))
    foot_l.tail = Vector((-0.3, 0.1, -0.8))
    foot_l.parent = lower_leg_l

    # --- PIERNA DERECHA ---
    upper_leg_r = ebones.new("UpperLeg_R")
    upper_leg_r.head = Vector((0.3, -0.05, 0.2))
    upper_leg_r.tail = Vector((0.3, -0.1, -0.3))
    upper_leg_r.parent = root

    lower_leg_r = ebones.new("LowerLeg_R")
    lower_leg_r.head = Vector((0.3, -0.1, -0.3))
    lower_leg_r.tail = Vector((0.3, -0.1, -0.65))
    lower_leg_r.parent = upper_leg_r

    foot_r = ebones.new("Foot_R")
    foot_r.head = Vector((0.3, -0.1, -0.65))
    foot_r.tail = Vector((0.3, 0.1, -0.8))
    foot_r.parent = lower_leg_r

    bpy.ops.object.mode_set(mode='OBJECT')
    return armature

# ──────────────────────────────────────────────────────────────
# 5. SKINNING (parent con pesos automaticos)
# ──────────────────────────────────────────────────────────────

def hacer_skinning(armature, cuerpo, ojos, pupilas):
    bpy.ops.object.select_all(action='DESELECT')

    if cuerpo:
        cuerpo.select_set(True)
        armature.select_set(True)
        bpy.context.view_layer.objects.active = armature
        bpy.ops.object.parent_set(type='ARMATURE_AUTO')

    if ojos:
        bpy.ops.object.select_all(action='DESELECT')
        ojos.select_set(True)
        armature.select_set(True)
        bpy.context.view_layer.objects.active = armature
        bpy.ops.object.parent_set(type='ARMATURE_AUTO')

    if pupilas:
        bpy.ops.object.select_all(action='DESELECT')
        pupilas.select_set(True)
        armature.select_set(True)
        bpy.context.view_layer.objects.active = armature
        bpy.ops.object.parent_set(type='ARMATURE_AUTO')

# ──────────────────────────────────────────────────────────────
# 6. CREAR ESPADA
# ──────────────────────────────────────────────────────────────

def crear_espada(mat_metal, mat_cuero=None, mat_laton=None):
    bpy.ops.object.select_all(action='DESELECT')

    if mat_cuero is None:
        mat_cuero = crear_material("M_Cuero", (0.16, 0.10, 0.06, 1.0))
    if mat_laton is None:
        mat_laton = crear_material("M_Laton", (0.85, 0.68, 0.32, 1.0))

    # 1. HOJA (Double-edged tapered medieval blade with fuller groove)
    mesh_hoja = bpy.data.meshes.new("Espada_Hoja_Mesh")
    hoja = bpy.data.objects.new("Espada_Hoja", mesh_hoja)
    bpy.context.collection.objects.link(hoja)

    # Geometry vertices
    z_base = 0.0
    z_mid = 1.2
    z_tip = 1.6

    verts = [
        # Base section (z=0)
        (-0.06, 0, z_base), (-0.02, 0.012, z_base), (0, 0.007, z_base), (0.02, 0.012, z_base),
        (0.06, 0, z_base), (0.02, -0.012, z_base), (0, -0.007, z_base), (-0.02, -0.012, z_base),
        # Mid section (z=1.2)
        (-0.04, 0, z_mid), (-0.012, 0.008, z_mid), (0, 0.005, z_mid), (0.012, 0.008, z_mid),
        (0.04, 0, z_mid), (0.012, -0.008, z_mid), (0, -0.005, z_mid), (-0.012, -0.008, z_mid),
        # Tip point (z=1.6)
        (0, 0, z_tip)
    ]

    faces = []
    # Side quads
    for i in range(8):
        nxt = (i + 1) % 8
        faces.append([i, nxt, nxt + 8, i + 8])
    # Tip fan
    for i in range(8):
        nxt = (i + 1) % 8
        faces.append([i + 8, nxt + 8, 16])

    mesh_hoja.from_pydata(verts, [], faces)
    mesh_hoja.update()
    asignar_material(hoja, mat_metal)

    # 2. GUARDA (Curved cruciform quillons)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, -0.04))
    guarda = bpy.context.active_object
    guarda.name = "Espada_Guarda"
    guarda.scale = (0.45, 0.08, 0.07)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    asignar_material(guarda, mat_metal)

    # 3. EMPUÑADURA (Contoured leather grip)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=0.35, location=(0, 0, -0.25))
    empunadura = bpy.context.active_object
    empunadura.name = "Espada_Empunadura"
    empunadura.scale = (0.75, 1.1, 1.0)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    asignar_material(empunadura, mat_cuero)

    # 4. POMMEL (Wheel pommel disc + brass medallion)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=0.06, location=(0, 0, -0.48))
    pommel = bpy.context.active_object
    pommel.name = "Espada_Pommel"
    pommel.rotation_euler = Euler((math.radians(90), 0, 0), 'XYZ')
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    asignar_material(pommel, mat_laton)

    # Unir espada
    bpy.ops.object.select_all(action='DESELECT')
    for name in ["Espada_Hoja", "Espada_Guarda", "Espada_Empunadura", "Espada_Pommel"]:
        obj = bpy.data.objects.get(name)
        if obj:
            obj.select_set(True)
    bpy.context.view_layer.objects.active = hoja
    bpy.ops.object.join()
    espada = bpy.context.active_object
    espada.name = "Espada"

    # Rotar para que apunte hacia adelante (eje X)
    espada.rotation_euler = Euler((0, math.radians(90), 0), 'XYZ')
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)

    espada.location = (2.5, 0, 1.5)
    return espada


def crear_arco(mat_madera, mat_metal):
    bpy.ops.object.select_all(action='DESELECT')

    # Cuerpo del arco (curva)
    bpy.ops.curve.primitive_bezier_curve_add(location=(4, 0, 1.5))
    curva = bpy.context.active_object
    curva.name = "Arco_Cuerpo"
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.curve.select_all(action='SELECT')
    bpy.ops.curve.delete(type='VERT')

    spline = curva.data.splines.new('BEZIER')
    spline.bezier_points.add(4)

    # Puntos de la forma del arco
    puntos = [
        Vector((0, 0, -1.0)),
        Vector((0.15, 0, -0.6)),
        Vector((0.0, 0, 0.0)),
        Vector((-0.15, 0, 0.4)),
        Vector((0, 0, 1.0)),
    ]

    for i, bp in enumerate(spline.bezier_points):
        bp.co = puntos[i]
        bp.handle_left_type = 'AUTO'
        bp.handle_right_type = 'AUTO'

    bpy.ops.object.mode_set(mode='OBJECT')

    # Darle grosor
    curva.data.bevel_depth = 0.03
    curva.data.bevel_resolution = 4

    # Convertir a mesh
    bpy.ops.object.select_all(action='DESELECT')
    curva.select_set(True)
    bpy.context.view_layer.objects.active = curva
    bpy.ops.object.convert(target='MESH')
    arco = bpy.context.active_object
    arco.name = "Arco"

    # Material
    asignar_material(arco, mat_madera)

    # Cuerda
    bpy.ops.mesh.primitive_cylinder_add(radius=0.012, depth=2.0, location=(4, 0, 1.5))
    cuerda = bpy.context.active_object
    cuerda.name = "Arco_Cuerda"
    cuerda.rotation_euler = Euler((math.radians(90), 0, 0), 'XYZ')
    asignar_material(cuerda, mat_metal)

    return arco

# ──────────────────────────────────────────────────────────────
# 7. ANIMACIONES
# ──────────────────────────────────────────────────────────────

def crear_accion(nombre, armature, frames_inicio, frames_fin):
    if armature.animation_data is None:
        armature.animation_data_create()
    accion = bpy.data.actions.new(name=nombre)
    armature.animation_data.action = accion
    return accion


def animar_caminar(armature):
    accion = crear_accion("Caminar", armature, 1, 24)
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 24
    bpy.context.scene.render.fps = 24

    duracion_ciclo = 24  # frames por ciclo completo

    pose_bones = armature.pose.bones

    # Huesos de piernas
    ul_l = pose_bones.get("UpperLeg_L")
    ul_r = pose_bones.get("UpperLeg_R")
    ll_l = pose_bones.get("LowerLeg_L")
    ll_r = pose_bones.get("LowerLeg_R")
    ua_l = pose_bones.get("UpperArm_L")
    ua_r = pose_bones.get("UpperArm_R")
    la_l = pose_bones.get("LowerArm_L")
    la_r = pose_bones.get("LowerArm_R")

    for frame in range(0, duracion_ciclo + 1):
        t = frame / duracion_ciclo

        # PIERNAS: movimiento pendular alternado
        angulo_pierna_izq = math.sin(t * math.pi * 2) * 0.5
        angulo_pierna_der = math.sin(t * math.pi * 2 + math.pi) * 0.5

        if ul_l:
            ul_l.rotation_euler = Euler((angulo_pierna_izq, 0, 0), 'XYZ')
            ul_l.keyframe_insert(data_path="rotation_euler", frame=frame + 1)
        if ul_r:
            ul_r.rotation_euler = Euler((angulo_pierna_der, 0, 0), 'XYZ')
            ul_r.keyframe_insert(data_path="rotation_euler", frame=frame + 1)

        # Rodillas
        if ll_l:
            ll_l.rotation_euler = Euler((max(0, -angulo_pierna_izq) * 0.3, 0, 0), 'XYZ')
            ll_l.keyframe_insert(data_path="rotation_euler", frame=frame + 1)
        if ll_r:
            ll_r.rotation_euler = Euler((max(0, -angulo_pierna_der) * 0.3, 0, 0), 'XYZ')
            ll_r.keyframe_insert(data_path="rotation_euler", frame=frame + 1)

        # BRAZOS: balanceo opuesto a las piernas
        if ua_l:
            ua_l.rotation_euler = Euler((-angulo_pierna_izq * 0.4, 0, 0), 'XYZ')
            ua_l.keyframe_insert(data_path="rotation_euler", frame=frame + 1)
        if ua_r:
            ua_r.rotation_euler = Euler((-angulo_pierna_der * 0.4, 0, 0), 'XYZ')
            ua_r.keyframe_insert(data_path="rotation_euler", frame=frame + 1)

    # BODY BOB
    root = pose_bones.get("Root")
    if root:
        for frame in range(0, duracion_ciclo + 1):
            t = frame / duracion_ciclo
            bob = math.sin(t * math.pi * 4) * 0.06
            root.location = Vector((0, 0, bob))
            root.keyframe_insert(data_path="location", frame=frame + 1)

    return accion


def animar_pegar_espada(armature):
    accion = crear_accion("PegarEspada", armature, 1, 20)
    pose_bones = armature.pose.bones

    ua_r = pose_bones.get("UpperArm_R")
    la_r = pose_bones.get("LowerArm_R")
    ua_l = pose_bones.get("UpperArm_L")
    la_l = pose_bones.get("LowerArm_L")

    frames_swing = 6

    # --- IDLE inicial ---
    if ua_r:
        ua_r.rotation_euler = Euler((0, 0, 0), 'XYZ')
        ua_r.keyframe_insert(data_path="rotation_euler", frame=1)

    # --- PREPARACION (levantar espada hacia atras) ---
    if ua_r:
        ua_r.rotation_euler = Euler((math.radians(-80), 0, math.radians(20)), 'XYZ')
        ua_r.keyframe_insert(data_path="rotation_euler", frame=frames_swing)

    if la_r:
        la_r.rotation_euler = Euler((math.radians(-30), 0, 0), 'XYZ')
        la_r.keyframe_insert(data_path="rotation_euler", frame=frames_swing)

    # --- GOLPE (bajar espada hacia adelante) ---
    if ua_r:
        ua_r.rotation_euler = Euler((math.radians(60), 0, math.radians(-30)), 'XYZ')
        ua_r.keyframe_insert(data_path="rotation_euler", frame=frames_swing + 3)

    if la_r:
        la_r.rotation_euler = Euler((math.radians(10), 0, 0), 'XYZ')
        la_r.keyframe_insert(data_path="rotation_euler", frame=frames_swing + 3)

    # --- RECUPERACION ---
    if ua_r:
        ua_r.rotation_euler = Euler((0, 0, 0), 'XYZ')
        ua_r.keyframe_insert(data_path="rotation_euler", frame=20)

    if la_r:
        la_r.rotation_euler = Euler((0, 0, 0), 'XYZ')
        la_r.keyframe_insert(data_path="rotation_euler", frame=20)

    # Brazo izquierdo acompañando
    if ua_l:
        ua_l.rotation_euler = Euler((0, 0, 0), 'XYZ')
        ua_l.keyframe_insert(data_path="rotation_euler", frame=1)
        ua_l.rotation_euler = Euler((math.radians(-30), 0, math.radians(-20)), 'XYZ')
        ua_l.keyframe_insert(data_path="rotation_euler", frame=frames_swing)
        ua_l.rotation_euler = Euler((math.radians(20), 0, math.radians(-50)), 'XYZ')
        ua_l.keyframe_insert(data_path="rotation_euler", frame=frames_swing + 3)
        ua_l.rotation_euler = Euler((0, 0, 0), 'XYZ')
        ua_l.keyframe_insert(data_path="rotation_euler", frame=20)

    return accion


def animar_disparar_arco(armature):
    accion = crear_accion("DispararArco", armature, 1, 30)
    pose_bones = armature.pose.bones

    ua_l = pose_bones.get("UpperArm_L")
    la_l = pose_bones.get("LowerArm_L")
    ua_r = pose_bones.get("UpperArm_R")
    la_r = pose_bones.get("LowerArm_R")

    # --- IDLE / POSICION INICIAL ---
    # Brazo izquierdo extendido al frente (sostiene arco)
    if ua_l:
        ua_l.rotation_euler = Euler((0, 0, 0), 'XYZ')
        ua_l.keyframe_insert(data_path="rotation_euler", frame=1)
    if la_l:
        la_l.rotation_euler = Euler((0, 0, 0), 'XYZ')
        la_l.keyframe_insert(data_path="rotation_euler", frame=1)

    # --- PREPARAR: alzar brazos ---
    if ua_l:
        ua_l.rotation_euler = Euler((math.radians(-70), 0, math.radians(-30)), 'XYZ')
        ua_l.keyframe_insert(data_path="rotation_euler", frame=5)
    if la_l:
        la_l.rotation_euler = Euler((0, 0, 0), 'XYZ')
        la_l.keyframe_insert(data_path="rotation_euler", frame=5)

    if ua_r:
        ua_r.rotation_euler = Euler((math.radians(-70), 0, math.radians(30)), 'XYZ')
        ua_r.keyframe_insert(data_path="rotation_euler", frame=5)
    if la_r:
        la_r.rotation_euler = Euler((math.radians(-80), 0, 0), 'XYZ')
        la_r.keyframe_insert(data_path="rotation_euler", frame=5)

    # --- TENSAR: brazo derecho tira hacia atras ---
    if ua_r:
        ua_r.rotation_euler = Euler((math.radians(-90), 0, math.radians(60)), 'XYZ')
        ua_r.keyframe_insert(data_path="rotation_euler", frame=18)
    if la_r:
        la_r.rotation_euler = Euler((math.radians(-90), 0, 0), 'XYZ')
        la_r.keyframe_insert(data_path="rotation_euler", frame=18)

    # --- SOLTAR: brazo vuelve ---
    if ua_r:
        ua_r.rotation_euler = Euler((math.radians(-70), 0, math.radians(30)), 'XYZ')
        ua_r.keyframe_insert(data_path="rotation_euler", frame=21)
    if la_r:
        la_r.rotation_euler = Euler((math.radians(-40), 0, 0), 'XYZ')
        la_r.keyframe_insert(data_path="rotation_euler", frame=21)

    # --- RECUPERACION ---
    if ua_l:
        ua_l.rotation_euler = Euler((0, 0, 0), 'XYZ')
        ua_l.keyframe_insert(data_path="rotation_euler", frame=30)
    if la_l:
        la_l.rotation_euler = Euler((0, 0, 0), 'XYZ')
        la_l.keyframe_insert(data_path="rotation_euler", frame=30)

    if ua_r:
        ua_r.rotation_euler = Euler((0, 0, 0), 'XYZ')
        ua_r.keyframe_insert(data_path="rotation_euler", frame=30)
    if la_r:
        la_r.rotation_euler = Euler((0, 0, 0), 'XYZ')
        la_r.keyframe_insert(data_path="rotation_euler", frame=30)

    return accion

# ──────────────────────────────────────────────────────────────
# 8. COLECCIONES
# ──────────────────────────────────────────────────────────────

def organizar_colecciones():
    colecciones = {
        "Monstruo": ["Monstruo_Cuerpo", "Monstruo_Ojos", "Monstruo_Pupilas", "Armature_Monstruo"],
        "Objetos": ["Espada", "Arco", "Arco_Cuerda"],
    }

    for coleccion_nombre, objetos_nombres in colecciones.items():
        col = bpy.data.collections.new(coleccion_nombre)
        bpy.context.scene.collection.children.link(col)
        for name in objetos_nombres:
            obj = bpy.data.objects.get(name)
            if obj:
                # Remover de colecciones previas
                for c in obj.users_collection:
                    c.objects.unlink(obj)
                col.objects.link(obj)

# ──────────────────────────────────────────────────────────────
# 9. PROGRAMA PRINCIPAL
# ──────────────────────────────────────────────────────────────

def main():
    print("=" * 50)
    print("GENERADOR DE MONSTRUO + ANIMACIONES + OBJETOS")
    print("=" * 50)

    # Limpiar escena
    print("\n[1/7] Limpiando escena...")
    limpiar_escena()

    # Materiales
    print("[2/7] Creando materiales...")
    mats = crear_materiales()
    mat_piel, _, _, _, mat_metal, mat_madera = mats

    # Modelo
    print("[3/7] Creando modelo del monstruo...")
    monstruo_parts = crear_monstruo(mats)
    cuerpo, ojos = unir_monstruo(monstruo_parts, mats)
    pupilas = unir_pupilas()

    # Asignar material a pupilas
    if pupilas:
        asignar_material(pupilas, mats[2])

    # Armature
    print("[4/7] Creando esqueleto (rig)...")
    armature = crear_armature()

    # Skinning
    print("[5/7] Haciendo skinning automatico...")
    hacer_skinning(armature, cuerpo, ojos, pupilas)

    # Objetos: espada y arco
    print("[6/7] Creando espada y arco...")
    crear_espada(mat_metal)
    crear_arco(mat_madera, mat_metal)

    # Animaciones
    print("[7/7] Creando animaciones...")
    bpy.context.scene.frame_set(1)

    # Poner el armature en modo pose
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.mode_set(mode='POSE')

    animar_caminar(armature)
    animar_pegar_espada(armature)
    animar_disparar_arco(armature)

    bpy.ops.object.mode_set(mode='OBJECT')

    # Organizar colecciones
    organizar_colecciones()

    # Frame final
    bpy.context.scene.frame_set(1)
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 30

    print("\n" + "=" * 50)
    print("GENERACION COMPLETA!")
    print("=" * 50)
    print("ACCIONES CREADAS:")
    print("  - Caminar (24 frames, loop)")
    print("  - PegarEspada (20 frames)")
    print("  - DispararArco (30 frames)")
    print("OBJETOS CREADOS:")
    print("  - Espada")
    print("  - Arco + Arco_Cuerda")
    print("=" * 50)
    print("Usa el Dope Sheet / Action Editor para cambiar entre animaciones.")
    print("Usa la NLA Editor para combinar animaciones.")
    print("=" * 50)


if __name__ == "__main__":
    main()
