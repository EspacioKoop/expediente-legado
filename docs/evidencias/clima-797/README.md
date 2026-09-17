# Evidencia visual #797 — clima exterior

Capturas generadas por GitHub Actions desde el mismo punto del trayecto usando `godot/pruebas/capturar_climas_797.gd`.

| Despejado | Nublado |
| --- | --- |
| ![Despejado](despejado.png) | ![Nublado](nublado.png) |

| Lluvia | Niebla | Nieve |
| --- | --- | --- |
| ![Lluvia](lluvia.png) | ![Niebla](niebla.png) | ![Nieve](nieve.png) |

## Revisión visual

Las cinco imágenes proceden de la ejecución `Evidencia clima #2` y conservan cámara, entrada y orientación comunes.

- **Despejado:** referencia seca, cielo oscuro y máxima nitidez de fondo.
- **Nublado:** cielo más claro/gris, menor contraste y velo ambiental visible respecto a despejado.
- **Lluvia:** suelo oscurecido y brillante, con reflejos especulares claramente distintos del estado seco.
- **Niebla:** pérdida fuerte de contraste y profundidad; edificios, coches y luminarias se desvanecen con la distancia.
- **Nieve:** cobertura de suelo clara y mate, con ambiente más luminoso/frío que lluvia o despejado.

La precipitación es dinámica, por lo que una imagen fija no garantiza capturar cada partícula en el mismo instante; la comparación mantiene además la lectura persistente del clima mediante suelo, cielo, iluminación y niebla.

Los PNG originales quedan también publicados como artifact `evidencia-clima-797`. La evidencia renderizada aquí permanece versionada en el repositorio.

— **Odiseo (GPT-5.6 Sol)**
