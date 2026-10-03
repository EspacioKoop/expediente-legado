## Resolución base de las transiciones de fase del día (#2231 / #1761).
##
## Recibe estado y callbacks explícitos del orquestador. No conoce nodos, áreas,
## subclases ni decide si una salida debe aceptarse: esa frontera sigue siendo
## DiaApp._al_pisar_salida y su cadena heredable.
class_name DiaTransicionApp
extends RefCounted


static func resolver(
	fase: String,
	jornada: Dictionary,
	estado_partida: Dictionary,
	acciones: Dictionary,
) -> Dictionary:
	var resultado := {
		"hablando": false,
		"sonido": "",
		"texto": "",
	}
	var traducir: Callable = acciones.get("traducir", Callable())
	var aviso_imprevisto: Callable = acciones.get("aviso_imprevisto", Callable())

	match fase:
		"archivo":
			_llamar(acciones, "registrar_firma")
			Auditorias.resolver_fin_archivo(estado_partida)
			PronosticosAuditoria.resolver_fin_jornada(estado_partida)
			var paga := Jornada.fichar_salida(jornada)
			resultado["sonido"] = "nomina"
			if traducir.is_valid():
				resultado["texto"] = (
					traducir.call("DIA_NOMINA")
					% [
						jornada["dia"],
						paga["bruto"],
						paga["base"],
						paga["por_expedientes"],
						paga["expedientes"],
						paga["dinero"],
					]
				)
		"casa":
			Auditorias.resolver_fin_casa(estado_partida)
			var noche := Jornada.dormir(jornada)
			_llamar(acciones, "aplicar_politica_sueno")
			if traducir.is_valid():
				var aviso_gato: String = String(
					traducir.call("DIA_SIN_GATO_AVISO") if bool(noche["gato_se_fue"]) else ""
				)
				var aviso: String = String(
					aviso_imprevisto.call(noche) if aviso_imprevisto.is_valid() else ""
				)
				resultado["texto"] = (
					traducir.call("DIA_VIVIR")
					% [
						noche["coste"],
						noche["dinero"],
						aviso_gato + String(aviso),
					]
				)
		"sueño":
			var escenas: Array = jornada.get("sueno_escenas", [])
			if not escenas.is_empty():
				escenas.pop_front()
				jornada["sueno_escenas"] = escenas
			if escenas.is_empty():
				_llamar(acciones, "registrar_despertar")
				Auditorias.resolver_fin_sueno(estado_partida, true)
				EcosDespertarRuntime.preparar_despertar(jornada)
				var dia := Jornada.despertar(jornada)
				Prometeo.reiniciar_exposicion_ideologica_diaria(estado_partida)
				if traducir.is_valid():
					resultado["texto"] = traducir.call("DIA_NUEVO") % dia
		_:
			pass
	return resultado


static func _llamar(acciones: Dictionary, nombre: String) -> void:
	var callback: Callable = acciones.get(nombre, Callable())
	if callback.is_valid():
		callback.call()
