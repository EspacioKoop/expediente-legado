## Controlador auxiliar del vertical 3D de archivado manual (#157).
##
## No sustituye la escena del día: `dia_clima_app.gd` lo invoca desde sus hooks
## reales de entrada/cierre de SIGA. Así se conserva la raíz histórica de
## `dia.tscn` y la regla de clasificación sigue viviendo en `Archivado` /
## `ArchivadoBandeja`.
class_name ArchivadoSesion3D
extends RefCounted

const RUTA_TEXTOS := "res://datos/archivado_textos.json"
const CLAVE_JORNADA := "archivado_bandeja"

var _estado_archivado: Dictionary = {}
var _carpeta_archivado: CarpetaArchivable3D = null
var _textos: Dictionary = {}


func refrescar(host) -> void:
	var folios_leidos: Array = host.jornada.get("leido_hoy", [])
	var casos := _casos_clasificables(host, folios_leidos)
	if _estado_archivado.is_empty():
		_estado_archivado = _restaurar_o_crear(host, casos, folios_leidos)
	else:
		ArchivadoBandeja.sincronizar(_estado_archivado, casos, folios_leidos)
	_persistir(host)

	var caso := ArchivadoBandeja.siguiente_pendiente(_estado_archivado)
	if caso.is_empty():
		if (
			not _estado_archivado.get("cerrada", false)
			and not _estado_archivado.get("casos", []).is_empty()
		):
			var resumen := ArchivadoBandeja.cerrar(_estado_archivado)
			_persistir(host)
			_mostrar_resultado(host, resumen)
			_guardar(host)
		return

	_configurar_archivadores(host, caso)
	_sincronizar_desorden_espacial(host)
	if is_instance_valid(_carpeta_archivado):
		return
	_montar_carpeta(host, caso)


func abandonar(host, guardar: bool = true) -> Dictionary:
	if _estado_archivado.is_empty():
		return {}
	if ArchivadoBandeja.siguiente_pendiente(_estado_archivado).is_empty():
		return ArchivadoBandeja.resultado(_estado_archivado)
	var resumen := ArchivadoBandeja.abandonar(_estado_archivado)
	_persistir(host)
	if guardar:
		_guardar(host)
	return resumen


func _casos_clasificables(host, folios_leidos: Array) -> Array:
	var casos := []
	for caso in host.contenido.casos:
		if Archivado.es_clasificable(caso, folios_leidos):
			casos.append(caso)
	return casos


func _restaurar_o_crear(host, casos: Array, folios_leidos: Array) -> Dictionary:
	var guardado = host.jornada.get(CLAVE_JORNADA, {})
	if (
		typeof(guardado) == TYPE_DICTIONARY
		and int(guardado.get("dia", -1)) == int(host.jornada.get("dia", 1))
	):
		var estado_guardado = guardado.get("estado", {})
		if typeof(estado_guardado) == TYPE_DICTIONARY:
			return ArchivadoBandeja.restaurar(estado_guardado, host.contenido.casos, folios_leidos)
	return ArchivadoBandeja.nueva(casos, folios_leidos)


func _persistir(host) -> void:
	host.jornada[CLAVE_JORNADA] = {
		"dia": int(host.jornada.get("dia", 1)),
		"estado": ArchivadoBandeja.serializar(_estado_archivado),
	}


func _guardar(host) -> void:
	if host.has_method("_guardar_o_avisar"):
		host.call("_guardar_o_avisar", "")


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
		host._nomina.text = _texto("carpeta_en_mano") % carpeta.destino
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
	var correcta := ArchivadoBandeja.colocar(_estado_archivado, _carpeta_archivado.caso, destino)
	_persistir(host)
	_sincronizar_desorden_espacial(host)
	_guardar(host)
	if not correcta:
		host._nomina.text = _texto("destino_incorrecto")
		_marcar_archivador(archivador, false)
		host._sonar("puerta_cierra")
		return

	host._nomina.text = _texto("carpeta_archivada") % destino
	_marcar_archivador(archivador, true)
	host._sonar("documento")
	_carpeta_archivado.queue_free()
	_carpeta_archivado = null
	refrescar(host)


func _sincronizar_desorden_espacial(host) -> void:
	var desorden := ArchivadoBandeja.desorden_por_destino(_estado_archivado)
	for archivador in _archivadores_del_mundo(host):
		var destino := String(archivador.get_meta("destino_archivado", ""))
		ArchivadoDesorden3D.aplicar(archivador, int(desorden.get(destino, 0)))


func _mostrar_resultado(host, resumen: Dictionary) -> void:
	var porcentaje := int(round(float(resumen.get("precision", 0.0)) * 100.0))
	host._nomina.text = (
		_texto("bandeja_completa")
		% [
			porcentaje,
			String(resumen.get("rango", "sin-datos")),
		]
	)


func _texto(clave: String) -> String:
	if _textos.is_empty():
		var fichero := FileAccess.open(RUTA_TEXTOS, FileAccess.READ)
		if fichero != null:
			var crudo = JSON.parse_string(fichero.get_as_text())
			fichero.close()
			if typeof(crudo) == TYPE_DICTIONARY:
				_textos = crudo
	return String(_textos.get(clave, clave))


func _marcar_archivador(archivador: ArchivadorInteractivo3D, correcto: bool) -> void:
	var rotulo := archivador.get_node_or_null("DestinoArchivado") as Label3D
	if rotulo == null:
		return
	rotulo.modulate = Color(0.55, 0.9, 0.55) if correcto else Color(1.0, 0.48, 0.42)
