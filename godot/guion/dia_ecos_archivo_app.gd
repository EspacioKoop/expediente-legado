## Wiring real de Ecos del archivo dentro de las salas de sueño (#161).
##
## Se monta como máximo una vez por noche, sobre la sala genérica ya creada por
## Dia/Espacio3D. La salida de la sala sigue siendo la de Sueno: este controller
## no añade destinos, puertas ni cuerpos sólidos.
extends Node

var _mundo_montado_id := 0
var _montado_esta_noche := false
var _fase_anterior := ""
var _ecos_activos: SuenoEcosArchivo3D


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return

	var fase := String(dia.jornada.get("fase", ""))
	if fase != _fase_anterior:
		if fase != "sueño":
			_abandonar_si_procede()
			_montado_esta_noche = false
		_fase_anterior = fase
	if fase != "sueño":
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_montado_id:
		return
	_abandonar_si_procede()
	_mundo_montado_id = mundo_id
	if _montado_esta_noche:
		return

	var candidato := _candidato(dia)
	if candidato.is_empty():
		return
	_montar_ecos(dia, mundo, candidato)


func _montar_ecos(dia: Node, mundo: Node3D, candidato: Dictionary) -> void:
	var raiz := (
		Sueno
		. semilla(
			int(dia.jornada.get("dia", 1)),
			dia.jornada.get("leido_hoy", []),
			dia._raiz(),
		)
	)
	var ecos = (
		EcosArchivo
		. crear(
			String(candidato.get("folio", "")),
			String(candidato.get("frase", "")),
			dia.jornada.get("leido_hoy", []),
			raiz,
		)
	)
	var presentacion = EcosArchivoPresentacion.crear(ecos)
	if presentacion == null:
		return

	var vertical := SuenoEcosArchivo3D.new()
	vertical.name = "EcosArchivo3D"
	vertical.position = _ancla(dia._espacio_actual)
	if not (
		vertical
		. configurar(
			presentacion,
			bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false)),
		)
	):
		vertical.free()
		return
	mundo.add_child(vertical)
	_ecos_activos = vertical
	_montado_esta_noche = true


## La lista de frases elegibles sigue siendo propiedad de SuenoContenido: solo
## después de aplicar sus reglas resolvemos de qué folio leído provenía la frase
## escogida. Ordenar antes de derivar el índice evita depender del orden de carga.
func _candidato(dia: Node) -> Dictionary:
	var leido_hoy: Array = dia.jornada.get("leido_hoy", [])
	if leido_hoy.is_empty():
		return {}
	var descubiertas: Array = dia.partida.estado.get("pistas_descubiertas", [])
	var fuentes := (
		SuenoContenido
		. fuentes(
			leido_hoy,
			dia.contenido.casos,
			descubiertas,
			dia.partida.estado.get("veredictos", {}),
			SuenoCombate.vencidos(dia.partida.estado),
		)
	)
	var frases: Array = fuentes.get("frases", []).duplicate()
	if frases.is_empty():
		return {}
	frases.sort()
	var semilla := (
		Sueno
		. semilla(
			int(dia.jornada.get("dia", 1)),
			leido_hoy,
			dia._raiz(),
		)
	)
	var frase := String(frases[posmod(semilla, frases.size())])
	var folio := _folio_de_frase(frase, leido_hoy, descubiertas, dia.contenido.casos)
	if folio.is_empty():
		return {}
	return {"folio": folio, "frase": frase}


func _folio_de_frase(frase: String, leido_hoy: Array, descubiertas: Array, casos: Array) -> String:
	for caso in casos:
		var origenes := {}
		for registro in caso.get("registros", []):
			var folio := String(registro.get("folio", ""))
			if leido_hoy.has(folio):
				origenes[String(registro.get("id", ""))] = folio
		for pista in caso.get("pistas", []):
			if not descubiertas.has(pista.get("id", "")):
				continue
			if String(pista.get("fraseGatillo", "")) != frase:
				continue
			var origen := String(pista.get("registroOrigen", ""))
			if origenes.has(origen):
				return String(origenes[origen])
	return ""


## El vertical queda cerca del centro del recorrido, elevado lo justo para leer
## los paneles. Son Areas y mallas, así que esta ancla no puede bloquear paso.
func _ancla(espacio: Dictionary) -> Vector3:
	var entrada: Vector3 = espacio.get("entrada", Vector3.ZERO)
	var salidas: Array = espacio.get("salidas", [])
	if salidas.is_empty():
		return entrada + Vector3(0.0, 0.0, -2.0)
	var salida: Vector3 = salidas[0].get("pos", entrada)
	return entrada.lerp(salida, 0.5)


func _abandonar_si_procede() -> void:
	if not is_instance_valid(_ecos_activos):
		_ecos_activos = null
		return
	var presentacion = _ecos_activos.presentacion
	if presentacion != null and not presentacion.cerrada:
		_ecos_activos.abandonar()
	_ecos_activos = null


func ecos_montados_esta_noche() -> bool:
	return _montado_esta_noche
