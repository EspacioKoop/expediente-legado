## Adaptador del Arconte de Umbral para el host onírico (#2244 / #2220).
##
## No crea reglas nuevas: mantiene una unidad CONTROLADOR y delega runtime,
## geometría y presentación a las autoridades existentes. El host principal
## decidirá después impacto, navegación y selección contextual.
class_name JuicioCombateArconteHost3D
extends RefCounted

const VARIANTE := "arconte_umbral"


static func es_estado(estado: Dictionary) -> bool:
	return String(estado.get("_variante_onirica", "")) == VARIANTE


static func nuevo(anfitrion: Node3D, raiz: int) -> Dictionary:
	if anfitrion == null:
		return {}
	var unidad := JuicioCombateArquetipos.nuevo(
		JuicioCombateArquetipos.CONTROLADOR,
		raiz,
	)
	if unidad.is_empty():
		return {}
	var zonas := JuicioCombateArconte3D.montar_zonas(anfitrion)
	if zonas.is_empty():
		return {}
	return {
		"_variante_onirica": VARIANTE,
		"tipo": JuicioCombateArquetipos.CONTROLADOR,
		"unidad": unidad,
		"zonas": zonas,
		"salida": {},
	}


static func avanzar(
	estado: Dictionary,
	delta: float,
	posicion_rival: Vector3,
	posicion_jugador: Vector3,
	reduccion_movimiento: bool,
	queda_salida_valida: bool = true,
) -> Dictionary:
	if not es_estado(estado):
		return {}
	var unidad: Dictionary = estado.get("unidad", {})
	var zonas: Array = estado.get("zonas", [])
	if unidad.is_empty() or zonas.is_empty():
		return {}

	# Solo el estado mecánico cuenta como presión activa. No se deduce desde
	# materiales/visibilidad, que pertenecen exclusivamente a presentación.
	var zonas_activas := (
		1
		if String(unidad.get("estado", "")) == JuicioCombateArquetipos.ACTIVAR_ZONA
		else 0
	)
	var salida := (
		JuicioCombateArconte3D
		. avanzar(
			unidad,
			delta,
			posicion_rival,
			posicion_jugador,
			zonas,
			zonas_activas,
			queda_salida_valida,
		)
	)
	var nueva: Dictionary = salida.get("unidad", unidad)
	estado["unidad"] = nueva
	estado["salida"] = salida
	return {
		"estado": estado,
		"intencion": String(salida.get("intencion", "")),
		"telegraph": String(salida.get("telegraph", "")),
		"inicio_marca": bool(salida.get("inicio_marca", false)),
		"inicio_zona": bool(salida.get("inicio_zona", false)),
		"zona_activa": bool(salida.get("zona_activa", false)),
		"abrir_ventana": bool(salida.get("abrir_ventana", false)),
		"geometria": salida.get("geometria", {}),
		"presentacion": JuicioCombateArconte3D.presentacion(
			nueva,
			reduccion_movimiento,
		),
	}
