## Presentación horaria diegética de la oficina (#963).
##
## Consume Jornada como única fuente de verdad. El reloj mural y la luz reaccionan
## cuando cambia hora_minutos, pero este controller nunca adelanta el tiempo ni
## decide disponibilidad, progreso o economía.
extends Node

const POSICION_RELOJ := Vector3(2.25, 2.25, -4.76)
const MEZCLA_TINTE := 0.14
const VELOCIDAD_TRANSICION := 2.4

var _mundo_id := 0
var _reloj: RelojOficina3D
var _hora_aplicada := -1
var _objetivo_ambiente := 0.0
var _objetivo_sol := 0.0
var _objetivo_color := Color.WHITE


func _process(delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id != _mundo_id:
		_mundo_id = mundo_id
		_reloj = null
		_hora_aplicada = -1
		if String(dia.jornada.get("fase", "")) == "archivo":
			_montar(dia, mundo)

	if String(dia.jornada.get("fase", "")) != "archivo":
		return
	if not is_instance_valid(_reloj):
		_montar(dia, mundo)

	var hora := Jornada.hora_minutos(dia.jornada)
	if hora != _hora_aplicada:
		_actualizar_objetivos(dia, hora)
	_transicionar_luz(dia, delta)


## Perfil discreto. La transición visual entre perfiles sí es suave, pero nunca
## crea minutos intermedios que Jornada no haya decidido.
static func perfil_luz(minutos: int) -> Dictionary:
	var hora := posmod(minutos, 24 * 60)
	if hora < 11 * 60:
		return {
			"franja": "manana",
			"ambiente_factor": 0.94,
			"sol_factor": 0.82,
			"tinte": Color(0.95, 0.86, 0.72),
		}
	if hora < 15 * 60:
		return {
			"franja": "mediodia",
			"ambiente_factor": 1.06,
			"sol_factor": 1.08,
			"tinte": Color(0.92, 0.94, 0.96),
		}
	if hora < 18 * 60:
		return {
			"franja": "tarde",
			"ambiente_factor": 0.96,
			"sol_factor": 0.78,
			"tinte": Color(0.96, 0.77, 0.58),
		}
	return {
		"franja": "noche",
		"ambiente_factor": 0.82,
		"sol_factor": 0.46,
		"tinte": Color(0.63, 0.70, 0.82),
	}


func _montar(dia: Node, mundo: Node3D) -> void:
	_reloj = RelojOficina3D.new()
	_reloj.name = "RelojJornadaOficina"
	_reloj.position = POSICION_RELOJ
	mundo.add_child(_reloj)
	_actualizar_objetivos(dia, Jornada.hora_minutos(dia.jornada))


func _actualizar_objetivos(dia: Node, hora: int) -> void:
	_hora_aplicada = hora
	_reloj.poner_hora(hora)

	var perfil := perfil_luz(hora)
	var espacio: Dictionary = dia._espacio_actual
	var color_base: Color = espacio.get("ambiente", Color(0.55, 0.55, 0.58))
	var energia_base := float(espacio.get("ambiente_energia", 0.7))
	var sol_base := float(espacio.get("sol", 0.7))
	_objetivo_color = color_base.lerp(perfil["tinte"], MEZCLA_TINTE)
	_objetivo_ambiente = energia_base * float(perfil["ambiente_factor"])
	_objetivo_sol = sol_base * float(perfil["sol_factor"])


func _transicionar_luz(dia: Node, delta: float) -> void:
	if dia._ambiente == null or dia._sol == null:
		return
	var factor := clampf(delta * VELOCIDAD_TRANSICION, 0.0, 1.0)
	dia._ambiente.ambient_light_color = dia._ambiente.ambient_light_color.lerp(
		_objetivo_color, factor
	)
	dia._ambiente.ambient_light_energy = lerpf(
		dia._ambiente.ambient_light_energy, _objetivo_ambiente, factor
	)
	dia._sol.light_energy = lerpf(dia._sol.light_energy, _objetivo_sol, factor)
