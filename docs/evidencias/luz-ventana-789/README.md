# Luz de ventana del archivo · #789

Segundo corte de #789. La jornada empieza a las 09:00, pero el cristal de las
dos ventanas del archivo era un azul de noche fijo del catálogo y por él no
entraba luz: el reloj de la pared decía una hora y la ventana otra.

## Cómo se obtuvieron

GPU real (Intel Alder Lake-N, Vulkan, Forward+, `DISPLAY=:0`), no xvfb: llvmpipe
falsea brillo y texturas. Montaje idéntico al gate de oficina #126
(`godot/pruebas/capturas_oficina_126.gd`: catálogo, dressing CC0, utilería,
compañeros) más `dia_reloj_horario_app.gd` colgando de un día mínimo con
`jornada.hora_minutos` fijado. Mismos dos encuadres en las cuatro tomas.

Cada comparativa es una rejilla 2×2:

| | |
| --- | --- |
| **antes**, 09:00 (`main` en `e3ca0cd6`) | **después**, 09:00 (mañana) |
| **después**, 16:30 (tarde) | **después**, 20:00 (noche) |

- `comparativa-acceso-ventanas.png`: el encuadre «acceso-ventanas» del gate #126.
- `comparativa-suelo-ventana.png`: hacia el suelo bajo las ventanas, donde cae
  la luz.

## Qué se midió

Media RGB de una franja de suelo bajo la ventana izquierda frente a una de suelo
lejano, sobre las PNG a 1280×720:

| Toma | Suelo bajo la ventana | Suelo lejano |
| --- | --- | --- |
| antes 09:00 | (39, 50, 70) | (39, 48, 64) |
| después 09:00 | (67, 78, 97) | (40, 49, 64) |
| después 16:30 | (62, 66, 79) | (39, 48, 63) |
| después 20:00 | (37, 48, 67) | (36, 45, 60) |

El suelo lejano no cambia; el de debajo de la ventana se aclara de día, vira a
cálido por la tarde y vuelve a la línea base de noche. Con el primer ajuste (haz
de 48° y energía de fluorescente) el mismo punto solo subía a 51: por eso el
haz es más cerrado y la energía, la de un sol y no la de una lámpara.

## Qué no demuestra

Solo es captura automatizada. No sustituye el pase humano de #789 ni dice cómo
se percibe en movimiento o con mando. Las figuras siguen leyéndose oscuras: su
material es de #275, no de este corte.
