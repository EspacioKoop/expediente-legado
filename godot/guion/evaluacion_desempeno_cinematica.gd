## Remate corporativo de una vida laboral ya sellada (#150 / #100).
##
## La reasignación reinicia Jornada antes de llegar a la cinemática, así que esta
## capa NO intenta reconstruir dinero, alquiler, sueño ni productividad desde la
## vida nueva. Lee exclusivamente el último registro persistido por
## EvaluacionDesempeno.sellar(), que fue congelado antes del reset.
class_name EvaluacionDesempenoCinematica
extends RefCounted

const ID := "evaluacion-desempeno-remate"

const FONDO := Color("27292d")
const PAPEL := Color("d4d0c8")
const TINTA := Color("42464b")
const GUIA := Color("a7a49d")

const ANCHO_BAJO := 34.0
const ANCHO_MEDIO := 68.0
const ANCHO_ALTO := 102.0
const CATEGORIAS := [
	"productividad",
	"precipitacion",
	"cuidado_gato",
	"liquidez",
	"exploracion_onirica",
	"dependencia_dinero",
]


static func planos_de(estado: Dictionary, vistas: int = 0) -> Array:
	var historial := EvaluacionDesempeno.historial(estado)
	if historial.is_empty():
		return []
	var registro: Variant = historial[historial.size() - 1]
	if not registro is Dictionary:
		return []
	var evaluacion: Variant = (registro as Dictionary).get("evaluacion", {})
	if not evaluacion is Dictionary:
		return []

	return (
		Cinematica
		. resolver(
			[
				{
					"tipo": "2d",
					"segundos": 1.65,
					"figura": _figura(evaluacion as Dictionary),
					"desde": Vector2.ZERO,
					"hasta": Vector2.ZERO,
					"rotulo": "EVALUACION_REMATE_ROTULO",
					"voz": _frase_de(evaluacion as Dictionary),
				}
			],
			{"vuelta": int((registro as Dictionary).get("vuelta", 0))},
			vistas,
		)
	)


static func _figura(evaluacion: Dictionary) -> Array:
	var figura := [
		{"rect": Rect2(-190, -95, 380, 190), "color": FONDO},
		{"rect": Rect2(-142, -78, 284, 156), "color": PAPEL},
		{"rect": Rect2(-112, -56, 224, 8), "color": TINTA},
	]
	var y := -34.0
	for categoria in CATEGORIAS:
		if not evaluacion.has(categoria):
			continue
		var rango := String(evaluacion.get(categoria, ""))
		figura.append({"rect": Rect2(-105, y, 210, 8), "color": GUIA})
		figura.append({"rect": Rect2(-105, y, _ancho_de(rango), 8), "color": TINTA})
		y += 19.0
	return figura


static func _ancho_de(rango: String) -> float:
	match rango:
		EvaluacionDesempeno.ALTA:
			return ANCHO_ALTO
		EvaluacionDesempeno.MEDIA:
			return ANCHO_MEDIO
		_:
			return ANCHO_BAJO


## Las frases describen contradicciones sin convertirlas en una nota total.
## El orden es deliberado y determinista para que recargar reproduzca la misma
## frase cuando varias condiciones podrían cumplirse a la vez.
static func _frase_de(evaluacion: Dictionary) -> String:
	if (
		String(evaluacion.get("productividad", "")) == EvaluacionDesempeno.ALTA
		and String(evaluacion.get("precipitacion", "")) == EvaluacionDesempeno.ALTA
	):
		return "EVALUACION_REMATE_PRODUCTIVA_PRECIPITADA"
	if (
		String(evaluacion.get("cuidado_gato", "")) == EvaluacionDesempeno.ALTA
		and String(evaluacion.get("liquidez", "")) == EvaluacionDesempeno.BAJA
	):
		return "EVALUACION_REMATE_CUIDADOS_LIQUIDEZ"
	if (
		String(evaluacion.get("exploracion_onirica", "")) == EvaluacionDesempeno.ALTA
		and String(evaluacion.get("productividad", "")) == EvaluacionDesempeno.BAJA
	):
		return "EVALUACION_REMATE_SUENO_PRODUCTIVIDAD"
	if (
		String(evaluacion.get("dependencia_dinero", "")) == EvaluacionDesempeno.ALTA
		and String(evaluacion.get("liquidez", "")) == EvaluacionDesempeno.ALTA
	):
		return "EVALUACION_REMATE_DEPENDENCIA_LIQUIDEZ"
	return "EVALUACION_REMATE_NEUTRA"
