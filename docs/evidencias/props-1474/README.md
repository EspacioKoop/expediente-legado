# Evidencia de props personales de escritorio · #1474

Este gate cubre el criterio visual que quedó pendiente tras integrar #1477:
comprobar desde la **cámara jugable** que varios puestos se distinguen por
composición y silueta sin depender del cuerpo del NPC.

El workflow **Evidencia props puestos 1474** arranca `dia.tscn`, entra en la
oficina real y deja que el runtime asigne primero los perfiles de utilería. A
continuación retira los cuerpos que llevan `companero_id` y genera **tres
capturas sin NPC**, una por puesto.

El proyecto declara **Forward+** como renderer canónico, pero el runner alojado
de GitHub puede no exponer Vulkan y Godot puede caer a OpenGL para generar el
artifact. Por eso el manifiesto registra el **renderer efectivo** y el workflow
no finge que CI ha validado iluminación Forward+. Estas imágenes sirven para
comparar composición, silueta, escala y oclusión; cualquier decisión sensible a
iluminación/materiales debe confirmarse en una build real que use el renderer
canónico.

El artifact contiene:

- `puesto-1.png`;
- `puesto-2.png`;
- `puesto-3.png`;
- `manifest.json`.

El manifiesto conserva para cada mesa el `perfil_props` asignado antes y
después de retirar los cuerpos, la firma de hijos visibles del
`PuestoUtileriaN`, el hash de la captura, el renderer efectivo y el contexto
del render. El workflow comprueba que los tres perfiles y las tres firmas de
composición son distintos, pero eso solo prueba que el montaje no es idéntico.

## Revisión humana obligatoria

El gate **no autoaprueba** la composición. Hay que abrir las tres capturas del
mismo SHA y registrar PASS/FAIL para:

1. **Diferenciación:** sin NPC, cada mesa se reconoce como una composición
   distinta a primera vista.
2. **Escala:** agenda, termo, planta, calculadora, cajas y demás piezas guardan
   proporciones plausibles respecto al escritorio, teclado y teléfono.
3. **Oclusión:** ningún prop tapa de forma problemática monitor, teclado ni la
   zona que el jugador necesita leer.
4. **Silueta:** la diferencia no depende solo de color; volumen y distribución
   cambian entre puestos.
5. **Coherencia:** los objetos parecen utilería de oficina y no elementos de HUD,
   marcadores o pistas flotantes.

Un registro de cierre puede usar:

```text
Validación visual #1474 · SHA <sha>
- renderer efectivo del artifact: <renderer>
- puesto 1: PASS
- puesto 2: PASS
- puesto 3: PASS
- escala/oclusión: PASS
- observaciones: ...
```

Si una vista falla, el siguiente cambio debe señalar la mesa y el prop concreto
que necesita recolocación o ajuste de escala; no hace falta reabrir el sistema
de perfiles completo.
