# Yggdrasil y Nornas — referencias culturales para #653

Este corte documenta las fuentes antes de incorporar arte histórico. El vertical actual usa solo geometría y materiales procedurales propios; **no copia ni empaqueta imágenes externas**.

## Fuentes primarias medievales

Las referencias de diseño se limitan a motivos atestiguados en las fuentes medievales, sin convertir reconstrucciones modernas en hechos antiguos:

- **Völuspá 19–20**: Yggdrasil aparece como un fresno asociado al pozo de Urðr; las tres Nornas nombradas son Urðr, Verðandi y Skuld. Traducción inglesa de Henry Adams Bellows disponible en Internet Sacred Text Archive: https://sacred-texts.com/book/the-poetic-edda/shell/voluspo
- **Grímnismál 29–35**: describe Yggdrasil, sus raíces y seres asociados al árbol. Para este vertical interesa sobre todo la idea de ramas/raíces que conectan ámbitos separados, no convertir cada criatura citada en contenido obligatorio: https://sacred-texts.com/neu/poe/poe06.htm
- **Snorri Sturluson, Gylfaginning XV**: desarrolla el árbol, sus tres raíces, pozos y las Nornas junto a Urðarbrunnr. Traducción de Arthur Gilchrist Brodeur (1916) en Wikisource: https://en.wikisource.org/wiki/The_Prose_Edda_(1916_translation_by_Arthur_Gilchrist_Brodeur)/Gylfaginning

## Qué se toma y qué no

Se toman tres ideas verificables y suficientemente generales:

1. **árbol como estructura que conecta ámbitos separados**;
2. **raíces y ramas como relaciones legibles entre lugares**;
3. **Nornas como motivo de causalidad/destino**, traducido aquí a tensiones y consecuencias visibles, no a NPCs expositivos.

No se fija como «canónico» ningún mapa moderno de nueve mundos, diagrama esotérico, código de colores, runario decorativo ni jerarquía espacial derivada de videojuegos, cine, neopaganismo contemporáneo o infografías recientes. Si se usa alguno como inspiración visual posterior deberá etiquetarse como reconstrucción o convención moderna.

## Traducción al vertical SIGA-98

- **raíces ↔ cables/conductos**: cada conexión existe físicamente antes de que el jugador actúe;
- **tronco ↔ terminal/fotocopiadora incrustada**: nodo central reconocible por lenguaje de oficina, sin introducir datos nuevos del expediente;
- **ramas ↔ pasarelas/organigramas**: una relación administrativa se convierte en arquitectura;
- **Nornas ↔ tensión causal**: la intervención en un nodo modifica otro distante y el resultado devuelve origen, destino y tipo de efecto;
- **retorno permanente**: ninguna lectura mitológica puede bloquear la salida; la solución se basa en seguir el grafo.

## Límites de dirección artística

- evitar cascos con cuernos, guerreros vikingos, runas usadas como simple textura y iconografía de acción sin respaldo en el objetivo del issue;
- no representar a las Nornas como «tres brujas» estandarizadas si no existe una decisión narrativa explícita y documentada;
- no presentar traducciones modernas de sus nombres como equivalencias exactas y exhaustivas del concepto medieval;
- cualquier reproducción histórica futura deberá registrarse en `godot/assets/procedencia.json` con URL, derechos/licencia y `sha256`.

## Estado del corte

El vertical implementa tres nodos y tres conexiones causales visibles, con interacción 3D común en cada nodo. La activación deliberada mediante el póster se monta únicamente en la vivienda real (`casa`), y durante la fase de sueño el controlador de `Dia` consume `SemillasOniricas` + `MitologiasNoche` para insertar Yggdrasil solo en la escena asignada, conservando la cámara, iluminación y salida del sueño base. `reduccion_movimiento` se propaga al grafo causal sin cambiar sus reglas. El arte final queda deliberadamente pendiente hasta revisar varias referencias visuales y separar con claridad fuente medieval, reconstrucción académica y convención pop.

## Atrezzo diegético de vigilia

El pase de arte incorpora dos objetos ficticios contemporáneos al mundo del juego, no dos fuentes históricas:

- un **bonsái doméstico de Yggdrasil**, cuyo tronco, raíces expuestas y ramificación exagerada traducen a escala de salón la idea de ámbitos conectados;
- **Yggdrasil's Egg**, caja de un videojuego ficticio expuesta en Bit 98 como puro atrezzo.

Ambos se etiquetan deliberadamente como interpretaciones comerciales/decorativas de 1998. Sus mapas, iconografía fantástica o convenciones visuales no se usan para afirmar la cosmología medieval ni para resolver el sueño. El bonsái no activa la semilla —esa responsabilidad sigue en el póster interactivo— y `Yggdrasil's Egg` no entra en el catálogo de ROMs ni en la economía.

Los recortes de runtime son arte propio generado para el proyecto y se registran con SHA-256 en `godot/assets/procedencia.json`.
