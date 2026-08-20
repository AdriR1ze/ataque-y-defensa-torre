---
name: run-debug
description: Cómo ejecutar y depurar el juego (Godot 4.7 tower defense). Usar cuando el usuario pida "correr/ejecutar/probar el juego", "debug", "verificar cambios", o "por qué no funciona". Incluye el binario de Godot, el modo debug y los autoloads.
---

# Ejecutar y depurar el juego

## Binario de Godot

Godot 4.7.1 no está en el PATH. El `.exe` de `Downloads` es la carpeta extraída; usar el console launcher
(o el ejecutable) dentro de ella:

- `C:\Users\Adriano\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe` (consola, para ver prints/errores)
- `C:\Users\Adriano\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe`

En PowerShell:

```powershell
& "C:\Users\Adriano\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --path "C:\Users\Adriano\Documents\GitHub\ataque-y-defensa-torre"
```

Para un chequeo rápido de scripts sin abrir ventana: añadir `--headless --quit-after 180`.

Para abrir solo el editor: añadir `-e`.

## Configuración del proyecto

- Godot 4.7, render Forward Plus, física Jolt Physics, driver de render d3d12 (ver `project.godot`).
- Escena principal: `res://src/ui/main_menu.tscn`.
- Al correr/abrir, Godot importa recursos y genera `.uid` y `*.import`. La carpeta `.godot/` está en `.gitignore`.

## Modo debug

- Dentro del juego, presionar la tecla `-` (menos, `KEY_MINUS`) para alternar debug. `Debug.debug_enabled` se setea.
- Con `Debug.debug_enabled`, el `WaveManager` corre una sola oleada y luego emite `level_completed`
  (ver `_run_wave_loop` en `wave_manager.gd`: `total_waves = 1 if debug_mode else max_waves`).
- El `WaveManager` tiene `debug_mode` propio; se sincroniza con `Debug.debug_enabled` en `_ready()`.
- También existe `res://src/ui/debug_text_overlay.gd/.tscn` para overlays de debug.

## Autoloads disponibles en runtime

`Debug`, `Economy`, `Settings`, `Music` (ver `[autoload]` en `project.godot`).

## Verificar cambios sin editor

1. Correr el juego con el binario de consola y leer los `print` y `push_error` en stdout.
2. Si aparecen errores de `uid` o recursos no encontrados, abrir una vez el editor
   (`-e`) para regenerar imports, o revisar que los `.tres`/`.tscn` referencien las rutas correctas.
3. Ante un `push_error("Could not load ...")`, revisar las rutas `res://` y los `preload`/`ResourceLoader.load`.
