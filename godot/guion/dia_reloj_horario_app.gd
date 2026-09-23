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
## Las ventanas del sitio montado. Hasta #789 el cristal era un azul de noche
## fijo aunque la jornada empiece a las nueve de la mañana: la hora se leía en
## el reloj de la pared y la ventana la contradecía.
var _cristales: Array[ShaderMaterial] = []
var _luces_ventana: Array[SpotLight3D] = []
var _objetivo_cristal := Color.BLACK
var _objetivo_ventana_color := Color.WHITE
var _objetivo_ventana_energia := 0.0


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
		_cristales.clear()
		_luces_ventana.clear()
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
			"cristal": Color(0.74, 0.80, 0.86),
			"ventana_color": Color(1.0, 0.90, 0.76),
			"ventana_energia": 5.0,
		}
	if hora < 15 * 60:
		return {
			"franja": "mediodia",
			"ambiente_factor": 1.06,
			"sol_factor": 1.08,
			"tinte": Color(0.92, 0.94, 0.96),
			"cristal": Color(0.82, 0.88, 0.94),
			"ventana_color": Color(1.0, 0.97, 0.92),
			"ventana_energia": 6.0,
		}
	if hora < 18 * 60:
		return {
			"franja": "tarde",
			"ambiente_factor": 0.96,
			"sol_factor": 0.78,
			"tinte": Color(0.96, 0.77, 0.58),
			"cristal": Color(0.92, 0.70, 0.48),
			"ventana_color": Color(1.0, 0.74, 0.50),
			"ventana_energia": 4.0,
		}
	return {
		"franja": "noche",
		"ambiente_factor": 0.82,
		"sol_factor": 0.46,
		"tinte": Color(0.63, 0.70, 0.82),
		# De noche el cristal vuelve a ser lo que el catálogo declaró siempre y
		# por él no entra nada: no se inventa sol para que la sala luzca más.
		"cristal": Color(0.09, 0.11, 0.20),
		"ventana_color": Color(0.63, 0.70, 0.82),
		"ventana_energia": 0.0,
	}


func _montar(dia: Node, mundo: Node3D) -> void:
	_reloj = RelojOficina3D.new()
	_reloj.name = "RelojJornadaOficina"
	_reloj.position = POSICION_RELOJ
	mundo.add_child(_reloj)
	_buscar_ventanas(mundo)
	_actualizar_objetivos(dia, Jornada.hora_minutos(dia.jornada))
	# Al entrar la ventana ya está como corresponde: fundirse desde la noche
	# en cada entrada sería un amanecer que no ha ocurrido.
	_transicionar_ventanas(1.0)


func _buscar_ventanas(mundo: Node3D) -> void:
	_cristales.clear()
	_luces_ventana.clear()
	for cristal in mundo.find_children(Espacio3D.NOMBRE_CRISTAL_VENTANA + "*", "", true, false):
		for hijo in cristal.get_children():
			if hijo is MeshInstance3D and hijo.material_override is ShaderMaterial:
				_cristales.append(hijo.material_override)
	for luz in mundo.find_children(Espacio3D.NOMBRE_LUZ_VENTANA + "*", "SpotLight3D", true, false):
		_luces_ventana.append(luz)


func _actualizar_objetivos(dia: Node, hora: int) -> void:
	_hora_aplicada = hora
	_reloj.poner_hora(hora)

	var perfil: Dictionary = perfil_luz(hora)
	var espacio: Dictionary = dia._espacio_actual
	var color_base: Color = espacio.get("ambiente", Color(0.55, 0.55, 0.58))
	var energia_base := float(espacio.get("ambiente_energia", 0.7))
	var sol_base := float(espacio.get("sol", 0.7))
	var tinte: Color = perfil["tinte"]
	_objetivo_color = color_base.lerp(tinte, MEZCLA_TINTE)
	_objetivo_ambiente = energia_base * float(perfil["ambiente_factor"])
	_objetivo_sol = sol_base * float(perfil["sol_factor"])
	_objetivo_cristal = perfil["cristal"]
	_objetivo_ventana_color = perfil["ventana_color"]
	_objetivo_ventana_energia = float(perfil["ventana_energia"])


func _transicionar_luz(dia: Node, delta: float) -> void:
	var factor := clampf(delta * VELOCIDAD_TRANSICION, 0.0, 1.0)
	_transicionar_ventanas(factor)
	if dia._ambiente == null or dia._sol == null:
		return
	dia._ambiente.ambient_light_color = dia._ambiente.ambient_light_color.lerp(
		_objetivo_color, factor
	)
	dia._ambiente.ambient_light_energy = lerpf(
		dia._ambiente.ambient_light_energy, _objetivo_ambiente, factor
	)
	dia._sol.light_energy = lerpf(dia._sol.light_energy, _objetivo_sol, factor)


func _transicionar_ventanas(factor: float) -> void:
	for material in _cristales:
		var actual: Color = material.get_shader_parameter("emision")
		material.set_shader_parameter("emision", actual.lerp(_objetivo_cristal, factor))
	for luz in _luces_ventana:
		if not is_instance_valid(luz):
			continue
		luz.light_color = luz.light_color.lerp(_objetivo_ventana_color, factor)
		luz.light_energy = lerpf(luz.light_energy, _objetivo_ventana_energia, factor)
		# Apagada del todo no se dibuja: una luz a energía casi nula seguiría
		# pagando su pasada de sombra para no alumbrar nada.
		luz.visible = luz.light_energy > 0.01
