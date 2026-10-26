# #2519 · Contrato de acabado realista para SIGA-98 (primer corte)

## Decisión artística

No seguir añadiendo primitivas como sustitutos *finales* de mobiliario, arquitectura o criaturas. Una malla más subdividida y una textura generada en SVG **no constituyen automáticamente** un asset fotorrealista. El criterio es la credibilidad de la superficie y de la silueta desde la cámara del jugador, no el número de nodos, triángulos o materiales declarados.

- **Vigilia (oficina, calle, casa):** geometría verosímil, dimensiones físicas, albedo y rugosidad coherentes, marcas de uso motivadas por función, iluminación naturalista. Evitar suciedad aleatoria global y plástico uniforme.
- **Sueños:** emplear el mismo vocabulario material reconocible, y después romper las reglas espaciales, causales y lumínicas de forma intencional. No compensar la falta de modelos con oscuridad, niebla o glitches.
- **SIGA-98 / OS98 / CRT / anomalías:** conservar cuantización, dithering, scanlines y artefactos PSX como recursos diegéticos o de secuencias concretas. No imponer estos efectos a **todos** los assets PBR del mundo.
- **Siluetas deliberadamente abstractas:** siguen siéndolo cuando la ficción lo exige; nunca etiquetar un placeholder geométrico como «fotorrealista».

## Producción: buscar antes de generar

1. Identificar el uso en una escena real, cámara prevista, tamaño físico y presupuesto de detalle. Priorizar la oficina/archivo de #398 antes que ampliar el catálogo indiscriminadamente.
2. Buscar modelo o escaneado existente y auditar la **fuente original**, licencia comercial y redistribución (preferencia CC0/CC-BY compatible). Un marketplace de assets no autoriza necesariamente a publicar el original dentro de un repositorio público.
3. Si no hay modelo apto, modelar o esculpir en Blender con fotografías/referencias dimensionales. La generación IA puede ayudar a concept art, búsqueda y herramientas de preparación, pero no se acepta una reconstrucción de primitivas como asset final.
4. Preparar UV, albedo, normal, metallic, roughness y AO cuando apliquen. Corregir escala real, jerarquía de meshes y pivote. Exportar a glTF/GLB y comprobar importación en Godot 4.
5. Registrar fuente, autor, licencia y SHA-256 **reales** en `godot/assets/procedencia.json`; binarios según Git LFS. No escribir punteros LFS sin subir los objetos.
6. Capturar el resultado en Godot, renderer Forward+, sin HUD y desde la cámara de juego. Comparar el mismo encuadre contra el estado previo; la validación automática de importación no aprueba el arte.

## Contrato de integración: `materiales_importados`

Los bultos siguen teniendo su caja física y medidas declaradas. Por defecto, `Modelos.mueble()` mantiene el shader común y el acabado anterior. La nueva bandera opt-in permite conservar **los materiales originales** de un modelo importado, sin reemplazar su albedo, normal, metallic o roughness por el shader PSX:

```gdscript
{
    "pos": Vector3(1, 0.5, 2),
    "tam": Vector3(1.4, 1.0, 0.7),
    "modelo": "modelo_auditado_con_materiales",
    "materiales_importados": true
}
```

- Esta ficha es **ilustrativa**, no declara que dicho modelo exista.
- Si falta el modelo, el bulto conserva su caja visible como antes.
- Si el modelo existe pero alguna superficie carece de material, el opt-in **retrocede al shader común** para evitar una mezcla de superficies sin terminar.
- `bulto["material"]`, si se declara expresamente, sigue teniendo prioridad final sobre los materiales importados (contrato existente de `Espacio3D`).
- Las instancias con y sin bandera pueden compartir el mismo recurso GLB sin pisar sus materiales.
- La bandera habilita la ruta PBR, **no certifica** que un modelo con materiales simples de color plano sea fotorrealista. Se activa solo tras revisión visual.
- Este corte **no** cambia todavía `EspaciosCatalogo.OFICINA`, los shaders globales ni los tratamientos de personajes/sueños; necesita assets auditados y una revisión en juego antes de hacerlo.

## Gate artístico de la primera oficina

No ampliar a casa, calle ni nuevos sueños hasta que la oficina de referencia resulte convincente desde dos encuadres reproducibles (entrada y puesto de archivo), con:

- siluetas/volúmenes legibles y escala de muebles congruente con los personajes Rocketbox;
- suelo, pared, archivadores, mesas, teléfonos y CRT con materiales distintos y rugosidad apropiada;
- suciedad localizada y huellas de uso, no ruido pseudoaleatorio sobre todas las superficies;
- iluminación coherente con fluorescentes y ventanas, sombras de contacto y exposición sin zonas quemadas;
- ausencia de cajas/primitivas presentadas como assets finales en primer plano;
- captura comparativa anterior/posterior desde Godot a 1920×1080, además de comprobación de rendimiento en hardware objetivo;
- arte evaluado **por persona**, separado de CI verde y del simple número de tests.

Criterios de bloqueo: una textura estirada, materiales que desaparecen al importar, escala físicamente absurda, modelo sin licencia redistribuible, silueta evidente de placeholder o capturas obtenidas fuera del motor. No inventar aprobación visual ni métricas.

## Reparto entre agentes

- **Sourcing/auditoría:** identifica candidatos concretos y licencias, sin descargar a ciegas ni rellenar procedencia ficticia.
- **Preparación:** corrige modelos, UV, escala, mapas y exportación en Blender; mantiene nombres estables.
- **Integración:** selecciona el bulto exacto, habilita `materiales_importados` tras confirmar los mapas, conserva colisiones e interacción.
- **Revisión visual:** compara encuadres, marca fallos concretos y devuelve el asset a preparación si no supera el gate.

Este documento complementa #2519, #398 y #399. No reemplaza la fuente canónica de prioridades (#181) ni el registro de reservas (#2905).
