# Godot Popup release diagnostic (#801)

## Estado

El error:

```text
ERROR: Attempt to disconnect a nonexistent connection ... Signal: 'focus_entered'
ERROR: Attempt to disconnect a nonexistent connection ... Signal: 'tree_exited'
```

no nace de un `disconnect()` del juego. El patrón coincide con Godot
`Popup::_deinitialize_visible_parents()` y con los informes upstream
[godotengine/godot#87626](https://github.com/godotengine/godot/issues/87626) y
[godotengine/godot#89657](https://github.com/godotengine/godot/issues/89657).

A 23 de septiembre de 2026:

- el proyecto sigue en la línea `4.7-stable`;
- upstream confirmó reproducción todavía en `4.7.2-stable` con templates release Linux;
- el MRP de tooltip dejó de reproducirse en `4.8-dev4` sobre X11/XWayland;
- #89657 quedó cerrado upstream el 28 de agosto de 2026, pero no hay un
  backport identificado a la línea 4.7 que podamos asumir en los templates
  oficiales usados por este repositorio;
- el hilo upstream apunta además a una interacción con el toolchain de los
  build containers oficiales. Por eso una compilación local del motor puede
  no reproducir el mismo fallo aun partiendo del mismo commit.

El diagnóstico upstream considera el spam inocuo para la funcionalidad del
popup. Eso no lo convierte en un error del juego que debamos silenciar de
forma global.

## Qué hace el parche versionado

`patches/godot_popup_fix.patch` es una **mitigación para un motor custom**:
protege las conexiones y desconexiones de `focus_entered` y `tree_exited`
con `is_connected()`.

El parche está escrito contra `scene/gui/popup.cpp` de la línea Godot 4.7.
Antes de compilar un motor propio:

```bash
git -C /ruta/al/godot checkout 4.7-stable
git -C /ruta/al/godot apply --check /ruta/a/expediente-legado/patches/godot_popup_fix.patch
git -C /ruta/al/godot apply /ruta/a/expediente-legado/patches/godot_popup_fix.patch
```

Después hay que compilar y usar tanto editor/template como corresponda según
la documentación oficial de Godot. Este repositorio **no compila ni selecciona
automáticamente** ese motor custom.

Por tanto, tener el fichero en `patches/` no significa que una alpha exportada
con los templates oficiales 4.7 esté corregida.

## Decisión para builds del proyecto

1. Mantener release builds; exportar debug no es una solución de distribución.
2. No añadir una allowlist general para `ERROR:`: ocultaría errores reales.
3. En 4.7, tratar estas dos líneas concretas como deuda conocida de motor solo
   cuando el playtest reproduzca exactamente este patrón.
4. Cuando el proyecto evalúe Godot 4.8 estable, repetir el playtest release en
   Linux con tooltips/popups. Si no reaparece, retirar la mitigación custom.
5. Si se necesita una release 4.7 sin ese spam antes de migrar, usar un template
   custom construido con el parche y registrar explícitamente el SHA del motor.

## Reproducción mínima

El caso más pequeño upstream es un `Button` con tooltip u `OptionButton` en
una exportación release Linux. Abrir/cerrar el popup o mostrar/ocultar el
tooltip varias veces puede imprimir las dos desconexiones inexistentes.

No se considera validación suficiente:

- ejecutar solo desde el editor;
- ejecutar solo una build debug;
- ejecutar solo headless;
- verificar únicamente que el parche existe en el repositorio.

Refs #801, #1156.
