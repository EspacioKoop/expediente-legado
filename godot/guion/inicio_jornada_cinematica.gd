## Inicio de jornada: una ficha breve antes de devolver el control al archivo.
##
## No avanza el día ni calcula economía: recibe una Jornada ya resuelta y solo
## la representa. Es deliberadamente 2D y provisional, como el resto de v0.7;
## migrarla a 3D no debe cambiar ni el marcador persistente ni el llamante.
class_name InicioJornadaCinematica
extends RefCounted

const ID := "inicio-jornada"

const PAPEL := Color("d8d5cc")
const TINTA := Color("35363a")
const SELLO := Color("8a4740")
const ACTIVA := Color("c7c4b9")
const VACIA := Color("58585c")


## Los datos exactos que se presentan. Separarlos de la figura permite probar
## que la cinemática mira el estado real y no mantiene otro contador paralelo.
static func datos_de(jornada: Dictionary) -> Dictionary:
	return {
		"dia": int(jornada.get("dia", 1)),
		"dinero": int(jornada.get("dinero", 0)),
		"acciones": int(jornada.get("acciones", 0)),
		"gato": bool(jornada.get("gato", {}).get("presente", false)),
	}


## Identidad persistente de una jornada. Incluye la vuelta: el día 1 de una
## reasignación es otro comienzo aunque comparta número con el primer día.
static func marca_de(jornada: Dictionary) -> String:
	return "%d:%d" % [int(jornada.get("vuelta", 1)), int(jornada.get("dia", 1))]


## Dos planos y 2,2 s en la primera vista. Al repetirse, el reproductor común
## los acorta; el segundo es el remate y conserva el suelo común de #67.
static func planos_de(jornada: Dictionary, vistas: int = 0) -> Array:
	var datos := datos_de(jornada)
	var rodaje := Cinematica.resolver(_planos(datos), {}, vistas)
	# Reutiliza el texto ya traducido del día en vez de duplicarlo en el CSV.
	rodaje[0]["rotulo"] = TranslationServer.translate("DIA_NUEVO") % datos["dia"]
	return rodaje


static func _planos(datos: Dictionary) -> Array:
	return [
		{
			"tipo": "2d",
			"segundos": 1.2,
			"figura": _calendario(datos["dia"]),
			"desde": Vector2.ZERO,
			"hasta": Vector2.ZERO,
		},
		{
			"tipo": "2d",
			"segundos": 1.0,
			"figura": _estado(datos["dinero"], datos["acciones"], datos["gato"]),
			"desde": Vector2.ZERO,
			"hasta": Vector2.ZERO,
		},
	]


## Una hoja arrancada. El número se expresa en el rótulo; las marcas rojas
## cambian con el día para que la repetición no sea una diapositiva idéntica.
static func _calendario(dia: int) -> Array:
	var figura := [
		{"rect": Rect2(-145, -135, 290, 230), "color": PAPEL},
		{"rect": Rect2(-145, -135, 290, 38), "color": SELLO},
		{"rect": Rect2(-112, -70, 224, 16), "color": TINTA},
		{"rect": Rect2(-112, -34, 172, 12), "color": TINTA},
	]
	for i in mini(maxi(dia, 1), 12):
		(
			figura
			. append(
				{
					"rect": Rect2(-112 + float(i % 6) * 38.0, 14 + float(i / 6) * 30.0, 24, 10),
					"color": SELLO,
				}
			)
		)
	return figura


## Estado sin duplicar el HUD en texto: dinero = grosor del bloque izquierdo,
## acciones = casillas centrales y gato = silueta derecha. Todo procede de la
## Jornada ya persistida; la animación no concede ni consume nada.
static func _estado(dinero: int, acciones: int, gato: bool) -> Array:
	var figura := [
		{"rect": Rect2(-270, -120, 540, 210), "color": TINTA},
		{"rect": Rect2(-245, -92, 150, 150), "color": PAPEL},
	]

	var bandas := clampi(int(maxi(dinero, 0) / 100), 0, 8)
	for i in bandas:
		figura.append({"rect": Rect2(-224, 36 - float(i) * 15.0, 108, 9), "color": SELLO})

	for i in Jornada.ACCIONES_POR_DIA:
		(
			figura
			. append(
				{
					"rect": Rect2(-60 + float(i % 3) * 42.0, -48 + float(i / 3) * 46.0, 28, 28),
					"color": ACTIVA if i < acciones else VACIA,
				}
			)
		)

	var color_gato := ACTIVA if gato else VACIA
	(
		figura
		. append_array(
			[
				{"rect": Rect2(120, -34, 92, 70), "color": color_gato},
				{"rect": Rect2(134, -70, 62, 42), "color": color_gato},
				{"rect": Rect2(134, -84, 16, 18), "color": color_gato},
				{"rect": Rect2(180, -84, 16, 18), "color": color_gato},
			]
		)
	)
	return figura
