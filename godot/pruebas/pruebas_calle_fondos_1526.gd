extends SceneTree

## #1526: los impostores fotográficos de la calle apoyan la base del edificio
## en la acera. El recorte de cada webp no tiene planta baja; si el sprite se
## apoya por el borde de la imagen, queda un hueco a la altura de los ojos por
## el que asoman las siluetas oscuras del skyline.
##
## El hueco se mide aquí sobre la imagen, no se copia de la declaración:
## si alguien sustituye un webp sin actualizar `hueco_inferior`, esto falla.

## Umbral de alfa del sprite (alpha_scissor_threshold = 0.18).
const ALFA_VISIBLE := 0.18
## Una fila es del cuerpo del edificio si al menos la mitad es visible.
const COBERTURA_CUERPO := 0.5
## Medio píxel de imagen a la altura del impostor ronda los 2 cm.
const TOLERANCIA_M := 0.05

var pasadas := 0
var fallos := 0


func _init() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	CalleFondosFotorealistas98.montar(mundo)
	var capa := mundo.get_node_or_null(CalleFondosFotorealistas98.NOMBRE_CAPA)
	comprobar("se monta la capa", capa != null, true)

	for datos in CalleFondosFotorealistas98.BLOQUES:
		var nombre := String(datos["nombre"])
		var ruta := CalleFondosFotorealistas98.BASE + String(datos["archivo"])
		var textura := load(ruta) as Texture2D
		var imagen := textura.get_image() if textura != null else null
		comprobar("%s: imagen legible" % nombre, imagen != null, true)
		var sprite := capa.get_node_or_null(nombre) as Sprite3D if capa != null else null
		comprobar("%s: sprite montado" % nombre, sprite != null, true)
		if imagen == null or sprite == null:
			continue

		var hueco := _hueco_inferior(imagen)
		comprobar(
			"%s: hueco declarado ≈ medido (%.3f)" % [nombre, hueco],
			absf(float(datos.get("hueco_inferior", 0.0)) - hueco) < 1.0 / imagen.get_height(),
			true
		)
		var alto_m := sprite.pixel_size * imagen.get_height()
		var base_imagen := sprite.position.y - alto_m / 2.0
		var base_edificio := base_imagen + hueco * alto_m
		comprobar(
			"%s: la base del edificio toca la acera (%.2f m)" % [nombre, base_edificio],
			absf(base_edificio) < TOLERANCIA_M,
			true
		)

	mundo.free()
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


## Fracción de la imagen, desde abajo, por debajo de la última fila del cuerpo.
func _hueco_inferior(imagen: Image) -> float:
	var ancho := imagen.get_width()
	var alto := imagen.get_height()
	for y in range(alto - 1, -1, -1):
		var visibles := 0
		for x in ancho:
			if imagen.get_pixel(x, y).a > ALFA_VISIBLE:
				visibles += 1
		if float(visibles) / float(ancho) >= COBERTURA_CUERPO:
			return float(alto - 1 - y) / float(alto)
	return 0.0


func comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		pasadas += 1
	else:
		fallos += 1
		print("FALLO %s: obtenido %s, esperado %s" % [nombre, obtenido, esperado])
