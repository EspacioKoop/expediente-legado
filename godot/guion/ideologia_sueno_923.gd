## Adaptador onírico del contrato ideológico común (#923).
##
## No traduce ejes políticos a colores o iconos. Lee únicamente etiquetas
## semánticas que ya fueron registradas por una elección o una exposición y
## las convierte en familias de comportamiento reutilizables por la gramática
## del sueño. Elección y exposición siguen siendo canales distintos.
class_name IdeologiaSueno923
extends RefCounted

const CANAL_ELECCION := "eleccion"
const CANAL_EXPOSICION := "exposicion"

## Las claves describen una relación o comportamiento, no una ideología.
## Los tags proceden de contenido ya existente (#919/#922/#924).
const FAMILIAS := {
	"reparto":
	{
		"etiquetas":
		[
			"responsabilidad_colectiva",
			"control_interno",
			"organizacion_colectiva",
			"servicios_compartidos",
			"reparto",
		],
		"regla": "distribuir",
		"parametros":
		{
			"resplandor_fuerza": 0.36,
			"estrellas_secundarias": 0.58,
		},
	},
	"procedimiento":
	{
		"etiquetas":
		[
			"garantias_procedimiento",
			"revision_institucional",
			"procedimiento",
			"evaluacion",
			"seguimiento",
			"continuidad_institucional",
		],
		"regla": "capas",
		"parametros":
		{
			"cirros": 0.48,
			"luz_lunar_nubes": 0.42,
			"bandas": 30.0,
		},
	},
	"negociacion":
	{
		"etiquetas":
		[
			"conciliacion",
			"acuerdo_interno",
			"negociacion",
			"contraste_de_posiciones",
			"mediacion",
		],
		"regla": "equilibrar",
		"parametros":
		{
			"ocaso_mezcla": 0.31,
			"bruma_fuerza": 0.44,
			"luna_halo": 0.15,
		},
	},
	"riesgo":
	{
		"etiquetas":
		[
			"costes",
			"eficiencia",
			"actividad_empresarial",
			"competencia",
			"contrato",
			"riesgo",
		],
		"regla": "desplazar",
		"parametros":
		{
			"nubes": 0.18,
			"estrellas": 0.72,
			"via_lactea": 0.08,
		},
	},
}


static func modificadores(
	estado: Dictionary,
	jornada_actual: int,
	raiz_azar: int,
	reduccion_movimiento: bool = false,
) -> Array:
	var resultado := []
	var familias_eleccion := _familias_de_eventos(Prometeo.elecciones_ideologicas(estado))
	var eleccion := _elegir_familia(
		familias_eleccion,
		raiz_azar,
		jornada_actual,
		CANAL_ELECCION,
	)
	if not eleccion.is_empty():
		resultado.append(_modificador(eleccion, CANAL_ELECCION, reduccion_movimiento))

	var exposiciones = estado.get(Prometeo.CLAVE_EXPOSICION_IDEOLOGICA, [])
	if typeof(exposiciones) == TYPE_ARRAY:
		var del_dia := []
		for evento_crudo in exposiciones:
			if typeof(evento_crudo) != TYPE_DICTIONARY:
				continue
			var evento: Dictionary = evento_crudo
			if int(evento.get("jornada", -1)) == jornada_actual:
				del_dia.append(evento)
		var familias_exposicion := _familias_de_eventos(del_dia)
		var exposicion := _elegir_familia(
			familias_exposicion,
			raiz_azar,
			jornada_actual,
			CANAL_EXPOSICION,
		)
		if not exposicion.is_empty():
			resultado.append(_modificador(exposicion, CANAL_EXPOSICION, reduccion_movimiento))
	return resultado


static func _familias_de_eventos(eventos: Array) -> Array:
	var encontradas := []
	for evento_crudo in eventos:
		if typeof(evento_crudo) != TYPE_DICTIONARY:
			continue
		var evento: Dictionary = evento_crudo
		var etiquetas = evento.get("etiquetas", [])
		if typeof(etiquetas) != TYPE_ARRAY:
			continue
		for etiqueta in etiquetas:
			var normalizada := _normalizar_etiqueta(String(etiqueta))
			for familia in FAMILIAS:
				var candidatas: Array = FAMILIAS[familia].get("etiquetas", [])
				if candidatas.has(normalizada) and not encontradas.has(familia):
					encontradas.append(familia)
	encontradas.sort()
	return encontradas


static func _elegir_familia(
	familias: Array,
	raiz_azar: int,
	jornada_actual: int,
	canal: String,
) -> String:
	if familias.is_empty():
		return ""
	var semilla := (
		Azar
		. derivar_texto(
			raiz_azar,
			"sueno",
			"ideologia:%s" % canal,
			[jornada_actual],
		)
	)
	return String(familias[posmod(semilla, familias.size())])


static func _modificador(
	familia: String,
	canal: String,
	reduccion_movimiento: bool,
) -> Dictionary:
	var definicion: Dictionary = FAMILIAS.get(familia, {})
	var parametros: Dictionary = definicion.get("parametros", {}).duplicate(true)
	if reduccion_movimiento:
		parametros = _reducir_movimiento(parametros)
	return {
		"origen": "ideologia:%s:%s" % [canal, familia],
		"prioridad": 55 if canal == CANAL_ELECCION else 65,
		"canal": canal,
		"familia": familia,
		# Exposición puede cambiar lenguaje visual, nunca regla estructural.
		"regla": String(definicion.get("regla", "")) if canal == CANAL_ELECCION else "",
		"parametros": parametros,
	}


static func _normalizar_etiqueta(valor: String) -> String:
	var texto := valor.strip_edges().to_lower()
	for origen in ["á", "é", "í", "ó", "ú", "ü"]:
		var destino := {"á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u", "ü": "u"}[origen]
		texto = texto.replace(origen, destino)
	return texto.replace(" ", "_").replace("-", "_")


static func _reducir_movimiento(parametros: Dictionary) -> Dictionary:
	var reducido := parametros.duplicate(true)
	for clave in ["cirros", "nubes", "luz_lunar_nubes"]:
		if reducido.has(clave):
			reducido[clave] = float(reducido[clave]) * 0.55
	return reducido
