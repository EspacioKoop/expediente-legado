## Presentación 3D alcanzable de Ecos del archivo (#161).
##
## Los tres fragmentos son Interactuable3D reales: el Caminante ya resuelve
## foco con raycast y la acción semántica `interactuar` para teclado y mando.
## Esta capa no lee Input ni conoce teclas/botones físicos.
##
## Los paneles y pórticos son solo malla/Area3D: no crean cuerpos sólidos ni
## pueden cerrar la salida genérica de la sala de sueño.
class_name SuenoEcosArchivo3D
extends Node3D

signal terminado(estado: String)
signal estado_cambiado(estado: String)

const POSICIONES_ECOS := [
	Vector3(-2.5, 0.0, 0.7),
	Vector3(0.0, 0.0, -0.8),
	Vector3(2.5, 0.0, 0.7),
]
const GIROS_ECOS := [-0.14, 0.0, 0.14]
const COLOR_BASE := Color(0.13, 0.15, 0.20)
const COLOR_SELECCION := Color(0.31, 0.35, 0.46)
const COLOR_TEXTO := Color(0.82, 0.84, 0.88)
const COLOR_HABITACION := Color(0.08, 0.09, 0.12, 0.68)

var presentacion
var reduccion_movimiento := false
var _recompensa_texto := ""
var _ecos_3d: Array = []
var _estado: Label3D
var _confirmar: Interactuable3D


func configurar(
	una_presentacion, reducir_movimiento: bool = false, recompensa_texto: String = ""
) -> bool:
	if una_presentacion == null or una_presentacion.ecos == null:
		return false
	presentacion = una_presentacion
	reduccion_movimiento = reducir_movimiento
	_recompensa_texto = recompensa_texto.strip_edges()
	_montar()
	_sincronizar()
	return true


func abandonar() -> bool:
	if presentacion == null:
		return false
	var seguro: bool = bool(presentacion.abandonar())
	_sincronizar()
	if seguro:
		var estado := str(presentacion.vista(reduccion_movimiento).get("estado", "cerrado"))
		estado_cambiado.emit(estado)
		terminado.emit(estado)
	return seguro


func _montar() -> void:
	if not _ecos_3d.is_empty():
		return

	var regla := Label3D.new()
	regla.name = "ReglaEcos"
	regla.text = str(presentacion.vista(reduccion_movimiento).get("regla", ""))
	regla.position = Vector3(0.0, 2.75, 0.0)
	regla.font_size = 38
	regla.pixel_size = 0.004
	regla.modulate = COLOR_TEXTO
	regla.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(regla)

	for slot in range(POSICIONES_ECOS.size()):
		var eco := Interactuable3D.new()
		eco.name = "EcoArchivo_%d" % slot
		eco.position = POSICIONES_ECOS[slot]
		eco.rotation.y = GIROS_ECOS[slot]
		eco.verbo = Interactuable3D.Verbo.LEER
		eco.nombre_objeto = "#%d" % (slot + 1)
		eco.set_meta("slot", slot)
		eco.activado.connect(_al_activar_eco.bind(slot))
		add_child(eco)
		_montar_microhabitacion(eco, slot)
		_montar_panel(eco)
		_ecos_3d.append(eco)

	_estado = Label3D.new()
	_estado.name = "EstadoEcos"
	_estado.position = Vector3(0.0, 1.95, 0.15)
	_estado.font_size = 28
	_estado.pixel_size = 0.004
	_estado.modulate = COLOR_TEXTO
	_estado.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_estado)

	_confirmar = Interactuable3D.new()
	_confirmar.name = "ConfirmarEcos"
	_confirmar.position = Vector3(0.0, 0.0, 2.35)
	_confirmar.verbo = Interactuable3D.Verbo.USAR
	_confirmar.activado.connect(_al_confirmar)
	add_child(_confirmar)
	_montar_confirmacion(_confirmar)


## Cada eco se lee dentro de una pequeña estancia deformada. Las superficies son
## únicamente malla translúcida: no añaden cuerpos, navegación ni puertas y por
## tanto conservan la salida segura del sueño.
func _montar_microhabitacion(eco: Interactuable3D, slot: int) -> void:
	var habitacion := Node3D.new()
	habitacion.name = "MicroHabitacion"
	habitacion.set_meta("slot", slot)
	eco.add_child(habitacion)

	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_HABITACION
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

	var signo := -1.0 if slot % 2 == 0 else 1.0
	_crear_superficie_habitacion(
		habitacion,
		"Suelo",
		Vector3(2.8, 0.08, 1.9),
		Vector3(0.0, 0.04, 0.35),
		Vector3(0.0, 0.0, signo * 0.018),
		material,
	)
	_crear_superficie_habitacion(
		habitacion,
		"Techo",
		Vector3(2.7, 0.08, 1.7),
		Vector3(0.0, 2.42, 0.32),
		Vector3(0.0, 0.0, -signo * (0.05 + float(slot) * 0.012)),
		material,
	)
	_crear_superficie_habitacion(
		habitacion,
		"ParedIzquierda",
		Vector3(0.10, 2.35, 1.65),
		Vector3(-1.34, 1.18, 0.34),
		Vector3(0.0, 0.0, 0.055 + signo * 0.018),
		material,
	)
	_crear_superficie_habitacion(
		habitacion,
		"ParedDerecha",
		Vector3(0.10, 2.28, 1.65),
		Vector3(1.34, 1.15, 0.34),
		Vector3(0.0, 0.0, -0.045 + signo * 0.016),
		material,
	)
	_crear_superficie_habitacion(
		habitacion,
		"Fondo",
		Vector3(2.68, 2.30, 0.08),
		Vector3(0.0, 1.15, 1.15),
		Vector3(signo * 0.012, 0.0, -signo * 0.025),
		material,
	)


func _crear_superficie_habitacion(
	padre: Node3D,
	nombre: String,
	tamano: Vector3,
	posicion_local: Vector3,
	rotacion_local: Vector3,
	material: Material,
) -> void:
	var superficie := MeshInstance3D.new()
	superficie.name = nombre
	var caja := BoxMesh.new()
	caja.size = tamano
	superficie.mesh = caja
	superficie.position = posicion_local
	superficie.rotation = rotacion_local
	superficie.material_override = material
	superficie.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(superficie)


func _montar_panel(eco: Interactuable3D) -> void:
	var panel := MeshInstance3D.new()
	panel.name = "Panel"
	var caja := BoxMesh.new()
	caja.size = Vector3(2.0, 1.35, 0.12)
	panel.mesh = caja
	panel.position = Vector3(0.0, 1.1, 0.0)
	eco.add_child(panel)

	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_BASE
	material.roughness = 0.88
	panel.material_override = material

	var texto := Label3D.new()
	texto.name = "Texto"
	texto.position = Vector3(0.0, 1.1, -0.08)
	texto.font_size = 30
	texto.pixel_size = 0.0032
	texto.modulate = COLOR_TEXTO
	texto.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	eco.add_child(texto)

	# Segunda impresión del mismo texto, usada solo como deformación visual.
	# Nunca introduce contenido nuevo: repite exactamente texto_visible.
	var eco_visual := Label3D.new()
	eco_visual.name = "EcoVisual"
	eco_visual.position = Vector3(0.0, 1.1, 0.02)
	eco_visual.font_size = 30
	eco_visual.pixel_size = 0.0032
	eco_visual.modulate = Color(COLOR_TEXTO.r, COLOR_TEXTO.g, COLOR_TEXTO.b, 0.0)
	eco_visual.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	eco.add_child(eco_visual)

	var orden := Label3D.new()
	orden.name = "Orden"
	orden.position = Vector3(0.0, 1.72, 0.0)
	orden.font_size = 34
	orden.pixel_size = 0.0035
	orden.modulate = COLOR_TEXTO
	orden.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	eco.add_child(orden)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(2.1, 1.55, 0.45)
	colision.shape = forma
	colision.position = Vector3(0.0, 1.1, 0.0)
	eco.add_child(colision)

	# Dos jambas deformadas hacen que cada fragmento se lea como un pequeño
	# umbral separado sin añadir colisión ni modificar la planta de la sala.
	_crear_jamba(eco, Vector3(-1.12, 1.15, 0.08), 0.14)
	_crear_jamba(eco, Vector3(1.12, 1.15, -0.05), -0.11)


func _montar_confirmacion(confirmar: Interactuable3D) -> void:
	var base := MeshInstance3D.new()
	base.name = "Base"
	var caja := BoxMesh.new()
	caja.size = Vector3(1.2, 0.22, 0.8)
	base.mesh = caja
	base.position = Vector3(0.0, 0.35, 0.0)
	confirmar.add_child(base)

	var etiqueta := Label3D.new()
	etiqueta.name = "Indicador"
	etiqueta.text = "✓"
	etiqueta.position = Vector3(0.0, 0.58, -0.18)
	etiqueta.font_size = 42
	etiqueta.pixel_size = 0.004
	etiqueta.modulate = COLOR_TEXTO
	etiqueta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	confirmar.add_child(etiqueta)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.3, 0.7, 0.9)
	colision.shape = forma
	colision.position = Vector3(0.0, 0.35, 0.0)
	confirmar.add_child(colision)


func _crear_jamba(padre: Node3D, posicion_local: Vector3, giro_z: float) -> void:
	var jamba := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(0.18, 2.45, 0.18)
	jamba.mesh = caja
	jamba.position = posicion_local
	jamba.rotation.z = giro_z
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.20, 0.19, 0.23)
	material.roughness = 1.0
	jamba.material_override = material
	padre.add_child(jamba)


## Cada familia documental altera la lectura espacial sin cambiar el puzzle:
## repetición = copia desplazada; palabra ausente = ya viene en texto_visible;
## rótulo deshecho = panel inclinado; eco lejano = copia tenue y ampliada.
func _aplicar_manifestacion(
	eco: Interactuable3D, manifestacion: String, slot: int, texto_visible: String
) -> void:
	var texto := eco.get_node("Texto") as Label3D
	var eco_visual := eco.get_node("EcoVisual") as Label3D
	var panel := eco.get_node("Panel") as MeshInstance3D
	if texto == null or eco_visual == null or panel == null:
		return

	panel.rotation = Vector3.ZERO
	panel.scale = Vector3.ONE
	texto.rotation = Vector3.ZERO
	eco_visual.text = ""
	eco_visual.position = Vector3(0.0, 1.1, 0.02)
	eco_visual.scale = Vector3.ONE
	eco_visual.modulate = Color(COLOR_TEXTO.r, COLOR_TEXTO.g, COLOR_TEXTO.b, 0.0)

	match manifestacion:
		EcosArchivoPresentacion.MANIFESTACION_REPETICION:
			eco_visual.text = texto_visible
			eco_visual.position = Vector3(0.08, 1.04, 0.025)
			eco_visual.modulate = Color(COLOR_TEXTO.r, COLOR_TEXTO.g, COLOR_TEXTO.b, 0.24)
		EcosArchivoPresentacion.MANIFESTACION_ROTULO_DESHECHO:
			var signo := -1.0 if slot % 2 == 0 else 1.0
			panel.rotation.z = signo * (0.045 + float(slot) * 0.012)
			panel.scale.x = 0.96 - float(slot) * 0.015
			texto.rotation.z = -panel.rotation.z * 0.35
		EcosArchivoPresentacion.MANIFESTACION_ECO_LEJANO:
			eco_visual.text = texto_visible
			eco_visual.position = Vector3(0.0, 1.1, 0.075)
			eco_visual.scale = Vector3(1.08, 1.08, 1.0)
			eco_visual.modulate = Color(COLOR_TEXTO.r, COLOR_TEXTO.g, COLOR_TEXTO.b, 0.16)


func _al_activar_eco(_actor: Node, slot: int) -> void:
	if presentacion == null or slot < 0 or slot >= _ecos_3d.size():
		return
	presentacion.foco = slot
	var evento: String = str(presentacion.seleccionar())
	_sincronizar()
	estado_cambiado.emit(evento)


func _al_confirmar(_actor: Node) -> void:
	if presentacion == null:
		return
	var evento: String = str(presentacion.confirmar())
	_sincronizar()
	estado_cambiado.emit(evento)
	if (
		evento
		in [
			EcosArchivoPresentacion.EVENTO_COMPLETADO,
			EcosArchivoPresentacion.EVENTO_DISPERSADO,
		]
	):
		terminado.emit(evento)


func _sincronizar() -> void:
	if presentacion == null or _ecos_3d.is_empty():
		return
	var vista: Dictionary = presentacion.vista(reduccion_movimiento)
	var elementos: Array = vista.get("elementos", [])
	var seleccion: Array = vista.get("seleccion", [])
	var ultimo_seleccionado := int(seleccion.back()) if not seleccion.is_empty() else -1
	for slot in range(mini(elementos.size(), _ecos_3d.size())):
		var dato: Dictionary = elementos[slot]
		var eco: Interactuable3D = _ecos_3d[slot]
		var texto := eco.get_node("Texto") as Label3D
		var orden := eco.get_node("Orden") as Label3D
		var panel := eco.get_node("Panel") as MeshInstance3D
		var texto_visible := str(dato.get("texto_visible", dato.get("texto", "")))
		texto.text = texto_visible
		_aplicar_manifestacion(eco, str(vista.get("manifestacion", "")), slot, texto_visible)
		var posicion := int(dato.get("posicion_seleccion", -1))
		var eco_id := int(dato.get("id", -1))
		orden.text = "" if posicion < 0 else "%d" % (posicion + 1)
		eco.habilitado = (
			not presentacion.cerrada and (posicion < 0 or eco_id == ultimo_seleccionado)
		)
		var material := StandardMaterial3D.new()
		material.albedo_color = COLOR_SELECCION if posicion >= 0 else COLOR_BASE
		material.roughness = 0.88
		panel.material_override = material

	if _confirmar != null:
		_confirmar.habilitado = bool(vista.get("confirmacion_disponible", false))

	if _estado != null:
		if (
			str(vista.get("estado", "")) == EcosArchivoPresentacion.EVENTO_COMPLETADO
			and not _recompensa_texto.is_empty()
		):
			_estado.text = _recompensa_texto
		else:
			_estado.text = (
				"%d/%d · %s"
				% [
					int(vista.get("intentos", 0)),
					int(vista.get("max_intentos", 1)),
					str(vista.get("estado", "activo")),
				]
			)
