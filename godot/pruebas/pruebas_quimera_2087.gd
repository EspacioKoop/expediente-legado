## Regresión de Quimera ciclo y determinismo (#2087)
extends SceneTree

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const RUNTIME = preload("res://guion/juicio_combate_quimera_runtime_2087.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_estado_inicial()
	_probar_secuencia_ciclos()
	_probar_determinismo()
	print("pruebas_quimera_2087: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_estado_inicial() -> void:
	var estado := RUNTIME.nuevo(2087)
	var unidad: Dictionary = estado["unidad"]
	_comprobar(String(unidad.get("tipo", "")) == ARQUETIPOS.EMBESTIDOR, "inicia en EMBESTIDOR")
	_comprobar(
		String(estado.get("patron_actual", "")) == ARQUETIPOS.EMBESTIDOR,
		"patrón actual es EMBESTIDOR"
	)


func _probar_secuencia_ciclos() -> void:
	# Esperamos tres ciclos completos y verificamos que el patrón avanza determinísticamente
	var patrones_esperados := [
		ARQUETIPOS.EMBESTIDOR, ARQUETIPOS.HOSTIGADOR, ARQUETIPOS.BLOQUEADOR, ARQUETIPOS.EMBESTIDOR
	]
	var indice := 0
	while indice < patrones_esperados.size() - 1:
		var estado := RUNTIME.nuevo(2087)
		var patron_actual := String(estado["patron_actual"])
		_comprobar(
			patron_actual == patrones_esperados[indice],
			"patrón inicial correcto %s" % patron_actual
		)
		var cambio := false
		while not cambio:
			var contexto := _contexto_para_patron(patron_actual)
			var resultado := RUNTIME.avanzar(estado, 0.5, contexto)
			cambio = resultado.get("cambio_patron", false)
			estado = resultado.get("estado", estado)
			patron_actual = String(estado.get("patron_actual", ""))
		_comprobar(cambio, "cambio de patrón detectado")
		_comprobar(
			patron_actual == patrones_esperados[indice + 1], "patrón avanzado a %s" % patron_actual
		)
		indice += 1


func _probar_determinismo() -> void:
	# Mismo estado + mismo contexto debe generar salida idéntica y no mutar el estado de entrada
	var estado_original := RUNTIME.nuevo(2087)
	var copia := estado_original.duplicate(true)
	var contexto := _contexto_para_patron(String(estado_original["patron_actual"]))
	var salida_a := RUNTIME.avanzar(estado_original, 0.5, contexto)
	var salida_b := RUNTIME.avanzar(copia, 0.5, contexto)
	_comprobar(salida_a == salida_b, "salida idéntica para mismo input")
	_comprobar(estado_original == RUNTIME.nuevo(2087), "estado de entrada no mutable")


func _contexto_para_patron(patron: String) -> Dictionary:
	match patron:
		ARQUETIPOS.EMBESTIDOR:
			return {"distancia": 5.0, "linea_libre": true, "choque": false}
		ARQUETIPOS.HOSTIGADOR:
			return {"distancia": 6.0, "rumbo_objetivo": 0.0}
		ARQUETIPOS.BLOQUEADOR:
			return {"flanqueado": true}
		_:
			return {}


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if not condicion:
		_fallos += 1
		push_error("FALLO #2087 Quimera: " + mensaje)
