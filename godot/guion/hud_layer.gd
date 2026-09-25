## Árbitro común de superficies del HUD (#397).
##
## No decide contenido ni crea textos: únicamente aplica la jerarquía visual
## entre estado, recursos, interacción, tutorial, fase, diálogo y modales. Así cada
## sistema puede seguir siendo dueño de su contenido sin pelear por la misma atención.
class_name HUDLayer
extends CanvasLayer

signal superficie_cambiada(tipo: StringName, visible: bool)

const ESTADO := &"estado"
const RECURSOS := &"recursos"
const INTERACCION := &"interaccion"
const TUTORIAL := &"tutorial"
const FASE := &"fase"
const DIALOGO := &"dialogo"
const MODAL := &"modal"

const PRIORIDADES := {
	INTERACCION: 100,
	TUTORIAL: 200,
	FASE: 250,
	DIALOGO: 300,
	MODAL: 400,
}

var _superficies: Dictionary = {}
var _activas: Dictionary = {}


func registrar(tipo: StringName, control: Control) -> void:
	if not _tipo_valido(tipo):
		push_error("Superficie HUD desconocida: %s" % tipo)
		return
	# Las superficies transitorias (tutorial, fase y diálogo) se liberan al terminar.
	# Guardar una referencia fuerte deja un objeto ya destruido dentro del
	# diccionario y Godot falla al intentar tiparlo en el siguiente refresco.
	_superficies[tipo] = weakref(control)
	_refrescar()


func activar(tipo: StringName) -> void:
	if not _tipo_valido(tipo):
		push_error("Superficie HUD desconocida: %s" % tipo)
		return
	_activas[tipo] = true
	_refrescar()


func desactivar(tipo: StringName) -> void:
	_activas.erase(tipo)
	_refrescar()


func desactivar_todo() -> void:
	_activas.clear()
	_refrescar()


func esta_activa(tipo: StringName) -> bool:
	return bool(_activas.get(tipo, false))


func debe_ser_visible(tipo: StringName) -> bool:
	if not esta_activa(tipo):
		return false
	if esta_activa(MODAL):
		return tipo == MODAL
	if tipo == ESTADO:
		return true
	if tipo == RECURSOS:
		# La banda de recursos es información secundaria. Puede convivir con el
		# prompt corto de interacción, pero desaparece cuando una superficie que
		# requiere lectura (tutorial, cambio de fase o diálogo) toma el foco.
		var primaria := _primaria_activa()
		return primaria == StringName() or primaria == INTERACCION
	if tipo == MODAL:
		return true
	return tipo == _primaria_activa()


func _primaria_activa() -> StringName:
	var elegida := StringName()
	var prioridad := -1
	for tipo in [INTERACCION, TUTORIAL, FASE, DIALOGO]:
		if not esta_activa(tipo):
			continue
		var actual := int(PRIORIDADES[tipo])
		if actual > prioridad:
			prioridad = actual
			elegida = tipo
	return elegida


func _refrescar() -> void:
	var caducadas: Array[StringName] = []
	for tipo in _superficies:
		var referencia: WeakRef = _superficies[tipo]
		var control := referencia.get_ref() as Control
		if control == null:
			caducadas.append(tipo)
			continue
		var visible := debe_ser_visible(tipo)
		if control.visible == visible:
			continue
		control.visible = visible
		superficie_cambiada.emit(tipo, visible)
	for tipo in caducadas:
		_superficies.erase(tipo)


func _tipo_valido(tipo: StringName) -> bool:
	return tipo in [ESTADO, RECURSOS, INTERACCION, TUTORIAL, FASE, DIALOGO, MODAL]
