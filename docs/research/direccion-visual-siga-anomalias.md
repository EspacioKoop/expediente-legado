# Dirección visual: SIGA, anomalías y emisiones CRT

Este documento integra tres láminas de referencia creadas para orientar trabajo futuro sin convertirlas en assets runtime ni en una nueva fuente de verdad del juego.

## Láminas

- [`referencia-visual-anomalias-siga.svg`](../capturas/referencia-visual-anomalias-siga.svg): lenguaje visual para #87/#149. Parte siempre de un original reconocible y deforma escala, geometría, repetición, material o relación espacial. La imagen no interpreta el símbolo ni revela soluciones.
- [`referencia-visual-sellos-siga.svg`](../capturas/referencia-visual-sellos-siga.svg): gramática física para los reconocimientos de #148. Debe consumir el catálogo/estado ya definido por #189 y sus superficies posteriores; esta hoja no crea ids, condiciones ni persistencia alternativas.
- [`referencia-visual-televisores-1998.svg`](../capturas/referencia-visual-televisores-1998.svg): categorías de contenido para el escaparate de #142: informativo, deporte, institucional, técnica, anomalía e infantil/ocio. Son categorías y composición, no emisiones históricas afirmadas como reales.

## Contratos que no cambian

### Sueño y anomalías

#87 sigue siendo la fuente conceptual sobre qué puede deformarse y de qué original procede. #149 registra reconocimiento persistente; no decide progreso onírico, puzzles ni significado. El catálogo integrado por #491 ya mantiene esa separación y estas referencias deben utilizarse únicamente para `representacion` o para dirección de arte posterior.

Una anomalía debe cumplir:

1. el jugador puede reconocer el original;
2. la deformación altera forma, escala, repetición, material o contexto;
3. la descripción registra lo observado, no lo interpreta;
4. verla no equivale a resolver un puzzle ni a obtener una pista;
5. una miniatura futura debe poder existir sin enseñar coordenadas, rutas u objetivos pendientes.

## Sellos SIGA

#148 ya tiene trabajo técnico desglosado en #189 y una superficie de consulta posterior. Por tanto, la lámina de sellos solo define presentación: tinta, borde, jerarquía tipográfica e iconografía.

Reglas visuales:

- aspecto de sello físico de oficina, no medalla ni badge moderno;
- tinta roja, azul o negra con pequeñas imperfecciones;
- lenguaje administrativo seco;
- iconos simples que sigan siendo legibles a baja resolución;
- al menos un reconocimiento explícitamente improductivo;
- ninguna marca debe sugerir dinero, acciones, pistas o mejora de estadísticas.

Los textos de ejemplo de la lámina no deben convertirse automáticamente en claves de catálogo. Antes de llevar uno al juego hay que enlazarlo con una condición ya decidida y verificable.

## Escaparate CRT

#142 ya soporta un fichero distinto por aparato y nieve como estado válido. La referencia propone seis familias de emisión para evitar que el escaparate se lea como seis copias del mismo vídeo.

Para contenido definitivo:

- mantener relación 4:3 y lectura CRT/VHS;
- priorizar bucles cortos y silenciosos;
- no usar logos, marcas, presentadores o imágenes con copyright sin procedencia compatible;
- no afirmar hechos históricos concretos solo para rellenar la pantalla;
- la anomalía puede ser ambigua, pero no debe adelantar información que el jugador no haya visto;
- medir coste antes de reproducir seis vídeos simultáneos.

## Uso de estas imágenes

Son **referencias de dirección artística versionables**, no assets finales del juego. Se han rehecho como SVG autocontenido para poder revisarlas en Git sin añadir binarios ni objetos LFS. No se registran en `godot/assets/procedencia.json` porque no se cargan desde Godot ni se distribuyen como contenido runtime.

Si alguna parte pasa a `godot/assets/`, deberá seguir entonces el flujo normal del repositorio: formato definitivo, procedencia aplicable, `sha256`, LFS cuando corresponda y prueba de integridad.

Refs #79 #87 #95 #140 #142 #148 #149 #189 #299 #363 #400.

— Odiseo (GPT-5.6 Sol)
