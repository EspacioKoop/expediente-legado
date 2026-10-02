extends SceneTree

const Rodeo := preload("res://guion/juicio_combate_obstaculo_1772.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_camino_directo()
	_probar_rodeo_estable()
	_probar_semilla_cambia_lado()
	_probar_borde_arena()
	_probar_objetivo_ocupado_espera()
	_probar_obstaculo_desaparece()
	print("combate_obstaculo_1772: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_camino_directo() -> void:
	var resultado := (
		Rodeo
		. planear(
			Vector3(-3.0, 0.0, -2.0),
			Vector3(3.0, 0.0, -2.0),
			5.0,
			_obstaculo(Vector3.ZERO, 0.7),
			10,
		)
	)
	_comprobar(String(resultado["intencion"]) == "directo", "camino libre sigue directo")
	_comprobar(not bool(resultado["bloqueado_directo"]), "camino libre no marca bloqueo")
	_comprobar(float((resultado["direccion"] as Vector3).x) > 0.9, "directo apunta al objetivo")


func _probar_rodeo_estable() -> void:
	var origen := Vector3(-3.0, 0.0, 0.0)
	var objetivo := Vector3(3.0, 0.0, 0.0)
	var obstaculo := _obstaculo(Vector3.ZERO, 0.7)
	var primero := Rodeo.planear(origen, objetivo, 5.0, obstaculo, 10)
	_comprobar(String(primero["intencion"]) == "rodear", "bloqueo frontal fuerza rodeo")
	_comprobar(int(primero["lado"]) == 1, "semilla par fija un lado")
	var destino: Vector3 = primero["destino"]
	_comprobar(
		not (
			Rodeo
			. segmento_bloqueado(
				Vector2(origen.x, origen.z),
				Vector2(destino.x, destino.z),
				Vector2.ZERO,
				0.7,
			)
		),
		"el primer tramo no entra en el volumen bloqueado",
	)

	var direccion: Vector3 = primero["direccion"]
	var segundo_origen := origen + direccion * 0.4
	var segundo := Rodeo.planear(segundo_origen, objetivo, 5.0, obstaculo, 10)
	_comprobar(String(segundo["intencion"]) == "rodear", "segundo tick sigue rodeando")
	_comprobar(int(segundo["lado"]) == int(primero["lado"]), "dos ticks no cambian de lado")


func _probar_semilla_cambia_lado() -> void:
	var origen := Vector3(-3.0, 0.0, 0.0)
	var objetivo := Vector3(3.0, 0.0, 0.0)
	var obstaculo := _obstaculo(Vector3.ZERO, 0.7)
	var par := Rodeo.planear(origen, objetivo, 5.0, obstaculo, 10)
	var impar := Rodeo.planear(origen, objetivo, 5.0, obstaculo, 11)
	_comprobar(int(par["lado"]) == 1, "semilla par usa lado positivo")
	_comprobar(int(impar["lado"]) == -1, "semilla impar usa lado negativo")
	var destino_par: Vector3 = par["destino"]
	var destino_impar: Vector3 = impar["destino"]
	_comprobar(destino_par.z * destino_impar.z < 0.0, "ambas rutas rodean por lados opuestos")


func _probar_borde_arena() -> void:
	var resultado := (
		Rodeo
		. planear(
			Vector3.ZERO,
			Vector3(2.9, 0.0, 0.0),
			3.0,
			_obstaculo(Vector3(2.0, 0.0, 0.0), 0.5),
			10,
		)
	)
	_comprobar(String(resultado["intencion"]) == "rodear", "cerca del borde aún busca paso")
	var destino: Vector3 = resultado["destino"]
	_comprobar(Vector2(destino.x, destino.z).length() <= 3.001, "el rodeo queda dentro de arena")


func _probar_objetivo_ocupado_espera() -> void:
	var resultado := (
		Rodeo
		. planear(
			Vector3(-2.0, 0.0, 0.0),
			Vector3(0.2, 0.0, 0.0),
			5.0,
			_obstaculo(Vector3.ZERO, 0.7),
			10,
		)
	)
	_comprobar(String(resultado["intencion"]) == "esperar", "no persigue dentro del obstaculo")
	_comprobar(
		(resultado["direccion"] as Vector3).is_zero_approx(), "esperar no inyecta movimiento"
	)


func _probar_obstaculo_desaparece() -> void:
	var obstaculo := _obstaculo(Vector3.ZERO, 0.7)
	var bloqueado := (
		Rodeo
		. planear(
			Vector3(-3.0, 0.0, 0.0),
			Vector3(3.0, 0.0, 0.0),
			5.0,
			obstaculo,
			10,
		)
	)
	_comprobar(String(bloqueado["intencion"]) == "rodear", "obstaculo activo se evita")
	obstaculo["activo"] = false
	var libre := (
		Rodeo
		. planear(
			Vector3(-3.0, 0.0, 0.0),
			Vector3(3.0, 0.0, 0.0),
			5.0,
			obstaculo,
			10,
		)
	)
	_comprobar(String(libre["intencion"]) == "directo", "al expirar vuelve a ruta directa")


func _obstaculo(centro: Vector3, radio: float) -> Dictionary:
	return {"activo": true, "centro": centro, "radio": radio}


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error("FALLO #2137: " + mensaje)
