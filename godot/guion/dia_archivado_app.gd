## Controlador auxiliar del vertical 3D de archivado manual (#157).
##
## No sustituye la escena del día: `dia_clima_app.gd` lo invoca desde sus hooks
## reales de entrada/cierre de SIGA. Así se conserva la raíz histórica de
## `dia.tscn` y la regla de clasificación sigue viviendo en `Archivado` /
## `ArchivadoBandeja`.
class_name ArchivadoSesion3D
extends RefCounted

var _estado_archivado: Dictionary = {}
var _carpeta_archivado: CarpetaArchivable3D = null


func refrescar(host) -> void:
	var caso := _primer_caso_clasificable(host)
	if caso.is_empty():
		return
	if _estado_archivado.is_empty():
		_estado_archivado = ArchivadoBandeja.nueva([caso], host.jornada.get("leido_hoy", []))
	_configurar_archivadores(host, caso)
	if is_instance_valid(_carpeta_archivado):
		return
	if _estado_archivado.get("pendientes", []).is_empty():
		return
	_montar_carpeta(host, caso)


func _primer_caso_clasificable(host) -> Dictionary:
	for caso in host.contenido.casos:
		if Archivado.es_clasificable(caso, host.jornada.get("leido_hoy", [])):
			return caso
	return {}


func _montar_carpeta(host, caso: Dictionary) -> void:
	_carpeta_archivado = CarpetaArchivable3D.new()
	_carpeta_archivado.name = "CarpetaArchivable"
	# Aparece cerca del jugador al levantarse del SIGA: visible, pero fuera del
	# volumen de colisión del cuerpo.
	_carpeta_archivado.position = host._caminante.position + Vector3(0.85, 0.78, -1.05)
	host._mundo.add_child(_carpeta_archivado)
	_carpeta_archivado.configurar(caso)
	_carpeta_archivado.activado.connect(_coger_carpeta.bind(host, _carpeta_archivado))


func _coger_carpeta(actor: Node, host, carpeta: CarpetaArchivable3D) -> void:
	if carpeta != _carpeta_archivado or not is_instance_valid(carpeta):
		return
	if carpeta.llevar(actor):
		host._nomina.text = "Carpeta en mano · busca el archivador %s" % carpeta.destino
		host._sonar("documento")


func _configurar_archivadores(host, caso: Dictionary) -> void:
	var archivadores := _archivadores_del_mundo(host)
	if archivadores.is_empty():
		return
	var destinos := _destinos_visibles(host, Archivado.destino_de(caso), archivadores.size())
	for i in archivadores.size():
		var archivador: ArchivadorInteractivo3D = archivadores[i]
		var destino: String = destinos[i]
		archivador.set_meta("destino_archivado", destino)
		archivador.nombre_objeto = "archivador %s" % destino
		_montar_rotulo_destino(archivador, destino)
		if not bool(archivador.get_meta("archivado_conectado", false)):
			archivador.activado.connect(_archivar_en.bind(host, archivador))
			archivador.set_meta("archivado_conectado", true)


func _archivadores_del_mundo(host) -> Array:
	var resultado := []
	for hijo in host._mundo.get_children():
		if hijo is ArchivadorInteractivo3D:
			resultado.append(hijo)
	resultado.sort_custom(func(a: Node3D, b: Node3D) -> bool: return a.name < b.name)
	return resultado


func _destinos_visibles(host, correcto: String, cantidad: int) -> Array:
	var destinos := []
	for caso in host.contenido.casos:
		var destino := Archivado.destino_de(caso)
		if not destino.is_empty() and not destinos.has(destino):
			destinos.append(destino)
	destinos.sort()
	if not destinos.has(correcto):
		destinos.append(correcto)
	var elegidos := destinos.slice(0, mini(cantidad, destinos.size()))
	if not elegidos.has(correcto) and not elegidos.is_empty():
		elegidos[elegidos.size() - 1] = correcto
	while elegidos.size() < cantidad:
		elegidos.append(correcto)
	return elegidos


func _montar_rotulo_destino(archivador: ArchivadorInteractivo3D, destino: String) -> void:
	var existente := archivador.get_node_or_null("DestinoArchivado") as Label3D
	if existente != null:
		existente.text = destino
		return
	var rotulo := Label3D.new()
	rotulo.name = "DestinoArchivado"
	rotulo.text = destino
	rotulo.font_size = 30
	rotulo.pixel_size = 0.004
	rotulo.position = Vector3(0, 0.72, 0.24)
	rotulo.modulate = Color(0.88, 0.82, 0.62)
	archivador.add_child(rotulo)


func _archivar_en(actor: Node, host, archivador: ArchivadorInteractivo3D) -> void:
	if not is_instance_valid(_carpeta_archivado):
		return
	# Solo colocar si la carpeta ya fue cogida. Mirar/abrir un archivador antes
	# de eso conserva exactamente la interacción de #283.
	if _carpeta_archivado.get_parent() != actor.get_node_or_null("Camara"):
		return
	var destino := String(archivador.get_meta("destino_archivado", ""))
	var correcta := ArchivadoBandeja.colocar(
		_estado_archivado, _carpeta_archivado.caso, destino
	)
	if not correcta:
		host._nomina.text = "Destino incorrecto · la carpeta sigue en tu mano"
		_marcar_archivador(archivador, false)
		host._sonar("puerta_cierra")
		return

	host._nomina.text = "Carpeta archivada · %s" % destino
	_marcar_archivador(archivador, true)
	host._sonar("documento")
	_carpeta_archivado.queue_free()
	_carpeta_archivado = null


func _marcar_archivador(archivador: ArchivadorInteractivo3D, correcto: bool) -> void:
	var rotulo := archivador.get_node_or_null("DestinoArchivado") as Label3D
	if rotulo == null:
		return
	rotulo.modulate = Color(0.55, 0.9, 0.55) if correcto else Color(1.0, 0.48, 0.42)
