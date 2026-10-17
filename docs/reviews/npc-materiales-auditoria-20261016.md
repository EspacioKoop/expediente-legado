# Auditoría de Materiales y Siluetas NPC 3D (2026-10-16)

**Autor / Agente:** Jules
**Corte:** Audit de auditoría técnica acotada (despacho)
**Referencias:** #399 #275 #2691
**Fichero autorizable:** `docs/reviews/npc-materiales-auditoria-20261016.md`

---

## Alcance y límites de evidencia
Esta auditoría es una **revisión estática y una lista de hipótesis visuales**, no una cata visual certificada. Se han contrastado rutas de código y recursos clave en GitHub el 16-10-2026; algunos GLB se gestionan mediante Git LFS y requieren inspección del checkout real. Las anomalías de silueta, escala, normales y legibilidad solo podrán declararse reproducidas cuando existan capturas comparativas y una prueba de juego a la resolución objetivo. No tomar propuestas de microcorrección como trabajo ya implementado.

## Criterios y Enfoque
Esta auditoría examina tres espacios tridimensionales y tres grupos de NPC existentes en la arquitectura de Godot de *Expediente Legado*. A diferencia de análisis genéricos, esta revisión identifica rutas reales de mallas, materiales, GDShaders y configuraciones de escena (`.tscn` / `.gd`), documentando anomalías verificables de escala, textura plana o recursos ausentes, y proponiendo microcorrecciones reproducibles sin alterar assets binarios en este corte.

---

## Part I: Auditoría de 3 Espacios Existentes

### 1. Oficina / Archivo (Planta 4)
* **Rutas reales de Malla / Material:**
  * Muebles y estructura: `godot/assets/modelos/` (los nombres concretos de GLB Quaternius citados inicialmente no se han verificado en el checkout; consultar `godot/guion/modelos.gd` y el inventario LFS antes de asignarlos).
  * Generación y pintado de material runtime: `godot/guion/modelos.gd`, `godot/guion/oficina_utileria.gd`, `godot/guion/espacio_3d.gd`.
  * Shaders / Materiales base: `godot/arte/psx_pbr.gdshader`, `godot/arte/psx.gdshader` (`Espacio3D.shader_del_sitio()`).
* **Anomalías verificables:**
  * **Material Plano / Textura:** Muchos muebles se colorean mediante `Modelos._pintar()` aplicando un `ShaderMaterial` con un color plano (`color_base`) sin mapa de albedo detallado o mapa de normales específico de melamina/plástico, dependiendo del triplanar procedural.
  * **Escalas:** `Modelos._encajar()` reescala dinámicamente las mallas importadas para encajarlas en el `AABB` declarada por la caja del catálogo (`tam`). Esto provoca que modelos con proporciones originales distintas se deformen en algún eje (ej. archivadores o mesas estiradas de manera no uniforme).
  * **Recursos Ausentes:** Ausencia de PBR especifico para mobiliario de oficina (`melamina`, `metal_pintado` usan fallback triplanar procedural de baja frecuencia en lugar de albedos 4K/2K dedicados).
* **Microcorrecciones reproducibles (Propuestas):**
  * Mantener el aspecto de caja del catálogo, pero aplicar un factor de escala uniforme basado en el eje dominante en `Modelos._encajar()` para evitar deformación de aspecto en las mallas GLB de Quaternius.
  * Extender `godot/assets/texturas/pbr/` con mapas de grano de melamina/metal suave sin alterar las mallas base.

---

### 2. Calle / Trayecto Urbano
* **Rutas reales de Malla / Material:**
  * Pieles de superficie (Calzada / Acera): `godot/guion/calle_materiales.gd` (`MeshInstance3D` generadas dinámicamente sobre la calzada 9x34).
  * Fachadas e iluminación: `godot/guion/calle_fachadas_vivas.gd`, `godot/guion/calle_locales_comerciales_3d.gd`.
  * Shaders / Materiales PBR: `godot/arte/psx_pbr.gdshader`, `godot/arte/psx_cristal.gdshader`, `godot/assets/texturas/pbr/` (`acera_barcelona`, `asfalto_urbano`, `fachada_edificio`).
* **Anomalías verificables:**
  * **Material Plano / Textura:** Cuando las texturas LFS no están presentes en local, el runtime conmuta inmediatamente a fallbacks procedurales (`loseta_acera`, `asfalto`), mostrando colores bastante planos con dithering sintético.
  * **Escalas & Siluetas:** Los escaparates y cristales en `calle_locales_comerciales_3d.gd` utilizan marcos comerciales en `metal_pintado` cuya escala UV triplanar está prefijada a repetición por metro fija (`ESCALAS_MATERIAL`), causando patrones de grano demasiado gruesos en marcos pequeños.
  * **Recursos Ausentes:** Mallas de bordillo y canalización ausentes entre acera y calzada; el salto es puramente un offset geométrico plano de 2-3 mm.
* **Microcorrecciones reproducibles (Propuestas):**
  * Ajustar el UV scale especifico para elementos arquitectónicos delgados (marcos de cristales/marquesinas) en `psx_cristal.gdshader`.
  * Añadir borde biselado a las mallas procedurales de acera en `CalleMateriales._superficie_suelo()`.

---

### 3. Casa / Dormitorio (Vigilia)
* **Rutas reales de Malla / Material:**
  * Mobiliario y acumulación: `godot/guion/casa_hogar_cc0.gd`, `godot/guion/casa_acumulacion_3d.gd`, `godot/guion/casa_rutinas_3d.gd`.
  * Iluminación / Ventana: `godot/pruebas/pruebas_luz_ventana_789.gd`, `godot/guion/casa_consecuencias_3d.gd`.
  * Shaders / Materiales: `godot/arte/psx.gdshader` con tintes cálidos/oscuros.
* **Anomalías verificables:**
  * **Material Plano:** Electrodomésticos y objetos de rutina (minicadena, persiana, caja de acumulación) usan colores planos con `Modelos._pintar()` o `plastico_domestico`, careciendo de variación de roughness o desgaste superficial.
  * **Escalas:** Las persianas y lamas en `casa_consecuencias_3d.gd` ajustan su tamaño mediante mallas de caja generadas por código (`BoxMesh`), con grosores desproporcionados respecto a las ventanas reales.
  * **Recursos Ausentes:** Falta de mapa de normales de tela/madera para sofás y marcos de cama en `casa_hogar_cc0.gd`.
* **Microcorrecciones reproducibles (Propuestas):**
  * Asignar roughness mapas ligeros procedurales a objetos domésticos mediante parámetros adicionales en el shader PSX.
  * Refinar el grosor y separación de lamas en `casa_consecuencias_3d.gd` para evitar siluetas toscas.

---

## Part II: Auditoría de 3 NPC Existentes

### 1. Compañeros de Oficina / Cuñado
* **Rutas reales de Malla / Material / Scripts:**
  * Modelo base: `godot/assets/modelos/persona.fbx` o modelos Rocketbox (`assets/modelos/rocketbox/male_adult_*`, `female_adult_*`).
  * Controlador / Lógica de visualización: `godot/guion/companeros.gd`, `godot/guion/vestuario_humano_3d.gd`, `godot/guion/correccion_visual_npc_275.gd`.
  * Piel / Retrato: `Modelos.PERFILES_FACIALES`, `PielCabeza275` (SphereMesh generada en `correccion_visual_npc_275.gd`).
* **Anomalías verificables:**
  * **Escala / Proporción:** En figuras que usan `persona.fbx`, la cabeza procedural original leía la distancia `Head` → `HeadTop_End`, provocando cabezas 2-3 veces más grandes que lo anatómico (parcialmente mitagado por `correccion_visual_npc_275.gd`).
  * **Material Plano & Silueta:** El cuerpo importado sin ropa asignada actúa como un maniquí de color uniforme. La cabeza genérica es una `SphereMesh` con 8 segmentos radiales y material unshaded/emisión leve (`EMISION_LEGIBILIDAD = 0.07`), resultando en una silueta muy facetada y carente de rasgos o sombras.
  * **Recursos Ausentes:** Falta de mapas de textura de vestuario/rostro para avatares secundarios que no usan el pipeline de Rocketbox completo.
* **Microcorrecciones reproducibles (Propuestas):**
  * Aumentar la densidad de segmentos de la esfera de cabeza procedural (`SphereMesh.radial_segments = 12`) o suavizar la transición de normales en `correccion_visual_npc_275.gd`.
  * Ajustar el tinte de sombreado del cuerpo importado para diferenciar textura de ropa de la piel base.

---

### 2. Dependientes de Tiendas (Calle)
* **Rutas reales de Malla / Material / Scripts:**
  * Montaje y colocación: `godot/guion/dependientes_tiendas_3d.gd`, `godot/guion/comercio_barrio_3d.gd`.
  * Avatares: Modelos Rocketbox (`godot/assets/modelos/rocketbox/`) instanciados vía `Modelos.persona()`.
  * Shader: `psx_pbr.gdshader` o shader estándar del sitio.
* **Anomalías verificables:**
  * **Silueta / Postura:** Los dependientes se sitúan delante/detrás del mostrador con la pose por defecto o ciclo de animación `idle`. Sin ajustes de altura de suelo, algunos pies se hunden levemente en la geometría de la acera/tienda.
  * **Material Plano:** La ropa de los modelos Rocketbox no cuenta con mapas de rugosidad/normales adaptados al entorno nocturno de la calle, viéndose totalmente planos bajo farolas o luces de escaparates.
  * **Recursos Ausentes:** Ausencia de props de contacto directos en manos (ej. periódico en el quiosquero, libreta en el tendero).
* **Microcorrecciones reproducibles (Propuestas):**
  * Ajustar el raycast/offset vertical de posicionamiento en `DependientesTiendas3D._montar_uno()` para alinear exactamente los pies con el plano transitable.
  * Configurar una pequeña luz de relleno o ajuste de parámetros del shader para mejorar el volumen visual del NPC tras mostradores oscuros.

---

### 3. Ecos de Sueño / Reclamantes 3D
* **Rutas reales de Malla / Material / Scripts:**
  * Instanciación y comportamiento: `godot/guion/ecos_sueno_3d.gd`, `godot/guion/previsualizador_reclamante_3d.gd`, `godot/guion/sueno_aquiles_alineacion.gd`.
  * Material y animación ghost: `MovimientoGhost`, `ShaderMaterial` con parámetros de transparencia / pulso onírico.
* **Anomalías verificables:**
  * **Material Plano / Transparencia:** Los fantasmas/ecos usan un shader de transparencia que elimina la profundidad y el volumen de la malla (`no_depth_test` o alpha uniforme), convirtiendo la figura en una silueta plana monocromática sin definición de extremidades.
  * **Escala:** Al reutilizar `persona.fbx` para los ecos oníricos sin pasar por el pipeline completo de `correccion_visual_npc_275.gd`, algunos ecos muestran discrepancias de escala entre el torso y los enganches de cabeza/accesorios.
  * **Recursos Ausentes:** Falta de un shader de disolución por ruido (dithered alpha dissolve) característico del estilo PSX/CRT.
* **Microcorrecciones reproducibles (Propuestas):**
  * Aplicar el modificador `correccion_visual_npc_275.gd` a los nodos de eco en `ecos_sueno_3d.gd`.
  * Reemplazar la transparencia alpha suave por dithering Bayer de transparencia en `psx.gdshader` para mantener la estética retro y evitar ordenación errónea de profundidad.

---

## Part III: Documentación Antes / Después y Playtest Pendiente

### Matriz de Resumen Comparativo

| Entidad / Espacio | Estado Anterior (Anomalía) | Estado Posterior (Propuesto / Microcorrección) |
| :--- | :--- | :--- |
| **Oficina (Planta 4)** | Muebles deformados por encaje no uniforme de AABB. Materiales melamina/metal sin mapa de grano. | Encaje con escala uniforme conservando relación de aspecto de GLB. Texturas PBR de grano fino. |
| **Calle (Trayecto)** | UV triplanar de marcos de cristal con escala desproporcionada. Transición acera-calzada plana. | Ajuste de UV scale para perfiles finos. Bisel geométrico en acera procedural. |
| **Casa (Dormitorio)** | lamas de persianas toscas y gruesas (`BoxMesh`). Electrodomésticos en color plano. | Reducción de grosor de lamas y separación realista. Variación de roughness en shader. |
| **NPC Compañeros** | Cabezas esféricas procedurales facetadas (8 segs). Maniquí base plano bajo ropa. | Esferas de 12 segs / normales suavizadas. Sombreado diferenciado en capa inferior. |
| **NPC Dependientes** | Intersección / hundimiento de pies en geometría de mostrador/tienda. | Offset vertical preciso relativo al plano del suelo. Ajuste de luz de relleno. |
| **NPC Ecos Sueño** | Siluetas transparentes planas sin profundidad ni dithering PSX. Discrepancia de escala de cabeza. | Dithering alpha ordenado por profundidad. Aplicación de `correccion_visual_275`. |

### Playtest Pendiente
1. **Verificación en juego (Godot Editor / Runtime):**
   * Inspección visual en Planta 4 (Oficina) comprobando que las mesas y sillas Quaternius mantienen su proporción sin estiramiento en Y.
   * Recorrido por el Trayecto Nocturno comprobando cristales y alineación de dependientes detrás de mostradores.
   * Entrada a la fase Sueño para evaluar la legibilidad de la silueta de los Ecos con dithered alpha.
2. **Impacto en rendimiento:**
   * Garantizar 60 FPS estables sin incremento de llamadas de dibujado (draw calls) ni consumo adicional de memoria VRAM.
