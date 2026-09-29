## Encuentro real autorado de #1889.
##
## Es una superficie opt-in del trayecto: el jugador debe interactuar de forma
## deliberada. El nodo no abre el combate por su cuenta ni habilita ataques en
## el mundo; construye un objetivo autorizado y deja a DiaApp usar la frontera
## comun de CombateContextual. La consecuencia solo se aplica al recibir el
## resultado emitido por ese combate.
class_name DiaEncuentroReal1889App
extends Node3D

signal combate_solicitado(objetivo: Dictionary)

const ID_OBJETIVO := "encuentro_real_1889"
const CLAVE_ESTADO := "encuentro_real_1889"
const TIPO_CONSECUENCIA := "cerrar_incidente_callejero"
const TAM_INTERACCION := Vector3(1.8, 2.0, 1.4)

var _jornada: Dictionary = {}
var _zona: Interactuable3D
var _escena: Node3D
var _solicitud_pendiente := false
var _combate_abierto := false


func configurar(jornada_actual: Dictionary) -> void:
	_jornada = jornada_actual
	if resuelto():
		return
	if _escena == null:
		_montar()


func objetivo() -> Dictionary:
	return CombateContextual.autorizar_realidad(
		{
			"id": ID_OBJETIVO,
			"nombre": "ENCUENTRO_REAL_1889_RIVAL",
		},
		{"tipo": TIPO_CONSECUENCIA},
	)


func marcar_combate_abierto(abierto: bool) -> void:
	_solicitud_pendiente = false
	_combate_abierto = abierto
	if _zona != null:
		_zona.habilitado = not abierto and not resuelto()


func resolver_resultado(
	objetivo_id: String, gano: bool, consecuencia: Dictionary
) -> bool:
	if objetivo_id != ID_OBJETIVO:
		return false
	if String(consecuencia.get("tipo", "")) != TIPO_CONSECUENCIA:
		return false
	if resuelto():
		return false
	_jornada[CLAVE_ESTADO] = {
		"estado": "victoria" if gano else "derrota",
	}
	_combate_abierto = false
	_solicitud_pendiente = false
	if _zona != null:
		_zona.habilitado = false
	if _escena != null and is_instance_valid(_escena):
		_escena.queue_free()
		_escena = null
	return true


func estado() -> String:
	var datos = _jornada.get(CLAVE_ESTADO, {})
	if not datos is Dictionary:
		return ""
	return String(datos.get("estado", ""))


func resuelto() -> bool:
	return estado() in ["victoria", "derrota"]


func zona_interactiva() -> Interactuable3D:
	return _zona


func _al_activar(_actor: Node) -> void:
	if resuelto() or _combate_abierto or _solicitud_pendiente:
		return
	_solicitud_pendiente = true
	if _zona != null:
		_zona.habilitado = false
	combate_solicitado.emit(objetivo())


func _montar() -> void:
	_escena = Node3D.new()
	_escena.name = "EncuentroReal1889"
	add_child(_escena)

	var figura_rival := FiguraSilueta.construir(
		_escena, Vector3(-0.48, 0.0, 0.10), Color(0.30, 0.27, 0.25)
	)
	figura_rival.name = "Rival"
	figura_rival.rotation_degrees.y = -18.0
	var figura_afectada := FiguraSilueta.construir(
		_escena, Vector3(0.48, 0.0, -0.18), Color(0.43, 0.42, 0.39)
	)
	figura_afectada.name = "PersonaAfectada"
	figura_afectada.rotation_degrees.y = 162.0

	_zona = Interactuable3D.new()
	_zona.name = "Intervenir"
	_zona.verbo = Interactuable3D.Verbo.DAR
	_zona.nombre_objeto = tr("ENCUENTRO_REAL_1889_INTERVENIR")
	_zona.sonido = Interactuable3D.SIN_SONIDO
	_zona.position = Vector3(0.0, 1.0, 0.0)
	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = TAM_INTERACCION
	colision.shape = forma
	_zona.add_child(colision)
	_zona.activado.connect(_al_activar)
	_escena.add_child(_zona)
