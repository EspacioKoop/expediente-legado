# Luz por píxel del mobiliario y las personas · #789

Tercer corte de #789. #1243 pasó la envolvente de la oficina a luz por píxel,
pero lo que hay dentro fijaba el shader canónico. Inventariada la oficina
montada con las capas del gate #126, unas 140 superficies seguían en luz por
vértice: muebles CC0, utilería, monitores, el archivador vintage, las personas
y su ropa. Proyectaban sombra y no la recibían.

## Cómo se obtuvieron

GPU real (Intel Alder Lake-N, Vulkan, Forward+, `DISPLAY=:0`), no xvfb. Montaje
idéntico al gate de oficina #126 más `dia_reloj_horario_app.gd` a las 09:00.
**Antes** es `main` en `1811e182` con los cinco consumidores sin tocar;
**después**, este corte. Mismos encuadres.

- `comparativa-puestos-archivo.png`: arriba antes, abajo después. Encuadre
  «puestos-archivo» del gate #126.
- `comparativa-companero-cerca.png`: arriba antes, abajo después. Un
  compañero a dos metros.
- `zoom-figuras.png`: recortes de figuras, antes y después por parejas.

## Qué se midió

Luminancia (media, desviación) sobre las PNG a 1280×720:

| Región | Antes | Después |
| --- | --- | --- |
| figura cercana (`companero-cerca`) | 88,8 / 41,2 | 77,0 / 39,2 |
| figura izquierda (`puestos-archivo`) | 88,8 / 44,4 | 79,7 / 43,3 |
| mesa rosa (`companero-cerca`) | 72,3 / 25,4 | 89,1 / 32,6 |

Tras el cambio no queda en la oficina ni una superficie con `psx.gdshader`
(inventario: 0), y calle y casa conservan el canónico.

## Qué no demuestra

- Las figuras ganan volumen, porque luz y sombra se separan en cara, torso y
  piernas, pero **quedan algo más oscuras de media**, y la cara de la figura
  cercana pierde luz. Si eso empeora la lectura de #275 lo tiene que decidir
  un humano. No se ha compensado subiendo la emisión de legibilidad, que es
  criterio de #275.
- Solo es captura automatizada: no hay validación humana, ni en movimiento ni
  con mando.
