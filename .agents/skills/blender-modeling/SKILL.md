---
name: blender-modeling
description: >-
  Automate 3D model creation, procedural geometry generation, PBR texturing, rigging,
  animation, and export (GLTF/GLB/BLEND/FBX) using Blender CLI and Python scripts (bpy).
  Use this skill when asked to create 3D assets, weapons, props, characters, or environment models in Blender.
---

# Blender 3D Automated Modeling & Pipeline Skill

This skill allows Antigravity agents to programmatically create high-quality 3D assets, weapons, props, characters, and environment blocks using Blender's Python API (`bpy`) and execute them headlessly via command line.

---

## Workflow Overview

1. **Locate Blender Executable**: Detect Blender on the host machine.
2. **Write Python Script (`bpy`)**: Generate mesh geometry, PBR materials, armatures/rigging, and animations.
3. **Execute Headlessly**: Run Blender in background mode (`-b -P <script.py>`).
4. **Export Assets**: Save `.glb` / `.gltf` and `.blend` files into the project's `assets/` directory.

---

## 1. Locating Blender Executable

Before running any script, determine the Blender executable path:

- **Windows**:
  - `C:\Program Files\Blender Foundation\Blender 5.2\blender.exe` (or version 4.x / 3.x)
  - PowerShell discovery command:
    ```powershell
    Get-Command blender -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path
    Get-ChildItem "C:\Program Files\Blender Foundation" -Recurse -Filter "blender.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
    ```
- **macOS**: `/Applications/Blender.app/Contents/MacOS/Blender`
- **Linux**: `blender` or `/usr/bin/blender`

---

## 2. Headless Execution Command

Run Blender in background mode without GUI:

```bash
# Windows PowerShell
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b -P script_name.py

# Linux / macOS
blender -b -P script_name.py
```

---

## 3. Python Scripting Template (`bpy`)

Every script should follow this robust template:

```python
import bpy
import math
import os
from mathutils import Vector, Euler

def limpiar_escena():
    """Limpia todos los objetos, mallas, materiales y esqueletos de la escena."""
    if bpy.context.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for block in [bpy.data.meshes, bpy.data.materials, bpy.data.armatures, bpy.data.actions]:
        for item in list(block):
            block.remove(item)

def crear_material_pbr(nombre, color_rgba, metallic=0.0, roughness=0.5):
    """Crea un material PBR compatible con Blender 4.x / 5.x."""
    mat = bpy.data.materials.new(name=nombre)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        if 'Base Color' in bsdf.inputs:
            bsdf.inputs['Base Color'].default_value = color_rgba
        if 'Metallic' in bsdf.inputs:
            bsdf.inputs['Metallic'].default_value = metallic
        if 'Roughness' in bsdf.inputs:
            bsdf.inputs['Roughness'].default_value = roughness
    return mat

def exportar_asset(nombre_asset):
    """Exporta el modelo activo a GLTF/GLB y guarda el archivo .blend."""
    output_dir = os.path.join(os.getcwd(), "assets")
    os.makedirs(output_dir, exist_ok=True)
    
    glb_path = os.path.join(output_dir, f"{nombre_asset}.glb")
    blend_path = os.path.join(output_dir, f"{nombre_asset}.blend")

    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format='GLB',
        use_selection=False,
        export_apply=True
    )
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print(f"✓ Exportado GLB: {glb_path}")
    print(f"✓ Guardado BLEND: {blend_path}")

if __name__ == "__main__":
    limpiar_escena()
    # [Insertar lógica de modelado]
    exportar_asset("mi_modelo")
```

---

## 4. Key Modeling Techniques in `bpy`

### A. Custom Procedural Mesh Generation
Use `from_pydata(vertices, edges, faces)` for custom weapons, blades, and complex polyhedrons:

```python
mesh = bpy.data.meshes.new("MiMesh")
obj = bpy.data.objects.new("MiObjeto", mesh)
bpy.context.collection.objects.link(obj)

verts = [(0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0)]
faces = [[0, 1, 2, 3]]

mesh.from_pydata(verts, [], faces)
mesh.update()
```

### B. Modifiers (Bevel, Subsurf, Solidify)
Enhance low-poly geometry into semi-realistic assets:

```python
# Bevel para bordes suaves y realistas
bevel = obj.modifiers.new(name="Bevel", type='BEVEL')
bevel.width = 0.01
bevel.segments = 3
```

### C. Smooth Shading & Origin Setup
```python
# Sombra suave
for poly in mesh.polygons:
    poly.use_smooth = True

# Establecer origen en la base/agarre
bpy.context.scene.cursor.location = (0, 0, -0.1)
bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
```

---

## 5. Checklist & Best Practices for Game Engines (Godot / Unity / Unreal / Web)

- [x] **Units**: Use default metric meters.
- [x] **Scale**: Always apply scale transform before export (`bpy.ops.object.transform_apply(scale=True)`).
- [x] **Orientation**: Models should face `-Z` or `+Y` depending on engine standard (Godot standard: Front facing `-Z` or `+Z`).
- [x] **Origin Point**: Set origin point at the pivot/handle base for easy weapon holding or placement.
- [x] **Material Nodes**: Ensure socket names use string fallbacks (`'Base Color'`, `'Metallic'`, `'Roughness'`) to support Blender API versions.
