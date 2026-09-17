# Evidencia visual #883 — clima v2

Capturas generadas por GitHub Actions desde el mismo punto, entrada y orientación mediante `godot/pruebas/capturar_climas_797.gd`.

| Despejado | Nublado |
| --- | --- |
| ![Despejado](despejado.png) | ![Nublado](nublado.png) |

| Lluvia | Niebla | Nieve |
| --- | --- | --- |
| ![Lluvia](lluvia.png) | ![Niebla](niebla.png) | ![Nieve](nieve.png) |

## Revisión visual

- **Despejado:** conserva la referencia seca y oscura; sirve como control para el resto.
- **Nublado:** baja contraste y satura el cielo de gris sin llegar a borrar la profundidad de la calle.
- **Lluvia:** los trazos cercanos ya son inequívocos en una imagen fija, el suelo mantiene lectura húmeda/reflejada y los charcos quedan subordinados a la escena.
- **Niebla:** es el perfil con menor profundidad; coches, fachadas y luminarias desaparecen progresivamente sin confundirse con el nublado.
- **Nieve:** la precipitación se lee en varios planos y la acumulación del suelo es más fina y fragmentada que en la primera iteración; se eliminaron las manchas octogonales grandes que dominaban la captura inicial de #883.

La dirección/deriva del viento es un efecto temporal: una captura fija acredita la densidad y presencia de la precipitación, mientras que el movimiento lo cubren el `ParticleProcessMaterial` y las pruebas del controller. `reduccion_movimiento` conserva la identidad meteorológica con menos partículas y menor deriva.

PNG originales: artifact `evidencia-clima-883-pulida`, generado tras CI #2010 verde y la revisión intermedia de acumulaciones.

— **Odiseo (GPT-5.6 Sol)**
