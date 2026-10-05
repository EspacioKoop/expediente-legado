extends SceneTree

const Catedral := preload("res://guion/catedral_invertida.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_orientaciones()
	_probar_transicion()
	_probar_reduccion_movimiento()
	_probar_anclas()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_orientaciones() -> void:
	_comprobar(Catedral.orientacion_valida(Catedral.SUELO), "acepta suelo")
	_comprobar(not Catedral.orientacion_valida("diagonal"), "rechaza orientación inventada")
	_comprobar(
		Catedral.siguiente(Catedral.SUELO) == Catedral.MURO_DERECHO,
		"primer giro lleva al muro derecho",
	)
	_comprobar(
		Catedral.siguiente(Catedral.SUELO, 2) == Catedral.TECHO,
		"dos giros llevan al techo",
	)
	_comprobar(
		Catedral.siguiente(Catedral.MURO_IZQUIERDO) == Catedral.SUELO,
		"la secuencia cierra el ciclo",
	)
	var secuencia := Catedral.secuencia_vertical()
	_comprobar(secuencia.size() == 3, "el primer vertical usa tres orientaciones")
	_comprobar(secuencia[0] == Catedral.SUELO, "el vertical parte del suelo")
	_comprobar(secuencia[2] == Catedral.TECHO, "el vertical termina invertido")


func _probar_transicion() -> void:
	var ancla := Vector3(2.0, 1.0, -3.0)
	var plan := Catedral.plan_transicion(Catedral.SUELO, Catedral.MURO_DERECHO, false, ancla)
	_comprobar(plan.get("animar", false), "el modo normal permite animación")
	_comprobar(float(plan.get("duracion", 0.0)) > 0.0, "el giro normal tiene duración")
	_comprobar(not plan.get("mover_jugador", true), "el contrato no teletransporta al jugador")
	_comprobar(not plan.get("mover_camara", true), "el contrato no fuerza la cámara")
	_comprobar(plan.get("ancla", Vector3.ZERO) == ancla, "conserva el punto de referencia")
	_comprobar(
		plan.get("rotacion_destino", Vector3.ZERO) == Vector3(0.0, 0.0, -90.0),
		"declara el giro de 90 grados esperado",
	)

	var invalido := Catedral.plan_transicion("inventado", "tambien", false)
	_comprobar(invalido.get("origen", "") == Catedral.SUELO, "normaliza origen inválido")
	_comprobar(
		invalido.get("destino", "") == Catedral.SUELO,
		"un destino inválido no cambia la orientación",
	)


func _probar_reduccion_movimiento() -> void:
	var plan := Catedral.plan_transicion(Catedral.SUELO, Catedral.TECHO, true)
	_comprobar(not plan.get("animar", true), "reducción de movimiento elimina animación")
	_comprobar(is_zero_approx(float(plan.get("duracion", -1.0))), "el corte reducido es inmediato")
	_comprobar(plan.get("modo", "") == "corte_fundido", "usa una alternativa no giratoria")
	_comprobar(
		plan.get("mantener_referencia_visual", false),
		"la referencia visual sigue siendo obligatoria",
	)


func _probar_anclas() -> void:
	var validas := {
		Catedral.SUELO: Vector3(0.0, 0.0, 0.0),
		Catedral.MURO_DERECHO: Vector3(1.0, 0.0, 0.0),
		Catedral.TECHO: Vector3(1.0, 2.0, 0.0),
		Catedral.MURO_IZQUIERDO: Vector3(0.0, 2.0, 0.0),
	}
	_comprobar(Catedral.validar_anclas(validas), "acepta una referencia para cada orientación")
	var incompletas := validas.duplicate(true)
	incompletas.erase(Catedral.TECHO)
	_comprobar(not Catedral.validar_anclas(incompletas), "rechaza referencias incompletas")
	var mal_tipo := validas.duplicate(true)
	mal_tipo[Catedral.TECHO] = "arriba"
	_comprobar(not Catedral.validar_anclas(mal_tipo), "rechaza una referencia mal tipada")

	var estado := Catedral.estado_reproducible(Catedral.TECHO, validas, true)
	_comprobar(estado.get("orientacion", "") == Catedral.TECHO, "serializa orientación estable")
	_comprobar(estado.get("anclas_validas", false), "expone validez de referencias")
	_comprobar(estado.get("reduccion_movimiento", false), "conserva preferencia de movimiento")


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO catedral invertida: " + nombre)
