extends SceneTree

const Densidad := preload("res://guion/densidad_3d.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	var espacio := {
		"bultos": [
			{"pos": Vector3.ZERO, "tam": Vector3(2, 1, 1), "modelo": "desk"},
			{"pos": Vector3(1, 0, 0), "tam": Vector3(3, 2, 1)},
			{"pos": Vector3(2, 0, 0), "tam": Vector3(1, 1, 1)},
			{"pos": Vector3(3, 0, 0), "tam": Vector3(2, 2, 1)},
		]
	}
	var informe := Densidad.auditar(espacio)
	_comprobar(informe["total"] == 4, "cuenta bultos válidos")
	_comprobar(informe["modelados"] == 1, "cuenta modelos reales")
	_comprobar(informe["proxies"] == 3, "cuenta proxies pendientes")
	_comprobar(is_equal_approx(informe["ratio_modelado"], 0.25), "calcula ratio modelado")

	var prioridad := Densidad.priorizar(espacio, 2)
	_comprobar(prioridad.size() == 2, "respeta el límite")
	_comprobar(prioridad[0]["indice"] == 1, "prioriza el proxy de mayor volumen")
	_comprobar(prioridad[1]["indice"] == 3, "mantiene orden descendente por volumen")
	_comprobar(Densidad.priorizar(espacio, 0).is_empty(), "límite cero no devuelve candidatos")
	_comprobar(Densidad.auditar({})["ratio_modelado"] == 0.0, "espacio vacío tiene ratio seguro")

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Densidad3D: " + nombre)
