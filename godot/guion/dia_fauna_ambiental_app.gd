## Integración de fauna ambiental con el día real (#1396).
##
## Observa el mundo ya montado, igual que otras capas aditivas. Solo actúa en la
## calle y en el sueño; la casa conserva al gato sistémico de #787 como animal
## con contrato propio.
extends Node

var _mundo_id := 0
var _capa: FaunaAmbiental3D = null


func _process(_delta: float) -> void:
	var dia = get_parent()
	if dia == null or dia._mundo == null:
		return
	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_id:
		return
	_mundo_id = mundo_id
	_capa = null

	var fase := String(dia.jornada.get("fase", ""))
	if fase != FaunaAmbiental.FASE_CALLE and fase != FaunaAmbiental.FASE_SUENO:
		return

	var contexto := ""
	if fase == FaunaAmbiental.FASE_SUENO:
		var escenas: Array = dia.jornada.get("sueno_escenas", [])
		if not escenas.is_empty():
			contexto = String(escenas[0])

	var animador: AnimadorAmbiental3D = dia.animador_ambiental()
	animador.semilla = int(dia.jornada.get("dia", 1))
	var clima := ""
	if fase == FaunaAmbiental.FASE_CALLE:
		clima = String(dia.jornada.get("clima_forzado", ""))
		if clima.is_empty():
			clima = Clima.estado(int(dia.jornada.get("dia", 1)))
	var franja := Jornada.franja_horaria(dia.jornada)

	_capa = FaunaAmbiental3D.new()
	_capa.name = "FaunaAmbiental"
	mundo.add_child(_capa)
	(
		_capa
		. montar(
			fase,
			dia._espacio_actual,
			int(dia.jornada.get("dia", 1)),
			dia._raiz(),
			contexto,
			animador,
			bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false)),
			clima,
			franja,
		)
	)
