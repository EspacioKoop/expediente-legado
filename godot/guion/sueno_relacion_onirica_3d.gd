## Presentación 3D de Relación documental onírica (#89).
##
## No lee Input directamente: cada documento es un Interactuable3D y reutiliza
## el raycast/acción semántica común. La pareja solo puede cerrarse una vez.
class_name SuenoRelacionOnirica3D
extends Node3D

signal terminado(estado: String)
signal estado_cambiado(estado: String)

const Puzzle := preload("res://guion/puzzle_onirico.gd")

const POSICIONES := [
	Vector3(-3.3, 0.0, 0.7),
	Vector3(-1.1, 0.0, -0.7),
	Vector3(1.1, 0.0, -0.7),
	Vector3(3.3, 0.0, 0.7),
]
const COLOR_BASE := Color(0.12, 0.14, 0.19)
const COLOR_SELECCION := Color(0.30, 0.34, 0.45)
const COLOR_TEXTO := Color(0.84, 0.85, 0.88)

var relacion: RelacionOnirica
var recompensa_texto := ""
var _documentos_3d: Array = []
var _estado: Label3D
var _confirmar: Interactuable3D


func configurar(una_relacion: RelacionOnirica, recompensa: String = "") -> bool:
	if una_relacion == null or una_relacion.nucleo == null:
		return false
	relacion = una_relacion
	recompensa_texto = recompensa.strip_edges()
	_montar()
	_sincronizar()
	return true


func abandonar() -> bool:
	if relacion == null:
		return false
	var seguro := relacion.salir()
	_sincronizar()
	if seguro:
		estado_cambiado.emit("abandonado")
		terminado.emit("abandonado")
	return seguro


func _montar() -> void:
	var regla := Label3D.new()
	regla.name = "ReglaRelacion"
	regla.text = tr("VISOR_ELIJA")
	regla.position = Vector3(0.0, 2.85, 0.0)
	regla.font_size = 36
	regla.pixel_size = 0.004
	regla.modulate = COLOR_TEXTO
	regla.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(regla)

	for indice in range(relacion.documentos.size()):
		var dato: Dictionary = relacion.documentos[indice]
		var documento := Interactuable3D.new()
		documento.name = "DocumentoRelacion_%d" % indice
		documento.position = POSICIONES[indice]
		documento.verbo = Interactuable3D.Verbo.LEER
		documento.nombre_objeto = String(dato.get("folio", ""))
		documento.activado.connect(_al_activar_documento.bind(indice))
		add_child(documento)
		_montar_panel(documento)
		_documentos_3d.append(documento)

	_estado = Label3D.new()
	_estado.name = "EstadoRelacion"
	_estado.position = Vector3(0.0, 2.05, 0.15)
	_estado.font_size = 28
	_estado.pixel_size = 0.004
	_estado.modulate = COLOR_TEXTO
	_estado.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_estado)

	_confirmar = Interactuable3D.new()
	_confirmar.name = "ConfirmarRelacion"
	_confirmar.position = Vector3(0.0, 0.0, 2.45)
	_confirmar.verbo = Interactuable3D.Verbo.USAR
	_confirmar.activado.connect(_al_confirmar)
	add_child(_confirmar)
	_montar_confirmacion(_confirmar)


func _montar_panel(documento: Interactuable3D) -> void:
	var panel := MeshInstance3D.new()
	panel.name = "Panel"
	var caja := BoxMesh.new()
	caja.size = Vector3(2.05, 1.65, 0.12)
	panel.mesh = caja
	panel.position = Vector3(0.0, 1.15, 0.0)
	documento.add_child(panel)

	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_BASE
	material.roughness = 0.9
	panel.material_override = material

	var titulo := Label3D.new()
	titulo.name = "Titulo"
	titulo.position = Vector3(0.0, 1.63, -0.08)
	titulo.font_size = 24
	titulo.pixel_size = 0.0032
	titulo.modulate = COLOR_TEXTO
	titulo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	documento.add_child(titulo)

	var texto := Label3D.new()
	texto.name = "Texto"
	texto.position = Vector3(0.0, 1.05, -0.08)
	texto.font_size = 20
	texto.pixel_size = 0.0028
	texto.modulate = COLOR_TEXTO
	texto.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	documento.add_child(texto)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(2.15, 1.8, 0.45)
	colision.shape = forma
	colision.position = Vector3(0.0, 1.15, 0.0)
	documento.add_child(colision)


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


func _al_activar_documento(_actor: Node, indice: int) -> void:
	if relacion == null:
		return
	var evento := relacion.seleccionar(indice)
	_sincronizar()
	estado_cambiado.emit(evento)


func _al_confirmar(_actor: Node) -> void:
	if relacion == null:
		return
	var evento := relacion.confirmar()
	_sincronizar()
	estado_cambiado.emit(evento)
	if evento == "completado" or evento == "fallado":
		terminado.emit(evento)


func _sincronizar() -> void:
	if relacion == null:
		return
	for indice in range(mini(relacion.documentos.size(), _documentos_3d.size())):
		var dato: Dictionary = relacion.documentos[indice]
		var documento: Interactuable3D = _documentos_3d[indice]
		var titulo := documento.get_node("Titulo") as Label3D
		var texto := documento.get_node("Texto") as Label3D
		var panel := documento.get_node("Panel") as MeshInstance3D
		var seleccionado := relacion.seleccion.has(String(dato.get("id", "")))
		var seleccion_completa := relacion.seleccion.size() >= 2
		titulo.text = "%s · %s" % [dato.get("folio", ""), dato.get("fecha", "")]
		texto.text = String(dato.get("extracto", ""))
		documento.habilitado = (not relacion.cerrada and (not seleccion_completa or seleccionado))
		var material := StandardMaterial3D.new()
		material.albedo_color = COLOR_SELECCION if seleccionado else COLOR_BASE
		material.roughness = 0.9
		panel.material_override = material

	if _confirmar != null:
		_confirmar.habilitado = (
			not relacion.cerrada and relacion.nucleo.pendiente() and relacion.seleccion.size() == 2
		)

	if _estado == null:
		return
	if relacion.nucleo.state == Puzzle.ESTADO_COMPLETADO:
		_estado.text = recompensa_texto
	elif relacion.nucleo.state == Puzzle.ESTADO_FALLADO:
		_estado.text = tr("GATO_SIGA_COMBINACION_FALLIDA")
	elif relacion.nucleo.state == Puzzle.ESTADO_ABANDONADO:
		_estado.visible = false
	elif relacion.seleccion.is_empty():
		_estado.text = tr("VISOR_ELIJA")
	else:
		_estado.text = tr("VISOR_RELACION_DISTINTO")
