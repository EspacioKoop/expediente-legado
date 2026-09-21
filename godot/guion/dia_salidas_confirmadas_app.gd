## Salidas deliberadas del día (#790).
##
## La salida de la oficina conserva el Area3D histórico como fuente de metadatos
## para no duplicar Jornada ni las capas que interceptan el tránsito. En runtime
## se desactiva su proximidad y se superpone un Interactuable3D sobre la puerta
## física ya declarada por el catálogo. Confirmar reinyecta el mismo evento en
## _al_pisar_salida, por lo que ascensor, archivado, guardado y nómina siguen
## pasando por sus dueños actuales.
extends "res://guion/dia_jornada_app.gd"

const NOMBRE_PUERTA_OFICINA := "PuertaSalidaOficina"
const NOMBRE_ZONA_ACCESO_OFICINA := "ZonaAccesoSalidaOficina"
const TAM_DIALOGO_SALIDA := Vector2i(420, 180)
# La hoja física está en el muro izquierdo. Las zonas se desplazan hacia el
# interior para que se puedan alcanzar sin pegar la cámara a la pared.
const DESPLAZAMIENTO_INTERACCION := Vector3(0.50, 0.0, 0.0)
const TAM_INTERACCION := Vector3(2.0, 2.4, 1.8)
const DESPLAZAMIENTO_ACCESO := Vector3(1.05, 0.0, 0.0)
const TAM_ACCESO := Vector3(1.8, 2.2, 1.8)

var _puerta_salida_oficina: Interactuable3D = null
var _zona_acceso_salida: Area3D = null
var _salida_oficina: Area3D = null
var _confirmacion_salida: ConfirmationDialog = null


func _entrar_en(fase: String) -> void:
	_cerrar_confirmacion_salida()
	super._entrar_en(fase)
	_puerta_salida_oficina = null
	_zona_acceso_salida = null
	_salida_oficina = null
	if fase == "archivo":
		call_deferred("_montar_puerta_salida_oficina")


func _montar_puerta_salida_oficina() -> void:
	if jornada.get("fase", "") != "archivo" or _mundo == null:
		return
	if is_instance_valid(_puerta_salida_oficina):
		return

	var salida := _buscar_salida_oficina(_mundo)
	if salida == null:
		return

	# La zona histórica conserva destino/rotulo para todas las capas que ya la
	# conocen, pero deja de poder dispararse al caminar o de tapar el raycast.
	salida.monitoring = false
	salida.monitorable = false
	_salida_oficina = salida

	var puerta := Interactuable3D.new()
	puerta.name = NOMBRE_PUERTA_OFICINA
	puerta.position = salida.position + DESPLAZAMIENTO_INTERACCION
	puerta.verbo = Interactuable3D.Verbo.ABRIR
	puerta.nombre_objeto = tr("SALIDA_PUERTA_OFICINA")
	# El sonido real pertenece al tránsito confirmado; pulsar y cancelar no
	# debe reproducir una puerta que nunca llegó a abrirse.
	puerta.sonido = Interactuable3D.SIN_SONIDO

	# El trigger histórico era razonable para pisarlo, pero demasiado estrecho
	# para apuntarle con un raycast. La interacción deliberada tiene su propio
	# volumen, algo mayor y metido en la habitación.
	var forma := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = TAM_INTERACCION
	forma.shape = caja
	puerta.add_child(forma)

	puerta.activado.connect(_pedir_confirmacion_salida)
	_mundo.add_child(puerta)
	_puerta_salida_oficina = puerta
	_montar_zona_acceso_salida(salida)


# Fallback de accesibilidad: acercarse físicamente a la puerta abre la misma
# confirmación que el raycast. No ficha ni transita por sí solo; solo evita que
# una puerta visible se convierta en un pixel-hunt para poder abandonar la sala.
func _montar_zona_acceso_salida(salida: Area3D) -> void:
	var zona := Area3D.new()
	zona.name = NOMBRE_ZONA_ACCESO_OFICINA
	zona.position = salida.position + DESPLAZAMIENTO_ACCESO
	var forma := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = TAM_ACCESO
	forma.shape = caja
	zona.add_child(forma)
	zona.body_entered.connect(_al_acercarse_a_salida)
	_mundo.add_child(zona)
	_zona_acceso_salida = zona


func _al_acercarse_a_salida(cuerpo: Node3D) -> void:
	if cuerpo == _caminante:
		_pedir_confirmacion_salida(cuerpo)


func _buscar_salida_oficina(raiz: Node) -> Area3D:
	for nodo in raiz.get_children():
		if not nodo is Area3D or nodo is Interactuable3D:
			continue
		var area := nodo as Area3D
		if String(area.get_meta("destino", "")) != "trayecto":
			continue
		if not String(area.get_meta("frase", "")).is_empty():
			continue
		if not String(area.get_meta("duelo", "")).is_empty():
			continue
		return area
	return null


func _forma_de_salida(salida: Area3D) -> CollisionShape3D:
	for hijo in salida.get_children():
		if hijo is CollisionShape3D:
			return hijo as CollisionShape3D
	return null


func _pedir_confirmacion_salida(_actor: Node) -> void:
	if _confirmacion_salida != null or not is_instance_valid(_salida_oficina):
		return
	if partida.guardado_pendiente:
		_al_pisar_salida(_caminante, _salida_oficina)
		return
	if _pantalla != null or not _caminante.is_physics_processing():
		return

	var dialogo := ConfirmationDialog.new()
	dialogo.name = "ConfirmarSalidaOficina"
	dialogo.title = tr("SALIDA_CONFIRMAR_TITULO")
	dialogo.dialog_text = tr("SALIDA_CONFIRMAR_OFICINA")
	dialogo.ok_button_text = tr("SALIDA_CONFIRMAR_ACEPTAR")
	dialogo.get_cancel_button().text = tr("SALIDA_CONFIRMAR_CANCELAR")
	dialogo.confirmed.connect(_confirmar_salida_oficina)
	dialogo.canceled.connect(_cancelar_salida_oficina)
	add_child(dialogo)
	_confirmacion_salida = dialogo

	if is_instance_valid(_puerta_salida_oficina):
		_puerta_salida_oficina.habilitado = false
	_caminante.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	dialogo.popup_centered(TAM_DIALOGO_SALIDA)
	dialogo.get_cancel_button().grab_focus.call_deferred()


func _confirmar_salida_oficina() -> void:
	var salida := _salida_oficina
	_cerrar_confirmacion_salida()
	if is_instance_valid(salida):
		# Llamada virtual deliberada: las capas de archivado/ascensor/clima deben
		# recibir exactamente el mismo tránsito que recibían desde body_entered.
		_al_pisar_salida(_caminante, salida)


func _cancelar_salida_oficina() -> void:
	_cerrar_confirmacion_salida()


func _cerrar_confirmacion_salida() -> void:
	var estaba_abierta := _confirmacion_salida != null
	if _confirmacion_salida != null:
		# ConfirmationDialog es Window exclusivo. Ocultarlo y liberar esa
		# exclusividad antes de queue_free permite abrir en el mismo frame el
		# selector de ascensor o volver a usar la puerta sin una ventana fantasma.
		_confirmacion_salida.hide()
		_confirmacion_salida.exclusive = false
		_confirmacion_salida.queue_free()
		_confirmacion_salida = null
	if is_instance_valid(_puerta_salida_oficina):
		_puerta_salida_oficina.habilitado = true
	if estaba_abierta and is_instance_valid(_caminante):
		_caminante.set_physics_process(true)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
