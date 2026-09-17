# Kubasta — rol tipográfico de terminal (#298)

Fuente canónica: https://zichy.itch.io/kubasta  
Licencia publicada por el autor: **CC0-1.0 / Public Domain**.

## Estado del proyecto

Desde #836, `main` ya empaqueta **IBM Plex Mono** y `EstiloSiga.fuente_mono()`
dejó de depender de fuentes instaladas en el sistema. Eso resolvió la
reproducibilidad de la monoespaciada general, pero no la identidad específica
de terminal que persigue #298.

Este corte separa ambos conceptos:

- `fuente_mono()`: monoespaciada genérica para rótulos técnicos, texto 3D y
  otros consumidores que no deben cambiar de aspecto por una decisión de
  identidad de terminal;
- `fuente_terminal()`: rol semántico para terminales, consolas y bloques de
  diagnóstico; mientras Kubasta no esté incorporada de forma verificable,
  devuelve IBM Plex Mono como fallback reproducible;
- el `Theme` publica `terminal_font` para `RichTextLabel` y `LineEdit`,
  sin convertirlo en fuente global.

Por tanto, este corte **no sustituye la fuente global**, no cambia
`fuente_mono()` y no modifica todavía el aspecto visual del juego.

## Integración binaria pendiente

El siguiente corte de #298 debe partir del fichero real distribuido por el
autor. No se añadirá una ruta ficticia ni un hash de un mirror.

1. descargar el ZIP oficial desde la fuente canónica;
2. seleccionar únicamente **`Kubasta.ttf`**;
3. incorporar el fichero bajo `godot/assets/fonts/Kubasta.ttf` mediante
   **Git LFS** real;
4. calcular el **SHA-256** del fichero exacto que entra en el repositorio;
5. registrar ruta, título, autor, licencia **CC0-1.0**, URL canónica y hash en
   `godot/assets/procedencia.json`;
6. cambiar solo `fuente_terminal()` para cargar Kubasta y conservar IBM Plex
   Mono como fallback si el recurso no puede cargarse.

## Matriz de validación

La aceptación visual/funcional de Kubasta debe cubrir explícitamente:

- caracteres españoles: **áéíóúüñ¿¡**;
- cifras, folios y símbolos técnicos: `0123456789 []{}:/\\-_+*=#`;
- tamaños **10/12/14/16 px**;
- alto contraste claro/oscuro;
- **escalado entero** y **escalado no entero**;
- comparación frente a IBM Plex Mono en la misma superficie;
- fallback tipográfico sin cajas vacías ni sustituciones silenciosas;
- ausencia de recortes o cambios de layout en terminales y bloques técnicos.

## Criterio de alcance

Kubasta es una candidata para identidad de terminal y texto técnico pequeño.
No debe sustituir MFB Oldstyle, Atkinson Hyperlegible ni IBM Plex Mono fuera de
ese rol sin un playtest específico. #780 sigue siendo dueño de la tipografía
general de interfaz; #298 queda acotado al rol terminal.

Refs #172 #216 #780 #836.

— Odiseo (GPT-5.6 Sol)
