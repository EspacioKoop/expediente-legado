extends SceneTree

var _pasadas := 0
var _fallos := 0

const RECETAS := [
	{
		"id": "documento_reforzado",
		"ingredientes": ["documento", "cinta"],
		"resultado":
		{
			"id": "documento_reforzado",
			"nombre": "Documento reforzado",
			"categoria": "documento",
			"origen": "combinacion",
			"vendible": false,
			"precio": 0,
		},
	},
	{
		"id": "linterna_revisada",
		"ingredientes": ["linterna", "bateria"],
		"consumir": ["linterna", "bateria"],
		"resultado":
		{
			"id": "linterna",
			"nombre": "Linterna revisada",
			"categoria": "herramienta",
			"usos": ["iluminar"],
			"origen": "combinacion",
			"vendible": false,
			"precio": 0,
		},
	},
]


func _initialize() -> void:
	_comprobar(
		(
			CombinacionObjetos.firma("cinta", "documento")
			== CombinacionObjetos.firma("documento", "cinta")
		),
		"la firma de pareja es conmutativa",
	)

	var inventario := Inventario.nuevo()
	_agregar(inventario, "documento")
	_agregar(inventario, "cinta")

	var vista := CombinacionObjetos.previsualizar(inventario, RECETAS, "cinta", "documento")
	_comprobar(vista["estado"] == CombinacionObjetos.ESTADO_EXITO, "resuelve la receta al revés")
	_comprobar(
		String(vista["resultado"]["id"]) == "documento_reforzado",
		"previsualizar devuelve el resultado sin mutar",
	)
	_comprobar(Inventario.contiene(inventario, "documento"), "previsualizar conserva ingrediente A")
	_comprobar(Inventario.contiene(inventario, "cinta"), "previsualizar conserva ingrediente B")

	var aplicado := CombinacionObjetos.combinar(inventario, RECETAS, "documento", "cinta")
	_comprobar(aplicado["estado"] == CombinacionObjetos.ESTADO_EXITO, "aplica combinación válida")
	_comprobar(not Inventario.contiene(inventario, "documento"), "consume primer ingrediente")
	_comprobar(not Inventario.contiene(inventario, "cinta"), "consume segundo ingrediente")
	_comprobar(
		Inventario.contiene(inventario, "documento_reforzado"),
		"materializa el resultado en carried",
	)

	var sin_receta := inventario.duplicate(true)
	_agregar(sin_receta, "palanca")
	_agregar(sin_receta, "revista")
	var huella := JSON.stringify(sin_receta)
	var fallo := CombinacionObjetos.combinar(sin_receta, RECETAS, "palanca", "revista")
	_comprobar(fallo["motivo"] == "sin_receta", "una pareja desconocida falla de forma explícita")
	_comprobar(JSON.stringify(sin_receta) == huella, "un fallo no muta el inventario")

	var mejora := Inventario.nuevo()
	_agregar(mejora, "linterna")
	_agregar(mejora, "bateria")
	var reemplazo := CombinacionObjetos.combinar(mejora, RECETAS, "bateria", "linterna")
	_comprobar(
		reemplazo["estado"] == CombinacionObjetos.ESTADO_EXITO, "permite modificar un objeto"
	)
	_comprobar(Inventario.contiene(mejora, "linterna"), "el id reemplazado vuelve materializado")
	_comprobar(not Inventario.contiene(mejora, "bateria"), "la mejora consume el accesorio")

	var incompleto := Inventario.nuevo()
	_agregar(incompleto, "documento")
	var antes := JSON.stringify(incompleto)
	var ausente := CombinacionObjetos.combinar(incompleto, RECETAS, "documento", "cinta")
	_comprobar(ausente["motivo"] == "objeto_ausente", "no combina objetos no poseídos")
	_comprobar(JSON.stringify(incompleto) == antes, "objeto ausente tampoco deja estado parcial")

	var mismo := CombinacionObjetos.previsualizar(incompleto, RECETAS, "documento", "documento")
	_comprobar(mismo["motivo"] == "mismo_objeto", "dos slots no duplican una sola instancia")

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _agregar(inventario: Dictionary, objeto_id: String) -> void:
	(
		Inventario
		. recoger(
			inventario,
			{
				"id": objeto_id,
				"nombre": objeto_id.capitalize(),
				"origen": "fixture",
				"vendible": false,
				"precio": 0,
			},
		)
	)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO CombinacionObjetos955: " + nombre)
