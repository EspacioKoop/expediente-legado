## Regresión del Falso Luminar (#2089 / #2397).
extends SceneTree

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const RUNTIME = preload("res://guion/juicio_combate_luminar_runtime_2089.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_ciclo_completo()
	_probar_determinismo_y_no_mutacion()
	print("pruebas_luminar_2089: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_ciclo_completo() -> void:
	var estado := RUNTIME.nuevo(2089)
	_comprobar(String(estado.get("fase", "")) == RUNTIME.FASE_SENUELO, "empieza en señuelo")

	var pasos_senuelo: Array = []
	for _paso in range(4):
		var salida := RUNTIME.avanzar(estado, 1.0, _contexto_hostigador())
		_comprobar(not bool(salida.get("ataque_real", false)), "el señuelo nunca aplica ataque real")
		_comprobar(
			not (
				bool(salida.get("senal_senuelo", false))
				and bool(salida.get("ataque_real", false))
			),
			"señuelo y ataque real nunca son simultáneos",
		)
		pasos_senuelo.append(salida)
		estado = salida["estado"]

	_comprobar(bool(pasos_senuelo[0].get("senal_senuelo", false)), "el primer tick muestra señuelo")
	_comprobar(
		String(pasos_senuelo[0].get("telegraph", "")) == RUNTIME.PATRON_SENUELO,
		"el señuelo anuncia línea",
	)
	_comprobar(bool(pasos_senuelo[1].get("senal_senuelo", false)), "la repetición sigue visible")
	_comprobar(
		bool(pasos_senuelo[2].get("ventana_respuesta", false)),
		"la recuperación mimética abre ventana",
	)
	_comprobar(
		String(estado.get("fase", "")) == RUNTIME.FASE_ATAQUE,
		"solo tras recuperar cambia a HOSTIGADOR",
	)

	var primer_ataque := RUNTIME.avanzar(estado, 0.0, _contexto_hostigador())
	_comprobar(not bool(primer_ataque.get("senal_senuelo", false)), "el ataque real oculta el señuelo")
	_comprobar(not bool(primer_ataque.get("ataque_real", false)), "el primer tick solo telegrafía")
	estado = primer_ataque["estado"]

	var disparo := RUNTIME.avanzar(estado, 1.0, _contexto_hostigador())
	_comprobar(bool(disparo.get("ataque_real", false)), "DISPARAR_LINEA es el único ataque real")
	_comprobar(
		String(disparo.get("telegraph", "")) == "linea",
		"el ataque real conserva telegraph de línea",
	)
	_comprobar(not bool(disparo.get("senal_senuelo", false)), "el disparo no reactiva el señuelo")
	estado = disparo["estado"]

	var vulnerable := RUNTIME.avanzar(estado, 1.0, _contexto_hostigador())
	_comprobar(not bool(vulnerable.get("ataque_real", false)), "vulnerable ya no dispara")
	_comprobar(bool(vulnerable.get("ventana_respuesta", false)), "vulnerable abre respuesta")
	estado = vulnerable["estado"]

	var vuelta := RUNTIME.avanzar(estado, 1.0, _contexto_hostigador())
	estado = vuelta["estado"]
	_comprobar(String(estado.get("fase", "")) == RUNTIME.FASE_SENUELO, "vuelve a señuelo")
	_comprobar(int(estado.get("ciclos", 0)) == 1, "cuenta un ciclo completo")
	_comprobar(not bool(vuelta.get("ataque_real", false)), "la vuelta no añade ataque residual")


func _probar_determinismo_y_no_mutacion() -> void:
	var estado := RUNTIME.nuevo(123)
	var antes := estado.duplicate(true)
	var contexto := _contexto_hostigador()
	var a := RUNTIME.avanzar(estado, 0.5, contexto)
	var b := RUNTIME.avanzar(antes.duplicate(true), 0.5, contexto)
	_comprobar(a == b, "misma entrada produce la misma salida")
	_comprobar(estado == antes, "avanzar no muta la entrada")
	for prohibido in ("dano", "partida", "jornada", "spawn"):
		_comprobar(not a.has(prohibido), "no crea autoridad " + prohibido)


func _contexto_hostigador() -> Dictionary:
	return {
		"distancia": 6.0,
		"rumbo_objetivo": 0.0,
	}


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if not condicion:
		_fallos += 1
		push_error("FALLO #2397 Falso Luminar: " + mensaje)
