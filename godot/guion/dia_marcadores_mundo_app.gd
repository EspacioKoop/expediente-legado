## Integra los marcadores persistentes de #957 en el mundo activo de Dia.
##
## Este primer vertical no captura input ni decide dónde debe apuntar el jugador:
## expone operaciones para la futura UI y restaura lo ya guardado cada vez que
## Dia reconstruye archivo, trayecto, casa o sueño.
class_name DiaMarcadoresMundoApp
extends Node

const NOMBRE_RAIZ := "MarcadoresMundoPersistentes"

var _host
var _mundo_id := 0
var _firma := ""
var _estres_presentacion := 0.0


func _ready() -> void:
	_host = get_parent()


func _process(_delta: float) -> void:
	if _host == null or not is_instance_valid(_host):
		return
	if _host.jornada.is_empty() or _host._mundo == null:
		return

	var mundo: Node3D = _host._mundo
	var zona := zona_actual()
	if zona.is_empty():
		return

	var marcadores := MarcadoresMundo.listar(_host.jornada, zona)
	var firma := JSON.stringify(marcadores) + "|%s|%.3f" % [zona, _estres_presentacion]
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_id and firma == _firma:
		return

	_mundo_id = mundo_id
	_firma = firma
	_remontar(mundo, marcadores)


func zona_actual() -> String:
	if _host == null or not is_instance_valid(_host):
		return ""
	return String(_host.jornada.get("fase", "")).strip_edges()


## Las posiciones son locales al mundo de la fase activa. El segundo corte de
## #957 resolverá el raycast/superficie desde la UI; aquí no se inventa input.
func colocar(
	tipo: String,
	color: String,
	texto: String,
	posicion: Vector3,
	normal: Vector3,
	solo_sueno := false,
) -> Dictionary:
	if _host == null or not is_instance_valid(_host):
		return {"ok": false, "motivo": "dia_no_disponible"}
	var resultado := MarcadoresMundo.colocar(
		_host.jornada,
		zona_actual(),
		tipo,
		color,
		texto,
		posicion,
		normal,
		solo_sueno,
	)
	if bool(resultado.get("ok", false)):
		_firma = ""
		_guardar()
	return resultado


func eliminar(marcador_id: String) -> bool:
	if _host == null or not is_instance_valid(_host):
		return false
	var eliminado := MarcadoresMundo.eliminar(_host.jornada, zona_actual(), marcador_id)
	if eliminado:
		_firma = ""
		_guardar()
	return eliminado


func eliminar_zona_actual() -> int:
	if _host == null or not is_instance_valid(_host):
		return 0
	var cantidad := MarcadoresMundo.eliminar_zona(_host.jornada, zona_actual())
	if cantidad > 0:
		_firma = ""
		_guardar()
	return cantidad


## Permite que un sistema de estrés ya existente module la presentación sin
## convertir el estrés en dato del marcador ni alterar su posición persistida.
func establecer_estres_presentacion(valor: float) -> void:
	var nuevo := clampf(valor, 0.0, 1.0)
	if is_equal_approx(nuevo, _estres_presentacion):
		return
	_estres_presentacion = nuevo
	_firma = ""


func _remontar(mundo: Node3D, marcadores: Array) -> void:
	var anterior := mundo.get_node_or_null(NOMBRE_RAIZ)
	if anterior != null:
		anterior.queue_free()

	var raiz := Node3D.new()
	raiz.name = NOMBRE_RAIZ
	mundo.add_child(raiz)

	var en_sueno := zona_actual() == "sueño"
	for datos in marcadores:
		if not MarcadoresMundo.visible_en(datos, en_sueno):
			continue
		var visual := MarcadorMundo3D.new()
		raiz.add_child(visual)
		visual.configurar(datos, en_sueno, _estres_presentacion)


func _guardar() -> void:
	if _host != null and _host.has_method("_guardar_o_avisar"):
		_host._guardar_o_avisar("")
