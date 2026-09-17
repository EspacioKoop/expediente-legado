## Feedback 3D para los estados activos de los rituales del Juicio (#779).
##
## No modifica reglas ni temporizadores: observa `JuicioCombate3D` después de su
## `_process` y traduce tres estados ya existentes a geometría estática. Así las
## señales siguen siendo legibles con reducción de movimiento.
class_name JuicioFeedbackRitual
extends Node3D

const DURACION_DESTELLO_SOL := 0.35

var _host: Node
var _destello_sol := 0.0
var _pendiente_previo := false
var _determinacion_previa := -1
var _sol: Node3D
var _anansi: Node3D
var _hidra: Node3D


static func montar(raiz: Node3D) -> JuicioFeedbackRitual:
	var feedback := JuicioFeedbackRitual.new()
	feedback.name = "FeedbackRitualActivo"
	feedback._host = raiz
	# El combate usa la prioridad por defecto. Leer después evita dibujar el
	# estado del frame anterior cuando una interrupción o retorno acaba de ocurrir.
	feedback.process_priority = 10
	raiz.add_child(feedback)
	return feedback


static func estado_visual(
	ritual_id: String,
	enredo: float,
	retornos: int,
	determinacion: int,
	pendiente_previo: bool,
	pendiente: bool,
	determinacion_previa: int,
) -> Dictionary:
	return {
		"sol":
		(
			ritual_id == "robo_del_sol"
			and pendiente_previo
			and not pendiente
			and determinacion_previa >= 0
			and determinacion < determinacion_previa
		),
		"anansi": ritual_id == "nudo_suspendido" and enredo > 0.0,
		"hidra": ritual_id == "retorno_hidra" and retornos > 0 and determinacion > 0,
	}


func _ready() -> void:
	_sol = _montar_sol()
	_anansi = _montar_anansi()
	_hidra = _montar_hidra()
	add_child(_sol)
	add_child(_anansi)
	add_child(_hidra)
	_sol.visible = false
	_anansi.visible = false
	_hidra.visible = false


func _process(delta: float) -> void:
	if _host == null or not is_instance_valid(_host):
		return
	var ritual_bruto = _host.get("_ritual")
	if typeof(ritual_bruto) != TYPE_DICTIONARY:
		return
	var ritual: Dictionary = ritual_bruto
	var ritual_id := String(ritual.get("id", ""))
	var pendiente := bool(_host.get("_ataque_rival_pendiente"))
	var determinacion := int(_host.get("_determinacion_rival"))
	var enredo := float(_host.get("_enredo"))
	var retornos := int(_host.get("_retornos_rival"))
	var estado := estado_visual(
		ritual_id,
		enredo,
		retornos,
		determinacion,
		_pendiente_previo,
		pendiente,
		_determinacion_previa,
	)
	if bool(estado["sol"]):
		_destello_sol = DURACION_DESTELLO_SOL
	else:
		_destello_sol = maxf(0.0, _destello_sol - delta)

	var rival_bruto = _host.get("_rival")
	if rival_bruto is Node3D:
		position = rival_bruto.position
	_sol.visible = ritual_id == "robo_del_sol" and _destello_sol > 0.0
	_anansi.visible = bool(estado["anansi"])
	_hidra.visible = bool(estado["hidra"])
	_pendiente_previo = pendiente
	_determinacion_previa = determinacion


func _montar_sol() -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "DestelloRoboSol"
	var color := Color(0.88, 0.66, 0.19, 0.42)
	var disco := MeshInstance3D.new()
	var malla := CylinderMesh.new()
	malla.top_radius = 1.85
	malla.bottom_radius = 1.85
	malla.height = 0.035
	malla.radial_segments = 32
	disco.mesh = malla
	disco.position.y = 0.035
	disco.material_override = _material(color, true)
	raiz.add_child(disco)
	for i in 8:
		var rayo := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = Vector3(1.0, 0.045, 0.08)
		rayo.mesh = caja
		var angulo := TAU * float(i) / 8.0
		rayo.position = Vector3(cos(angulo) * 2.15, 0.055, sin(angulo) * 2.15)
		rayo.rotation.y = -angulo
		rayo.material_override = _material(color, true)
		raiz.add_child(rayo)
	return raiz


func _montar_anansi() -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "EnredoAnansi"
	var color := Color(0.45, 0.29, 0.50, 0.72)
	for i in 6:
		var hilo := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = Vector3(2.45, 0.045, 0.055)
		hilo.mesh = caja
		hilo.position.y = 0.08 + 0.035 * float(i % 2)
		hilo.rotation.y = TAU * float(i) / 6.0
		hilo.material_override = _material(color, true)
		raiz.add_child(hilo)
	return raiz


func _montar_hidra() -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "SegundaFaseHidra"
	var color := Color(0.27, 0.55, 0.31, 0.82)
	var halo := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = 1.28
	disco.bottom_radius = 1.28
	disco.height = 0.04
	disco.radial_segments = 24
	halo.mesh = disco
	halo.position.y = 0.05
	halo.material_override = _material(color, true)
	raiz.add_child(halo)
	for i in 3:
		var cabeza := MeshInstance3D.new()
		var esfera := SphereMesh.new()
		esfera.radius = 0.18
		esfera.height = 0.36
		cabeza.mesh = esfera
		cabeza.position = Vector3(-0.48 + 0.48 * float(i), 1.75 + 0.16 * float(i % 2), 0.0)
		cabeza.material_override = _material(color, true)
		raiz.add_child(cabeza)
	return raiz


func _material(color: Color, emision: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if emision:
		material.emission_enabled = true
		material.emission = Color(color.r, color.g, color.b)
		material.emission_energy_multiplier = 0.9
	return material
