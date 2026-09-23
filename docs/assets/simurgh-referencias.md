# Simurgh — referencias culturales y de arte para #658

Este corte documenta las referencias antes de incorporar arte histórico. El vertical implementado usa únicamente geometría/materiales procedurales propios; **no copia ni empaqueta ninguna imagen externa**.

## Criterio cultural

La familia se apoya en el Simorḡ/Simurgh del `Shahnameh`, en particular en su relación con Zāl: rescate, crianza/tutela, nido en altura y protección. La mecánica toma de ahí **altura, refugio y cambio de perspectiva**, pero no recrea literalmente la narración ni presenta al Simurgh como un «fénix persa» intercambiable.

La Encyclopaedia Iranica distingue sus apariciones épicas, folclóricas y místicas y describe al Simorḡ del `Shahnameh` como salvador, tutor y guardián de Zāl. Esa distinción es el límite de diseño principal para texto y arte posteriores.

- Encyclopaedia Iranica — **SIMORḠ**: https://www.iranicaonline.org/articles/simorg/
- Encyclopaedia Iranica — **ZĀL**: https://www.iranicaonline.org/articles/zal/

## Referencias visuales primarias

The Metropolitan Museum of Art conserva folios del `Shahnama` útiles para composición, relación de escala y disposición del nido. El primer vertical **no reutiliza** estas imágenes; solo sirven como referencia documentada.

- The Met — **“Birth of Zal”, Folio from a Shahnama**, 1576–77, objeto 34.72: https://www.metmuseum.org/art/collection/search/449008
- The Met — **“Zal in the Simurgh's Nest”, Folio from a Shahnama**, ca. 1330–40, objeto 1974.290.2: https://www.metmuseum.org/art/collection/search/452627

Ambas fichas del Met identifican sus imágenes como Public Domain. Si en un corte posterior se incorpora una reproducción concreta al juego, deberá registrarse el archivo exacto en `godot/assets/procedencia.json` con URL de origen, licencia/estado de derechos y `sha256`, siguiendo la política del repositorio.

## Traducción al vertical

- **Pluma → pasarela:** misma silueta y color en dos escalas; el jugador reconoce una identidad persistente, no un portal arbitrario.
- **Archivadores → montañas:** la masa repetida de SIGA se reinterpreta como cordillera sin introducir información nueva de expedientes.
- **Lámpara → nido:** la altura/refugio de la referencia épica se transforma en arquitectura onírica doméstica.
- **Sombra de ave:** presencia ambiental abstracta; evita fabricar una anatomía «canónica» donde las fuentes visuales varían entre épocas y talleres.
- **Cambio de capa:** intercambio discreto de escena, nunca interpolación del tamaño físico del jugador.

## Estado del corte

El vertical ya está conectado al ciclo real. En fase `casa`, `Dia` monta una lámina examinable en la vivienda real; verla de fondo no activa la familia y el jugador debe observarla y girarla deliberadamente. En fase `sueño`, el controller consume exclusivamente `SemillasOniricas` + `MitologiasNoche` y materializa Simurgh solo en la escena asignada.

El cambio de escala deja de ser una API de prototipo: cada capa expone un `Interactuable3D` sobre la misma ancla pluma/pasarela. Al cambiar de capa se desactiva físicamente el hotspot de la capa oculta para evitar interacciones fantasma. `reduccion_movimiento` mantiene la misma regla espacial mediante corte/fundido, sin zoom, movimiento forzado de cámara ni escalado interpolado del jugador.

La emisora cultural doméstica sigue siendo una fuente alternativa compatible con el contrato común de semillas, pero la lámina queda como superficie principal de vigilia para este vertical.

## Pendiente antes de arte final

1. Elegir una dirección visual propia basada en varias referencias persas, no en una única miniatura.
2. Registrar cualquier textura/reproducción externa en `godot/assets/procedencia.json` antes de integrarla.
3. Revisar nombres, texto diegético y silueta final para no mezclar sin contexto tradiciones épicas, folclóricas y místicas.
