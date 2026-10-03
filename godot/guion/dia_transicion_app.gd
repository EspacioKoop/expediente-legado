## Resolucion base de transiciones de salida de DiaApp (#2232 / #1761).
##
## Muta solo las fuentes de verdad de dominio en el mismo orden que DiaApp.
## No entra en espacios, no guarda, no traduce texto y no toca UI/camaras/audio.
class_name DiaTransicionApp
extends RefCounted

const MENSAJE_NOMINA := "DIA_NOMINA"
const MENSAJE_VIVIR := "DIA_VIVIR"
const MENSAJE_NUEVO_DIA := "DIA_NUEVO"


static func resolver(
	estado_partida: Dictionary,
	jornada: Dictionary,
	destino: String,
	registrar_firma: Callable,
	aplicar_politica_sueno: Callable,
	registrar_despertar: Callable,
) -> Dictionary:
	var fase_origen := String(jornada.get("fase", ""))
	var resultado := _resultado_base(destino, fase_origen)
	match fase_origen:
		"archivo":
			resultado = _resolver_archivo(
				estado_partida,
				jornada,
				destino,
				registrar_firma,
			)
		"casa":
			resultado = _resolver_casa(
				estado_partida,
				jornada,
				destino,
				aplicar_politica_sueno,
			)
		"sueño":
			resultado = _resolver_sueno(
				estado_partida,
				jornada,
				destino,
				registrar_despertar,
			)
		_:
			pass
	resultado["sonar_puerta"] = String(jornada.get("fase", "")) != "sueño"
	return resultado


static func _resolver_archivo(
	estado_partida: Dictionary,
	jornada: Dictionary,
	destino: String,
	registrar_firma: Callable,
) -> Dictionary:
	var resultado := _resultado_base(destino, "archivo")
	if not registrar_firma.is_valid():
		resultado["resuelto"] = false
		resultado["error"] = "registrar_firma_invalido"
		return resultado

	registrar_firma.call()
	Auditorias.resolver_fin_archivo(estado_partida)
	PronosticosAuditoria.resolver_fin_jornada(estado_partida)
	var paga := Jornada.fichar_salida(jornada)
	resultado["sonido"] = "nomina"
	resultado["mensaje_clave"] = MENSAJE_NOMINA
	resultado["mensaje_args"] = [
		jornada.get("dia", 0),
		paga.get("bruto", 0),
		paga.get("base", 0),
		paga.get("por_expedientes", 0),
		paga.get("expedientes", 0),
		paga.get("dinero", 0),
	]
	resultado["datos"] = {"paga": paga.duplicate(true)}
	return resultado


static func _resolver_casa(
	estado_partida: Dictionary,
	jornada: Dictionary,
	destino: String,
	aplicar_politica_sueno: Callable,
) -> Dictionary:
	var resultado := _resultado_base(destino, "casa")
	if not aplicar_politica_sueno.is_valid():
		resultado["resuelto"] = false
		resultado["error"] = "politica_sueno_invalida"
		return resultado

	Auditorias.resolver_fin_casa(estado_partida)
	var noche := Jornada.dormir(jornada)
	aplicar_politica_sueno.call()
	resultado["mensaje_clave"] = MENSAJE_VIVIR
	resultado["mensaje_args"] = [
		noche.get("coste", 0),
		noche.get("dinero", 0),
	]
	resultado["datos"] = {"noche": noche.duplicate(true)}
	return resultado


static func _resolver_sueno(
	estado_partida: Dictionary,
	jornada: Dictionary,
	destino: String,
	registrar_despertar: Callable,
) -> Dictionary:
	var resultado := _resultado_base(destino, "sueño")
	var valor_escenas = jornada.get("sueno_escenas", null)
	if typeof(valor_escenas) != TYPE_ARRAY or valor_escenas.is_empty():
		resultado["resuelto"] = false
		resultado["error"] = "sueno_sin_escena_actual"
		return resultado

	var escenas: Array = valor_escenas
	if escenas.size() == 1 and not registrar_despertar.is_valid():
		resultado["resuelto"] = false
		resultado["error"] = "registrar_despertar_invalido"
		return resultado

	escenas.pop_front()
	jornada["sueno_escenas"] = escenas
	if not escenas.is_empty():
		return resultado

	registrar_despertar.call()
	Auditorias.resolver_fin_sueno(estado_partida, true)
	EcosDespertarRuntime.preparar_despertar(jornada)
	var dia := Jornada.despertar(jornada)
	Prometeo.reiniciar_exposicion_ideologica_diaria(estado_partida)
	resultado["mensaje_clave"] = MENSAJE_NUEVO_DIA
	resultado["mensaje_args"] = [dia]
	resultado["datos"] = {"dia": dia}
	return resultado


static func _resultado_base(destino: String, fase_origen: String) -> Dictionary:
	return {
		"resuelto": true,
		"error": "",
		"fase_origen": fase_origen,
		"destino": destino,
		"mensaje_clave": "",
		"mensaje_args": [],
		"datos": {},
		"sonido": "",
		"sonar_puerta": false,
	}
