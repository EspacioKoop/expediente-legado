extends SceneTree

const Continuidad := preload("res://guion/continuidad_onirica.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_lucidez()
	_probar_allowlist_y_origen()
	_probar_determinismo()
	_probar_aplicacion_no_invasiva()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_lucidez() -> void:
	var contrato := {
		"acciones_lucidas":
		[
			{"id": "puerta_imposible", "nivel_minimo": 1, "tipo": "revelar_ruta"},
			{"id": "negar_transicion", "nivel_minimo": 2, "tipo": "cancelar_transicion"},
		]
	}
	_comprobar(Continuidad.accion_lucida(0, contrato).is_empty(), "sin lucidez no concede acciones")
	var baja := Continuidad.accion_lucida(1, contrato)
	_comprobar(baja.get("id", "") == "puerta_imposible", "lucidez baja habilita la acción básica")
	_comprobar(not baja.get("afecta_estado_global", true), "la acción no es autoridad global")
	var alta := Continuidad.accion_lucida(2, contrato)
	_comprobar(alta.get("id", "") == "negar_transicion", "lucidez alta prioriza la capacidad mayor")
	_comprobar(
		Continuidad.accion_lucida(2, {"acciones_lucidas": "mal"}).is_empty(),
		"rechaza contratos de acciones mal tipados",
	)


func _motivos() -> Array:
	return [
		{
			"id": "rama_yggdrasil",
			"origen": "yggdrasil",
			"destinos": ["duat", "hidra"],
			"presentacion": {"prop": "rama"},
		},
		{
			"id": "escama_hidra",
			"origen": "hidra",
			"destinos": ["duat"],
			"presentacion": {"prop": "escama"},
		},
		{
			"id": "pluma_duat",
			"origen": "duat",
			"destinos": ["hidra"],
			"presentacion": {"prop": "pluma"},
		},
	]


func _probar_allowlist_y_origen() -> void:
	var elegidos := Continuidad.seleccionar_motivos(
		_motivos(), "duat", 77, ["rama_yggdrasil", "escama_hidra"]
	)
	_comprobar(elegidos.size() == 1, "primer corte limita la contaminación a un motivo")
	_comprobar(
		["rama_yggdrasil", "escama_hidra"].has(elegidos[0].get("id", "")),
		"solo selecciona ids permitidos por el receptor",
	)
	_comprobar(elegidos[0].get("origen", "") != "duat", "nunca importa un motivo del mismo sueño")
	_comprobar(
		Continuidad.seleccionar_motivos(_motivos(), "duat", 77, ["pluma_duat"]).is_empty(),
		"respeta la allowlist de destinos declarada por el motivo",
	)
	_comprobar(
		Continuidad.seleccionar_motivos(_motivos(), "", 77, []).is_empty(),
		"rechaza un destino vacío",
	)
	_comprobar(
		Continuidad.seleccionar_motivos(_motivos(), "duat", 77, [], 0).is_empty(),
		"cantidad cero desactiva el sistema",
	)


func _probar_determinismo() -> void:
	var a := Continuidad.seleccionar_motivos(_motivos(), "duat", 991, [])
	var invertidos := _motivos()
	invertidos.reverse()
	var b := Continuidad.seleccionar_motivos(invertidos, "duat", 991, [])
	_comprobar(a == b, "mismo seed y catálogo produce la misma intrusión")
	_comprobar(a.size() == 1, "sin allowlist respeta el máximo del primer corte")
	var dos := Continuidad.seleccionar_motivos(_motivos(), "duat", 991, [], 2)
	_comprobar(dos.size() == 2, "el contrato admite ampliar el máximo explícitamente")
	_comprobar(dos[0].get("id", "") != dos[1].get("id", ""), "no duplica motivos por ejecución")

	var duplicados := _motivos()
	duplicados.append(_motivos()[0])
	var sin_duplicar := Continuidad.seleccionar_motivos(duplicados, "duat", 991, [], 3)
	var ids: Array[String] = []
	for motivo in sin_duplicar:
		ids.append(String(motivo.get("id", "")))
	_comprobar(ids.count("rama_yggdrasil") <= 1, "deduplica ids repetidos")


func _probar_aplicacion_no_invasiva() -> void:
	var espacio := {
		"planta": [Vector2i(0, 0), Vector2i(1, 0)],
		"entrada": Vector3.ZERO,
		"salidas": [{"destino": "archivo"}],
		"objetivos": ["salir"],
	}
	var original := espacio.duplicate(true)
	var seleccion := Continuidad.seleccionar_motivos(
		_motivos(), "duat", 123, ["rama_yggdrasil", "escama_hidra"]
	)
	var aplicado := Continuidad.aplicar(espacio, seleccion)
	_comprobar(espacio == original, "aplicar no muta el espacio recibido")
	_comprobar(aplicado.get("planta", []) == original["planta"], "conserva la navegación")
	_comprobar(aplicado.get("salidas", []) == original["salidas"], "conserva las salidas")
	_comprobar(aplicado.get("objetivos", []) == original["objetivos"], "conserva los objetivos")
	var contaminacion: Array = aplicado.get("contaminacion_onirica", [])
	_comprobar(contaminacion.size() == 1, "adjunta una única metadata de contaminación")
	_comprobar(
		not contaminacion[0].get("afecta_navegacion", true),
		"la metadata no cambia navegación",
	)
	_comprobar(
		not contaminacion[0].get("afecta_objetivo", true),
		"la metadata no cambia el objetivo",
	)
	_comprobar(
		Continuidad.aplicar(espacio, []) == espacio,
		"una selección vacía deja el contrato base intacto",
	)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO continuidad onírica: " + nombre)
