## Pruebas aisladas del montaje de presentación de Crónicas (#2589).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	_sin_climax()
	_fallback_sin_juego()
	_cuatro_capas_con_visitas()
	_no_deducir_visitas_ni_modificar_estado()
	_respeta_vuelta_y_fases()
	print("Crónicas 2589: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _estado_iniciado() -> Dictionary:
	var estado := Partida.nueva()
	var jornada: Dictionary = estado["jornada"]
	jornada["raiz"] = 2589
	jornada["vuelta"] = 1
	var resultado := (
		ClimaxHastur
		. iniciar(
			estado,
			jornada,
			{"climax_hastur_pendiente": true},
		)
	)
	_comprobar(resultado.get("resultado") == "iniciado", "el dueño canónico inicia el clímax")
	return estado


func _sin_climax() -> void:
	var estado := Partida.nueva()
	var jornada: Dictionary = estado["jornada"]
	var original := JSON.stringify(estado)
	_comprobar(
		CronicasSieteEsferasMontaje.plan(estado, jornada).is_empty(),
		"sin handoff no aparece montaje ni se crea clímax",
	)
	_comprobar(JSON.stringify(estado) == original, "plan no escribe estado")


func _fallback_sin_juego() -> void:
	var estado := _estado_iniciado()
	var jornada: Dictionary = estado["jornada"]
	var secuencia := CronicasSieteEsferasMontaje.plan(estado, jornada)
	_comprobar(
		secuencia.get("capas", []) == ["os98", "vigilia"],
		"sin jugar Crónicas permanece la ruta canónica offline",
	)
	_comprobar(secuencia.get("modo") == "combate", "combate canónico inalterado")
	_comprobar(secuencia.get("resolucion_propietario") == "ClimaxHastur", "un dueño")


func _cuatro_capas_con_visitas() -> void:
	var estado := _estado_iniciado()
	var jornada: Dictionary = estado["jornada"]
	var secuencia := (
		CronicasSieteEsferasMontaje
		. plan(
			estado,
			jornada,
			{
				"cronicas_jugadas": true,
				"sueno_cronicas_visto": true,
			},
		)
	)
	_comprobar(
		secuencia.get("capas", []) == ["os98", "sueno", "cronicas", "vigilia"],
		"las cuatro capas siguen un orden fijo",
	)
	_comprobar(bool(secuencia.get("presentacion_solamente")), "ninguna capa resuelve combate")


func _no_deducir_visitas_ni_modificar_estado() -> void:
	var estado := _estado_iniciado()
	var jornada: Dictionary = estado["jornada"]
	var original := JSON.stringify(estado)
	var visitas := {"cronicas_jugadas": false, "sueno_cronicas_visto": true, "otra": true}
	var visitas_original := JSON.stringify(visitas)
	var uno := CronicasSieteEsferasMontaje.plan(estado, jornada, visitas)
	var dos := CronicasSieteEsferasMontaje.plan(estado, jornada, visitas)
	_comprobar(uno == dos, "plan determinista sin contador interno")
	_comprobar(uno.get("capas", []) == ["os98", "sueno", "vigilia"], "sin capa no visitada")
	_comprobar(JSON.stringify(estado) == original, "estado canónico intacto")
	_comprobar(JSON.stringify(visitas) == visitas_original, "visitas intactas")


func _respeta_vuelta_y_fases() -> void:
	var estado := _estado_iniciado()
	var jornada: Dictionary = estado["jornada"]
	var anterior := jornada.duplicate(true)
	anterior["vuelta"] = 2
	_comprobar(
		CronicasSieteEsferasMontaje.plan(estado, anterior).is_empty(),
		"otra vuelta no hereda el montaje",
	)
	var actual: Dictionary = estado[ClimaxHastur.CLAVE_ESTADO]
	actual["fase"] = ClimaxHastur.FASE_FINAL
	_comprobar(
		CronicasSieteEsferasMontaje.plan(estado, jornada).get("modo") == "epilogo",
		"final existente se presenta, no se recombate",
	)
	actual["fase"] = ClimaxHastur.FASE_INTERRUMPIDO
	_comprobar(
		CronicasSieteEsferasMontaje.plan(estado, jornada).is_empty(),
		"interrupción no crea clímax alternativo",
	)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("Crónicas 2589: " + nombre)
