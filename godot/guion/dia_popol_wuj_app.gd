## Wiring del Popol Wuj al recorrido nocturno real (#655).
##
## La semilla ya se obtiene en trayecto mediante Publicaciones98 (#1111).
## Este controller solo consume la selección común de #442 y monta el vertical
## en la escena nocturna asignada, sin crear otra vía de activación.
extends Node

const ESCALA_SUENO := 0.44

var _mundo_sueno_id := 0
var _sueno_montado_esta_noche := false
var _fase_anterior := ""


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return

	var fase := String(dia.jornada.get("fase", ""))
	if fase != _fase_anterior:
		if fase != "sueño":
			_sueno_montado_esta_noche = false
		_fase_anterior = fase

	if fase != "sueño" or _sueno_montado_esta_noche:
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_sueno_id:
		return
	_mundo_sueno_id = mundo_id

	var seleccion := (
		SemillasOniricas
		. seleccionar_para_noche(
			dia.jornada,
			dia._raiz(),
			MitologiasNoche.MAX_FAMILIAS_NOCHE,
		)
	)
	var familias: Array = seleccion.get("familias", [])
	if not _corresponde_a_esta_escena(dia, familias):
		return

	_montar_sueno(mundo, dia._espacio_actual)
	_sueno_montado_esta_noche = true


func _corresponde_a_esta_escena(dia: Node, familias: Array) -> bool:
	var opciones: Dictionary = dia._opciones_sueno()
	var cantidad := clampi(
		int(opciones.get("cantidad", Sueno.ESCENAS_POR_NOCHE)),
		1,
		SuenoFormas.ids().size(),
	)
	var pendientes: Array = dia.jornada.get("sueno_escenas", [])
	return (
		MitologiasNoche
		. corresponde_a_escena(
			SuenoPopolWuj.ID_MITO,
			familias,
			cantidad,
			pendientes.size(),
		)
	)


func _montar_sueno(mundo: Node3D, espacio: Dictionary) -> void:
	if mundo.get_node_or_null("SuenoPopolWujNoche") != null:
		return

	var sueno := SuenoPopolWuj.new()
	sueno.name = "SuenoPopolWujNoche"
	sueno.preparar()

	for nombre in ["CamaraStandalone", "LuzGeneral"]:
		var nodo := sueno.get_node_or_null(nombre)
		if nodo != null:
			sueno.remove_child(nodo)
			nodo.free()

	sueno.scale = Vector3.ONE * ESCALA_SUENO
	sueno.position = _ancla_entre_entrada_y_salida(espacio)
	mundo.add_child(sueno)
	_montar_hotspots(sueno)


func _montar_hotspots(sueno: SuenoPopolWuj) -> void:
	for elemento in SuenoPopolWuj.ELEMENTOS:
		var contenedor := sueno.get_node_or_null(String(elemento)) as Node3D
		if contenedor == null:
			continue
		var hotspot := Interactuable3D.new()
		hotspot.name = "Interactuar_%s" % String(elemento)
		hotspot.position = Vector3(0.0, 1.15, 0.0)
		hotspot.verbo = Interactuable3D.Verbo.USAR
		hotspot.nombre_objeto = _nombre_elemento(String(elemento))
		hotspot.sonido = Interactuable3D.SIN_SONIDO
		hotspot.collision_mask = 0
		hotspot.activado.connect(_al_intervenir.bind(sueno, String(elemento)))
		contenedor.add_child(hotspot)

		var forma := BoxShape3D.new()
		forma.size = Vector3(1.95, 2.65, 1.65)
		var colision := CollisionShape3D.new()
		colision.name = "Colision"
		colision.shape = forma
		hotspot.add_child(colision)


func _nombre_elemento(elemento: String) -> String:
	if elemento.begins_with("archivo"):
		return "archivador reflejado"
	return "teléfono de eco"


func _al_intervenir(_actor: Node, sueno: SuenoPopolWuj, elemento: String) -> void:
	var reduccion := bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false))
	sueno.intervenir(elemento, reduccion)


func _ancla_entre_entrada_y_salida(espacio: Dictionary) -> Vector3:
	var entrada: Vector3 = espacio.get("entrada", Vector3.ZERO)
	var salidas: Array = espacio.get("salidas", [])
	if salidas.is_empty():
		return entrada
	var salida: Vector3 = salidas[0].get("pos", entrada)
	return entrada.lerp(salida, 0.5)


func sueno_montado_esta_noche() -> bool:
	return _sueno_montado_esta_noche
