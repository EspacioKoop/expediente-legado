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
	if _montado_esta_noche or mundo.has_meta("puzzle_onirico_montado"):
		return

	if _atender_sesion_ecos(dia, mundo):
		return

	var candidato := _candidato(dia)
	if candidato.is_empty():
		return
	_montar_ecos(dia, mundo, candidato)


func _atender_sesion_ecos(dia: Node, mundo: Node3D) -> bool:
	if not SuenoPuzzleSesion.registrada_esta_noche(dia.jornada):
		return false
	var sesion := SuenoPuzzleSesion.actual(dia.jornada)
	if sesion.is_empty() or String(sesion.get("tipo", "")) != SuenoPuzzleSesion.TIPO_ECOS:
		return true
	if SuenoPuzzleSesion.terminal(sesion):
		_montado_esta_noche = true
		return true
	var guardado := _candidato_guardado(dia, sesion)
	if guardado.is_empty():
		return true
	_montar_ecos(dia, mundo, guardado, sesion.get("datos", {}))
	return true


func _montar_ecos(
	dia: Node, mundo: Node3D, candidato: Dictionary, datos_guardados: Dictionary = {}
) -> void:
	var folio := String(candidato.get("folio", ""))
	var frase := String(candidato.get("frase", ""))
	var reward_id := String(candidato.get("reward_id", ""))
	var ecos: Variant = null
	if datos_guardados.is_empty():
		var raiz := (
			Sueno
			. semilla(
				int(dia.jornada.get("dia", 1)),
				dia.jornada.get("leido_hoy", []),
				dia._raiz(),
			)
		)
		ecos = (
			EcosArchivo
			. crear(
				folio,
				frase,
				dia.jornada.get("leido_hoy", []),
				raiz,
				reward_id,
			)
		)
	else:
		ecos = (
			EcosArchivo
			. restaurar(
				datos_guardados,
				frase,
				dia.jornada.get("leido_hoy", []),
			)
		)
	if ecos == null:
		return
	if (
		String(ecos.nucleo.reward_id) != reward_id
		or String(ecos.nucleo.puzzle_id) != "ecos:" + folio
		or ecos.nucleo.source_ids != [folio]
	):
		return
	var caso: Dictionary = candidato.get("caso", {})
	if caso.is_empty() or not dia.has_method("conectar_recompensa_onirica"):
		return
	if not dia.conectar_recompensa_onirica(ecos.nucleo, caso):
		return
	var presentacion = EcosArchivoPresentacion.crear(
		ecos, String(candidato.get("tipo", ""))
	)
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
			String(candidato.get("descripcion", "")),
		)
	):
		vertical.free()
		return
	var caso_id := String(caso.get("id", ""))
	vertical.estado_cambiado.connect(_al_cambiar_ecos.bind(dia, ecos, caso_id, reward_id))
	mundo.add_child(vertical)
	if dia.has_method("registrar_objetivo_puzzle_onirico"):
		dia.call("registrar_objetivo_puzzle_onirico", ecos.nucleo)
	mundo.set_meta("puzzle_onirico_montado", "ecos")
	_ecos_activos = vertical
	_montado_esta_noche = true
	if datos_guardados.is_empty():
		_persistir_ecos(dia, ecos, caso_id, reward_id)


## #89 sí puede recontextualizar una pista aún no descubierta, pero únicamente
## cuando su frase gatillo está literalmente dentro de un registro leído hoy.
## Se priorizan esas recompensas pendientes; si ya no quedan, el mismo vertical
## puede volver a usar una pista conocida sin duplicarla al persistir.
func _candidato(dia: Node) -> Dictionary:
	var leido_hoy: Array = dia.jornada.get("leido_hoy", [])
	if leido_hoy.is_empty():
		return {}
	var descubiertas: Array = dia.partida.estado.get("pistas_descubiertas", [])
	var pendientes: Array = []
	var conocidas: Array = []

	for caso in dia.contenido.casos:
		var registros := {}
		for registro in caso.get("registros", []):
			var folio := String(registro.get("folio", ""))
			var registro_id := String(registro.get("id", ""))
			if folio.is_empty() or registro_id.is_empty() or not leido_hoy.has(folio):
				continue
			registros[registro_id] = registro

		for pista in caso.get("pistas", []):
			# EcosArchivo usa un único documento. Las relaciones de dos registros
			# necesitan otro tipo de puzzle y se mantienen fuera de este vertical.
			if pista.has("registroOrigen2"):
				continue
			var pista_id := String(pista.get("id", ""))
			var origen := String(pista.get("registroOrigen", ""))
			var frase := String(pista.get("fraseGatillo", ""))
			if pista_id.is_empty() or origen.is_empty() or frase.is_empty():
				continue
			if not registros.has(origen):
				continue
			if frase.strip_edges().split(" ", false).size() < EcosArchivo.CANTIDAD_FRAGMENTOS:
				continue

			var registro: Dictionary = registros[origen]
			# El sueño no puede introducir texto que el documento leído no contuviera.
			if not String(registro.get("contenido", "")).contains(frase):
				continue
			var candidato := {
				"folio": String(registro.get("folio", "")),
				"tipo": String(registro.get("tipo", "")),
				"frase": frase,
				"reward_id": pista_id,
				"descripcion": String(pista.get("descripcion", "")),
				"caso": caso,
				"_orden": "%s|%s|%s" % [pista_id, registro.get("folio", ""), frase],
			}
			if descubiertas.has(pista_id):
				conocidas.append(candidato)
			else:
				pendientes.append(candidato)

	var candidatos: Array = pendientes if not pendientes.is_empty() else conocidas
	if candidatos.is_empty():
		return {}
	candidatos.sort_custom(Callable(self, "_candidato_antes"))
	var semilla := (
		Sueno
		. semilla(
			int(dia.jornada.get("dia", 1)),
			leido_hoy,
			dia._raiz(),
		)
	)
	var elegido: Dictionary = candidatos[posmod(semilla, candidatos.size())].duplicate()
	elegido.erase("_orden")
	return elegido


func _candidato_guardado(dia: Node, sesion: Dictionary) -> Dictionary:
	var caso_id := String(sesion.get("caso_id", ""))
	var reward_id := String(sesion.get("reward_id", ""))
	var leido_hoy: Array = dia.jornada.get("leido_hoy", [])
	for caso in dia.contenido.casos:
		if String(caso.get("id", "")) != caso_id:
			continue
		for pista in caso.get("pistas", []):
			if String(pista.get("id", "")) != reward_id or pista.has("registroOrigen2"):
				continue
			var origen := String(pista.get("registroOrigen", ""))
			var frase := String(pista.get("fraseGatillo", ""))
			if frase.strip_edges().split(" ", false).size() < EcosArchivo.CANTIDAD_FRAGMENTOS:
				return {}
			for registro in caso.get("registros", []):
				if String(registro.get("id", "")) != origen:
					continue
				var folio := String(registro.get("folio", ""))
				if not leido_hoy.has(folio):
					return {}
				if not String(registro.get("contenido", "")).contains(frase):
					return {}
				return {
					"folio": folio,
					"tipo": String(registro.get("tipo", "")),
					"frase": frase,
					"reward_id": reward_id,
					"descripcion": String(pista.get("descripcion", "")),
					"caso": caso,
				}
	return {}


func _candidato_antes(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("_orden", "")) < String(b.get("_orden", ""))


func _al_cambiar_ecos(
	_evento: String,
	dia: Node,
	ecos,
	caso_id: String,
	reward_id: String,
) -> void:
	_persistir_ecos(dia, ecos, caso_id, reward_id)


func _persistir_ecos(
	dia: Node,
	ecos,
	caso_id: String,
	reward_id: String,
) -> void:
	if ecos == null:
		return
	if not (
		SuenoPuzzleSesion
		. guardar(
			dia.jornada,
			SuenoPuzzleSesion.TIPO_ECOS,
			caso_id,
			reward_id,
			ecos.serializar(),
		)
	):
		return
	if dia.has_method("_guardar_o_avisar"):
		dia.call("_guardar_o_avisar", "")


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
