# Literatura en el sueño (#1182)

## Contrato

La literatura es un **consumidor de presentacion**, no una segunda autoridad del
sueño. La selección de escenas sigue en `Sueno.noche()` y el contenido factual
sigue viniendo de #87/#79.

`SuenoLiteratura` recibe una sala ya construida y consulta exclusivamente el
canal `insight` del contrato #1176. Para que un evento sea consumible:

1. la obra debe existir en el catálogo canónico;
2. el `insight_id` del evento debe coincidir con el declarado por la lectura;
3. la obra debe declarar `sueno.consumidor = "sueno_literario"`;
4. los motivos y su modulación visual salen del catálogo, no de expedientes.

## Primer corte

`La vida es sueño` expone los motivos `umbral` y `doble`. El consumidor
puede modular deformación de textura, contraste y energía ambiental. No añade ni
reescribe:

- frases/carteles;
- figuras/sospechosos;
- pistas o hechos;
- salidas;
- selección de escenas.

Sin insight literario, el resultado es semánticamente idéntico al espacio base.
La transformación es pura y reversible: se trabaja sobre una copia profunda y
no se escribe en `Partida`, `Jornada` ni en el registro literario.

## Integración

`Dia._espacio_de("sueño")` construye primero la sala mediante
`Sueno.espacio(...)` y solo después invoca `SuenoLiteratura.aplicar(...)`.
Esto conserva la regla de #79: **el sueño no inventa contenido; deforma material
ya legitimado**.

Refs #79 #87 #888 #1175 #1176 #1182.
