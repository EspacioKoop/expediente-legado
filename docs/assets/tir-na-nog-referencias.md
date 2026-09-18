# Tír na nÓg — referencias culturales para #654

Este corte documenta variantes antes de fijar iconografía o guion. El prototipo usa geometría/materiales propios y **no empaqueta imágenes ni transcripciones externas**.

## Tradición recogida: Dúchas / National Folklore Collection, UCD

Se contrastan varias entradas del archivo, no una única versión asumida como «la» historia:

- **CBÉ 0027, p. 114 — “Tír na nÓg agus Daoine a Chuaidh ann - Oisín”** (registro de 1935; volumen catalogado en 1938, Waterville/An Coireán, Co. Kerry): https://www.duchas.ie/en/cbe/9000025/7021575/9093816
- **CBÉ 0033 (Part 1), p. 17 — “Oisín - A Thuras go Tír na nÓg, A Chasadh, A Bhaisteadh…”** (marzo de 1933; informante Séamas de Paor): https://www.duchas.ie/ga/cbe/9001159/7024183/9096036
- **CBÉ 0514 (Part 2), pp. 129–130 — “Oisín i dTír na nÓg”** (1 de marzo de 1938; informante Seán Ó Mathghamhna): https://www.duchas.ie/en/cbe/9001647/7266186/9103102 y https://www.duchas.ie/en/cbe/9001647/7266187/9103102
- **Bailiúchán na Scol, An Charraig — “Oisín i dTír na nÓg”** (informante Pádraig Ó Baoighill): https://www.duchas.ie/ga/cbes/4428327/4395540/4500720

Estas fichas se tratan como **tradición recogida en el siglo XX por un archivo folklórico**, no como testimonio medieval directo. Algunas páginas están transcritas por voluntariado y otras siguen manuscritas; el diseño no depende de una lectura paleográfica concreta.

## Capa literaria separada

La historia conocida también circula a través de reelaboraciones literarias. Para no mezclarlas con el archivo oral:

- Mícheál Coimín / Michael Comyn, *Laoi Oisín ar Thír na nÓg* (siglo XVIII) se registra como **reelaboración literaria**, no como equivalente automático de todas las variantes orales.
- Como referencia historiográfica secundaria, *The Mythology of All Races*, vol. 3, cap. 13, distingue el poema dieciochesco de tradiciones anteriores sobre Oisín: https://en.wikisource.org/wiki/The_Mythology_of_All_Races/Volume_3/Celtic/Chapter_13
- Retellings posteriores —incluido el Revival irlandés— deben etiquetarse por autor y fecha si llegan a influir arte o texto; no se usarán como “folklore anónimo” por defecto.

## Motivos retenidos para el vertical

El corte toma únicamente motivos que permiten construir la mecánica sin exigir conocimiento previo:

1. **salir y regresar no conserva la misma relación con el tiempo**;
2. **el umbral importa más que una fauna feérica genérica**;
3. **el retorno revela discontinuidad entre dos estados del mismo mundo**.

No se fija una cronología literal de “X años”, ni una cosmología completa, ni una lista de criaturas. El sueño traduce el motivo a una oficina SIGA-98 desincronizada.

## Decisiones propias del sueño

- dos versiones simultáneas como máximo: `reciente` y `envejecida`;
- una misma planta de oficina mantiene geometría reconocible en ambos lados;
- mover una **taza**, **silla** o **archivador** deja un reflejo legible en la otra versión (marca, silueta o huella de óxido);
- una franja de “arroyo” atraviesa ambas versiones como frontera continua;
- cruzar nunca borra inventario, progreso ni objetos críticos;
- la solución se basa en comparar continuidad espacial y cambios de estado, no en identificar a Oisín, Niamh o una versión concreta del relato.

## Accesibilidad y procedencia

- `reduccion_movimiento` sustituye la transición espacial por `corte_fundido`, sin alterar versión destino ni reglas de objetos;
- no hay time-lapse agresivo ni reloj contrarreloj;
- el estado se serializa como versión actual + estados de objetos y puede restaurarse de forma determinista;
- cualquier reproducción visual histórica futura deberá registrarse en `godot/assets/procedencia.json` con URL, derechos/licencia y `sha256`.

## Estado del corte

El prototipo standalone de #760 queda conectado al ciclo real: la minicadena doméstica de #670 incluye `Radio Oeste 98` y la pieza `islas_fuera_del_tiempo`, que exige dos acciones de atención antes de registrar `tir_na_nog` mediante `SemillasOniricas`. Durante la fase de sueño, `dia_tir_na_nog_app.gd` consulta la selección común y `MitologiasNoche` antes de montar el vertical en la escena asignada; sin semilla o sin asignación, no aparece. La escena standalone se conserva como harness aislado de pruebas, no como segunda ruta de gameplay.
