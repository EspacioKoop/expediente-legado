## Proyección de una cinta onírica ante el jurado.
##
## Recibe un estado YA RESUELTO. No evalúa la grabación, no concede oficio y no
## altera el veredicto: únicamente convierte `valida`, `contaminada`, `blanco`
## o `caos` en planos del reproductor común.
class_name ProyeccionOniricaCinematica
extends RefCounted

const ESTADO_VALIDA := "valida"
const ESTADO_CONTAMINADA := "contaminada"
const ESTADO_BLANCO := "blanco"
const ESTADO_CAOS := "caos"
const ESTADOS := [ESTADO_VALIDA, ESTADO_CONTAMINADA, ESTADO_BLANCO, ESTADO_CAOS]

const SALA := Color("202124")
const MUEBLE := Color("4b4946")
const MARCO := Color("595a5d")
const PANTALLA := Color("c9c8bd")
const NEGRO := Color("101113")
const RUIDO := Color("797a7d")
const PAPEL := Color("d9d5c8")
const ALERTA := Color("844842")
const PERSONA := Color("3a3b3e")


static func es_estado(estado: String) -> bool:
	return ESTADOS.has(estado)


static func id_de(estado: String) -> String:
	assert(es_estado(estado), "Estado de proyección onírica desconocido")
	return "proyeccion-onirica-%s" % estado


static func planos_de(estado: String, vistas: int = 0) -> Array:
	assert(es_estado(estado), "Estado de proyección onírica desconocido")
	return Cinematica.resolver(_planos(estado), {}, vistas)


static func _planos(estado: String) -> Array:
	return [
		{
			"tipo": "2d",
			"nombre": "sala",
			"segundos": 0.8,
			"figura": _sala(_televisor_apagado()),
			"desde": Vector2.ZERO,
			"hasta": Vector2.ZERO,
		},
		{
			"tipo": "2d",
			"nombre": "proyeccion",
			"segundos": 1.3 if estado != ESTADO_BLANCO else 1.6,
			"figura": _sala(_pantalla_de(estado)),
			"desde": Vector2.ZERO,
			"hasta": Vector2.ZERO,
		},
		{
			"tipo": "2d",
			"nombre": "remate",
			"segundos": 1.2 if estado != ESTADO_BLANCO else 1.7,
			"figura": _remate_de(estado),
			"desde": Vector2.ZERO,
			"hasta": Vector2.ZERO,
		},
	]


static func _sala(pantalla: Array) -> Array:
	var figura := [
		{"rect": Rect2(-320, -190, 640, 330), "color": SALA},
		{"rect": Rect2(-130, -105, 260, 185), "color": MUEBLE},
	]
	figura.append_array(pantalla)
	figura.append_array(_jurado(false))
	return figura


static func _televisor_apagado() -> Array:
	return [
		{"rect": Rect2(-110, -90, 220, 140), "color": MARCO},
		{"rect": Rect2(-92, -72, 184, 104), "color": NEGRO},
	]


static func _pantalla_de(estado: String) -> Array:
	var figura := [
		{"rect": Rect2(-110, -90, 220, 140), "color": MARCO},
	]
	match estado:
		ESTADO_VALIDA:
			figura.append({"rect": Rect2(-92, -72, 184, 104), "color": PANTALLA})
			for i in 4:
				figura.append({"rect": Rect2(-72, -50 + float(i) * 22.0, 144, 8), "color": NEGRO})
		ESTADO_CONTAMINADA:
			figura.append({"rect": Rect2(-92, -72, 184, 104), "color": NEGRO})
			for i in 9:
				(
					figura
					. append(
						{
							"rect": Rect2(-92, -70 + float(i) * 12.0, 184, 6),
							"color": PANTALLA if i % 2 == 0 else RUIDO,
						}
					)
				)
		ESTADO_BLANCO:
			figura.append({"rect": Rect2(-92, -72, 184, 104), "color": PANTALLA})
		ESTADO_CAOS:
			figura.append({"rect": Rect2(-92, -72, 184, 104), "color": ALERTA})
			figura.append({"rect": Rect2(-72, -24, 144, 9), "color": NEGRO})
	return figura


static func _remate_de(estado: String) -> Array:
	var figura := _sala(_pantalla_de(estado))
	if estado == ESTADO_CAOS:
		# La pelea no vive aquí. Solo se rompe la composición del público para
		# que un futuro sistema de combate tenga una antesala visual inequívoca.
		figura.append_array(_jurado(true))
	return figura


static func _jurado(desordenado: bool) -> Array:
	var figura := []
	for i in 5:
		var x := -250.0 + float(i) * 105.0
		var y := 68.0
		if desordenado:
			y += -24.0 if i % 2 == 0 else 20.0
			x += 18.0 if i % 2 == 0 else -14.0
		figura.append({"rect": Rect2(x, y, 54, 72), "color": PERSONA})
		figura.append({"rect": Rect2(x + 9, y - 30, 36, 34), "color": PERSONA})
	return figura
