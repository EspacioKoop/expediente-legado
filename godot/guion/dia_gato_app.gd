## Capa de presentación del gato compartido entre casa, SIGA y sueño (#92).
##
## Conserva la herencia histórica directa desde alquiler y compone aquí el
## primer vertical de objetivos oníricos (#299), evitando alterar el contrato
## estructural comprobado por las regresiones existentes.
extends "res://guion/dia_alquiler_app.gd"

const TAM_OBJETIVO := Vector3(2.8, 2.4, 2.8)
const DEMORA_RESOLUCION := 0.35

var _gato_guia: Gato
var _entrada_guia := Vector3.ZERO
var _salida_guia := Vector3.ZERO
var _hay_rumbo_guia := false
var _objetivos_espacio: Array = []
var _objetivo_escena := ""


func _espacio_de(fase: String) -> Dictionary:
	var espacio: Dictionary = super._espacio_de(fase)
	_hay_rumbo_guia = false
	_objetivos_espacio = []
	_objetivo_escena = ""
	if fase != "sueño":
		return espacio

	# Mantener esta lectura conserva el contrato histórico de la guía (#92),
	# aunque la salida deje de ser el mecanismo normal de progreso en #299.
	var salidas: Array = espacio.get("salidas", [])
	if jornada.get("sueno_escenas", []).is_empty():
		return espacio

	_objetivo_escena = String(jornada["sueno_escenas"][0])
	var foco: Vector3 = espacio.get("entrada", Vector3.ZERO)
	if not salidas.is_empty():
		foco = salidas[0].get("pos", foco)
	espacio["salidas"] = []

	var posiciones: Array = _posiciones_objetivo(espacio, foco)
	for i in SuenoObjetivos.POSIBLES_PRIMER_CORTE:
		(
			_objetivos_espacio
			. append(
				{
					"id": "%s:%d" % [_objetivo_escena, i],
					"pos": posiciones[i],
				}
			)
		)

	if not _objetivos_espacio.is_empty():
		_entrada_guia = espacio.get("entrada", Vector3.ZERO)
		_salida_guia = _objetivos_espacio[0].get("pos", _entrada_guia)
		_hay_rumbo_guia = true
	return espacio


func _entrar_en(fase: String) -> void:
	super._entrar_en(fase)
	_gato_guia = null
	if fase == "sueño":
		_montar_objetivos_sueno()
		_montar_guia_sueno()


func _posiciones_objetivo(espacio: Dictionary, foco: Vector3) -> Array:
	var posiciones: Array = []
	var bloques: Array = espacio.get("planta", [])
	if not bloques.is_empty():
		for celda in Planta.repartidas(bloques, SuenoObjetivos.POSIBLES_PRIMER_CORTE, []):
			posiciones.append(Planta.centro_en_metros(bloques, celda) + Vector3(0, 1.0, 0))
	while posiciones.size() < SuenoObjetivos.POSIBLES_PRIMER_CORTE:
		posiciones.append(foco)

	var figuras: Array = espacio.get("figuras", [])
	if not figuras.is_empty():
		posiciones[0] = figuras[0].get("pos", posiciones[0]) + Vector3(0, 1.0, 0)
	var carteles: Array = espacio.get("carteles", [])
	if not carteles.is_empty():
		posiciones[1] = carteles[0].get("pos", posiciones[1]) + Vector3(0, 1.0, 0)
	posiciones[2] = foco
	return posiciones


func _clave_objetivos_actual() -> String:
	return "%d:%s" % [int(jornada.get("dia", 0)), _objetivo_escena]


func _estado_objetivos_actual() -> Dictionary:
	if not jornada.has("sueno_objetivos"):
		jornada["sueno_objetivos"] = {}
	var estados: Dictionary = jornada["sueno_objetivos"]
	var clave: String = _clave_objetivos_actual()
	if not estados.has(clave):
		var ids: Array = _objetivos_espacio.map(func(objetivo): return objetivo["id"])
		estados[clave] = SuenoObjetivos.nuevo(ids)
	return estados[clave]


func _montar_objetivos_sueno() -> void:
	if _objetivos_espacio.is_empty():
		return
	var estado: Dictionary = _estado_objetivos_actual()
	var completados: Array = estado.get("completados", [])
	_actualizar_feedback_objetivos(SuenoObjetivos.progreso(estado))
	_actualizar_rumbo_guia_pendiente(estado)
	for objetivo in _objetivos_espacio:
		if completados.has(objetivo["id"]):
			continue
		var zona := Area3D.new()
		zona.name = "ObjetivoSueno_%s" % objetivo["id"]
		zona.position = objetivo["pos"]
		zona.set_meta("objetivo", objetivo["id"])
		var colision := CollisionShape3D.new()
		var caja := BoxShape3D.new()
		caja.size = TAM_OBJETIVO
		colision.shape = caja
		zona.add_child(colision)
		_mundo.add_child(zona)
		zona.body_entered.connect(_al_pisar_objetivo.bind(zona))
	if SuenoObjetivos.resuelto(estado):
		call_deferred("_resolver_objetivos_sueno")


func _al_pisar_objetivo(cuerpo: Node3D, zona: Area3D) -> void:
	if cuerpo != _caminante or jornada.get("fase", "") != "sueño" or _pantalla != null:
		return
	var estado: Dictionary = _estado_objetivos_actual()
	var id := String(zona.get_meta("objetivo", ""))
	if not SuenoObjetivos.completar(estado, id):
		return
	# body_entered se emite durante físicas; diferir permite desactivar la zona.
	zona.set_deferred("monitoring", false)

	var progreso: Vector2i = SuenoObjetivos.progreso(estado)
	_ambiente.ambient_light_energy = minf(_ambiente.ambient_light_energy + 0.14, 1.5)
	_actualizar_feedback_objetivos(progreso)
	_actualizar_rumbo_guia_pendiente(estado)
	_orientar_gato_guia()
	if not SuenoObjetivos.resuelto(estado):
		_guardar_o_avisar("")
		return

	_caminante.set_physics_process(false)
	get_tree().create_timer(DEMORA_RESOLUCION).timeout.connect(_resolver_objetivos_sueno)


func _actualizar_feedback_objetivos(progreso: Vector2i) -> void:
	var marcas := []
	for i in progreso.y:
		marcas.append("◆" if i < progreso.x else "◇")
	_rotulo.text = "  ".join(marcas)


func _actualizar_rumbo_guia_pendiente(estado: Dictionary) -> void:
	var completados: Array = estado.get("completados", [])
	_hay_rumbo_guia = false
	for objetivo in _objetivos_espacio:
		if completados.has(objetivo["id"]):
			continue
		_salida_guia = objetivo.get("pos", _entrada_guia)
		_hay_rumbo_guia = true
		return


func _orientar_gato_guia() -> void:
	if not is_instance_valid(_gato_guia) or not _hay_rumbo_guia:
		return
	var rumbo := _salida_guia - _entrada_guia
	rumbo.y = 0.0
	if rumbo.length() < 0.01:
		return
	var direccion := rumbo.normalized()
	if GatoAyuda.guia_orienta(jornada.get("gato", {})):
		_gato_guia.rotation.y = atan2(direccion.x, direccion.z)


func _resolver_objetivos_sueno() -> void:
	if jornada.get("fase", "") != "sueño" or _objetivo_escena.is_empty():
		return
	var estado: Dictionary = _estado_objetivos_actual()
	if not SuenoObjetivos.resuelto(estado):
		return

	jornada["sueno_escenas"].pop_front()
	var destino := "sueño"
	if jornada["sueno_escenas"].is_empty():
		var dia := Jornada.despertar(jornada)
		_hablando = false
		_nomina.text = tr("DIA_NUEVO") % dia
		destino = "archivo"
	if not _guardar_o_avisar(destino):
		_caminante.set_physics_process(true)
		return
	_entrar_en(destino)
	_caminante.set_physics_process(true)


func _abrir_expediente() -> void:
	super._abrir_expediente()
	if _pantalla == null:
		return
	_montar_asistente_siga()


func _montar_asistente_siga() -> void:
	var gato: Dictionary = jornada.get("gato", {})
	var lineas := GatoAyuda.lineas_asistente(gato)
	if lineas.is_empty():
		return

	# El conjunto no tiene fondo propio: gato y bocadillo son dos piezas
	# visualmente independientes. El anclaje al borde inferior derecho escala con
	# la ventana y deja el cuerpo del expediente libre en vez de ocupar la base.
	var conjunto := HBoxContainer.new()
	conjunto.name = "AsistenteSiga"
	conjunto.theme = EstiloSiga.tema()
	conjunto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	conjunto.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	conjunto.offset_left = -540
	conjunto.offset_top = -176
	conjunto.offset_right = -16
	conjunto.offset_bottom = -16
	conjunto.add_theme_constant_override("separation", 18)
	_pantalla.add_child(conjunto)

	var burbuja := PanelContainer.new()
	burbuja.name = "BocadilloGato"
	burbuja.custom_minimum_size = Vector2(348, 118)
	burbuja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	conjunto.add_child(burbuja)

	var margen := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 12)
	burbuja.add_child(margen)

	var caja := VBoxContainer.new()
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_theme_constant_override("separation", 6)
	margen.add_child(caja)
	for clave in lineas:
		var frase := Label.new()
		frase.text = tr(String(clave))
		frase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		frase.custom_minimum_size.x = 320
		frase.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caja.add_child(frase)

	# Cola del bocadillo: un triángulo que apunta al avatar, separado del dibujo
	# del gato para que la atribución de la frase sea inequívoca.
	var puntero := Polygon2D.new()
	puntero.name = "PunteroBocadilloGato"
	puntero.polygon = PackedVector2Array([Vector2(342, 82), Vector2(370, 96), Vector2(342, 108)])
	puntero.color = Color(0.78, 0.79, 0.75)
	conjunto.add_child(puntero)

	var avatar := GatoAsistente2D.new()
	avatar.name = "GatoAsistente"
	var preferencias := PreferenciasSiga.cargar()
	avatar.configurar(GatoAyuda.nivel(gato), bool(preferencias.get("reduccion_movimiento", false)))
	conjunto.add_child(avatar)


func _montar_guia_sueno() -> void:
	var gato: Dictionary = jornada.get("gato", {})
	if not GatoAyuda.guia_visible(gato) or not _hay_rumbo_guia:
		return

	var rumbo := _salida_guia - _entrada_guia
	rumbo.y = 0.0
	if rumbo.length() < 0.01:
		return

	var direccion := rumbo.normalized()
	var posicion := _entrada_guia + direccion * 1.4
	_gato_guia = Gato.new()
	_mundo.add_child(_gato_guia)
	_gato_guia.empezar(posicion, [posicion])

	# Bien cuidado funciona como una brújula viva hacia el primer objetivo
	# pendiente, no hacia la antigua salida física.
	_orientar_gato_guia()
