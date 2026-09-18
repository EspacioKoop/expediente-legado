## Wiring de Relación documental onírica dentro de las salas de sueño (#89).
##
## Tiene prioridad sobre Ecos del archivo cuando existe una relación de dos
## documentos con al menos un distractor leído. El mundo recibe una meta mínima
## para garantizar que solo un puzzle de pistas se monte en la misma sala.
extends Node

var _mundo_montado_id := 0
var _montado_esta_noche := false
var _fase_anterior := ""
var _relacion_activa: SuenoRelacionOnirica3D


func _ready() -> void:
	process_priority = -10


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

	if _atender_sesion_relacion(dia, mundo):
		return

	var candidato := _candidato(dia)
	if candidato.is_empty():
		return
	_montar_relacion(dia, mundo, candidato)


func _atender_sesion_relacion(dia: Node, mundo: Node3D) -> bool:
	if not SuenoPuzzleSesion.registrada_esta_noche(dia.jornada):
		return false
	var sesion := SuenoPuzzleSesion.actual(dia.jornada)
	if sesion.is_empty() or String(sesion.get("tipo", "")) != SuenoPuzzleSesion.TIPO_RELACION:
		return true
	if SuenoPuzzleSesion.terminal(sesion):
		_montado_esta_noche = true
		return true
	var guardado := _candidato_guardado(dia, sesion)
	if guardado.is_empty():
		return true
	_montar_relacion(dia, mundo, guardado, sesion.get("datos", {}))
	return true


func _montar_relacion(
	dia: Node, mundo: Node3D, candidato: Dictionary, datos_guardados: Dictionary = {}
) -> void:
	var caso: Dictionary = candidato.get("caso", {})
	var pista: Dictionary = candidato.get("pista", {})
	var relacion: Variant = null
	if datos_guardados.is_empty():
		var raiz := (
			Sueno
			. semilla(
				int(dia.jornada.get("dia", 1)),
				dia.jornada.get("leido_hoy", []),
				dia._raiz(),
			)
		)
		relacion = RelacionOnirica.crear(
			caso,
			pista,
			dia.jornada.get("leido_hoy", []),
			raiz,
		)
	else:
		relacion = RelacionOnirica.restaurar(
			datos_guardados,
			caso,
			pista,
			dia.jornada.get("leido_hoy", []),
		)
	if relacion == null:
		return
	if not dia.has_method("conectar_recompensa_onirica"):
		return
	if not dia.conectar_recompensa_onirica(relacion.nucleo, caso):
		return

	var vertical := SuenoRelacionOnirica3D.new()
	vertical.name = "RelacionOnirica3D"
	vertical.position = _ancla(dia._espacio_actual)
	if not vertical.configurar(relacion, String(pista.get("descripcion", ""))):
		vertical.free()
		return
	var caso_id := String(caso.get("id", ""))
	var reward_id := String(pista.get("id", ""))
	vertical.estado_cambiado.connect(
		_al_cambiar_relacion.bind(dia, relacion, caso_id, reward_id)
	)
	mundo.add_child(vertical)
	mundo.set_meta("puzzle_onirico_montado", "relacion")
	_relacion_activa = vertical
	_montado_esta_noche = true
	if datos_guardados.is_empty():
		_persistir_relacion(dia, relacion, caso_id, reward_id)


## Una relación solo es jugable si ambos orígenes y al menos un tercer documento
## del mismo caso se leyeron hoy. Sin distractor, elegir la única pareja posible
## no demostraría comprensión.
func _candidato(dia: Node) -> Dictionary:
	var leido_hoy: Array = dia.jornada.get("leido_hoy", [])
	if leido_hoy.size() < RelacionOnirica.MIN_DOCUMENTOS:
		return {}
	var descubiertas: Array = dia.partida.estado.get("pistas_descubiertas", [])
	var pendientes: Array = []
	var conocidas: Array = []

	for caso in dia.contenido.casos:
		var registros_leidos := {}
		for registro in caso.get("registros", []):
			var folio := String(registro.get("folio", ""))
			var registro_id := String(registro.get("id", ""))
			if folio.is_empty() or registro_id.is_empty() or not leido_hoy.has(folio):
				continue
			registros_leidos[registro_id] = registro
		if registros_leidos.size() < RelacionOnirica.MIN_DOCUMENTOS:
			continue

		for pista in caso.get("pistas", []):
			if not pista.has("registroOrigen2"):
				continue
			var pista_id := String(pista.get("id", ""))
			var origen_a := String(pista.get("registroOrigen", ""))
			var origen_b := String(pista.get("registroOrigen2", ""))
			if pista_id.is_empty() or origen_a.is_empty() or origen_b.is_empty():
				continue
			if origen_a == origen_b:
				continue
			if not registros_leidos.has(origen_a) or not registros_leidos.has(origen_b):
				continue

			var candidato := {
				"caso": caso,
				"pista": pista,
				"_orden": "%s|%s" % [String(caso.get("id", "")), pista_id],
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
	for caso in dia.contenido.casos:
		if String(caso.get("id", "")) != caso_id:
			continue
		for pista in caso.get("pistas", []):
			if String(pista.get("id", "")) != reward_id:
				continue
			if not pista.has("registroOrigen2"):
				return {}
			return {"caso": caso, "pista": pista}
	return {}


func _candidato_antes(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("_orden", "")) < String(b.get("_orden", ""))


func _al_cambiar_relacion(
	_evento: String,
	dia: Node,
	relacion,
	caso_id: String,
	reward_id: String,
) -> void:
	_persistir_relacion(dia, relacion, caso_id, reward_id)


func _persistir_relacion(
	dia: Node,
	relacion,
	caso_id: String,
	reward_id: String,
) -> void:
	if relacion == null:
		return
	if not SuenoPuzzleSesion.guardar(
		dia.jornada,
		SuenoPuzzleSesion.TIPO_RELACION,
		caso_id,
		reward_id,
		relacion.serializar(),
	):
		return
	if dia.has_method("_guardar_o_avisar"):
		dia.call("_guardar_o_avisar", "")


func _ancla(espacio: Dictionary) -> Vector3:
	var entrada: Vector3 = espacio.get("entrada", Vector3.ZERO)
	var salidas: Array = espacio.get("salidas", [])
	if salidas.is_empty():
		return entrada + Vector3(0.0, 0.0, -2.5)
	var salida: Vector3 = salidas[0].get("pos", entrada)
	return entrada.lerp(salida, 0.5)


func _abandonar_si_procede() -> void:
	if not is_instance_valid(_relacion_activa):
		_relacion_activa = null
		return
	if _relacion_activa.relacion != null and not _relacion_activa.relacion.cerrada:
		_relacion_activa.abandonar()
	_relacion_activa = null


func relacion_montada_esta_noche() -> bool:
	return _montado_esta_noche
