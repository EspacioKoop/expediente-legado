## Primer vertical reutilizable del castillo onírico (#296/#284).
##
## No importa un pack entero ni decide todavía cuándo aparece el castillo. Toma
## la familia anular de #279 como patio reconocible, fija una selección mínima
## de categorías CC0 verificadas y deriva anomalías de presentación de un
## estado explícito y reproducible.
class_name SuenoCastillo
extends RefCounted

const ID := "castillo"
const LICENCIA := "CC0-1.0"
const FUENTE_ARQUITECTURA := "https://valsekamerplant.itch.io/psx-style-going-medieval"
const FUENTE_PROPS := "https://quaternius.com/packs/fantasypropsmegakit.html"

## Señal local del códice. No pretende sustituir el prop final: permite que la
## interacción sea localizable mientras #296 no haya incorporado una pieza
## concreta con procedencia/hash/LFS. No añade texto nuevo; solo acompaña una
## frase que el sueño ya estaba autorizado a mostrar.
const COLOR_CODICE := Color(0.72, 0.58, 0.32)
const ENERGIA_CODICE := 0.9
const ALCANCE_CODICE := 3.2

## Las categorías, no nombres de fichero inventados. Los binarios concretos se
## resolverán solo al importar una pieza real con procedencia/hash/LFS.
const SELECCION_MINIMA := [
	{
		"id": "muro_modular",
		"grupo": "arquitectura",
		"categoria": "building_block",
		"fuente": FUENTE_ARQUITECTURA,
		"uso": "cerrar el patio sin convertirlo en corredor ortogonal",
	},
	{
		"id": "puerta_modular",
		"grupo": "arquitectura",
		"categoria": "door",
		"fuente": FUENTE_ARQUITECTURA,
		"uso": "marcar el umbral principal del patio",
	},
	{
		"id": "escalera_modular",
		"grupo": "arquitectura",
		"categoria": "stairs",
		"fuente": FUENTE_ARQUITECTURA,
		"uso": "dar lectura vertical de torre sin exigir salto",
	},
	{
		"id": "codice",
		"grupo": "prop",
		"categoria": "book",
		"fuente": FUENTE_PROPS,
		"uso": "traducir un documento conocido a objeto onírico",
	},
	{
		"id": "cofre",
		"grupo": "prop",
		"categoria": "chest",
		"fuente": FUENTE_PROPS,
		"uso": "contenedor reconocible para interacción ambiental",
	},
	{
		"id": "banco_scriptorium",
		"grupo": "prop",
		"categoria": "furniture",
		"fuente": FUENTE_PROPS,
		"uso": "anclar una zona de lectura sin decoración gratuita",
	},
]


static func configuracion(estado_presentacion: Dictionary = {}) -> Dictionary:
	var familia := SuenoFamilias.de(SuenoFamilias.ANULAR)
	if familia.is_empty():
		return {}

	var vuelta := maxi(0, int(estado_presentacion.get("vuelta_castillo", 0)))
	var semilla := int(estado_presentacion.get("semilla_castillo", 0))
	var anclas: Array = familia.get("anclas", []).duplicate(true)
	var indice_codice := 0
	if not anclas.is_empty():
		indice_codice = posmod(semilla + vuelta, anclas.size())

	return {
		"id": ID,
		"familia": SuenoFamilias.ANULAR,
		"contorno": familia.get("contorno", PackedVector2Array()),
		"hueco": familia.get("hueco", PackedVector2Array()),
		"altura": familia.get("altura", 3.4),
		"entrada": familia.get("entrada", Vector3.ZERO),
		"anclas": anclas,
		"seleccion": SELECCION_MINIMA.duplicate(true),
		"anomalias":
		# Al volver al mismo patio, la entrada reaparece en otra ancla conocida.
		# La geometría no se teletransporta ni se inventan coordenadas fuera de
		# la familia: cambia la lectura del recorrido conservando sitios válidos.
		{
			"retorno_patio":
			{
				"activa": vuelta > 0 and not anclas.is_empty(),
				"entrada":
				(
					anclas[posmod(vuelta, anclas.size())]
					if not anclas.is_empty()
					else familia.get("entrada", Vector3.ZERO)
				),
			},
			# El códice cambia entre anclas conocidas de forma determinista. No
			# crea una pista: solo mueve la representación de un documento que el
			# llamador ya haya autorizado a mostrar.
			"codice_desplazado":
			{
				"activa": not anclas.is_empty(),
				"ancla": anclas[indice_codice] if not anclas.is_empty() else Vector3.ZERO,
			},
		},
	}


## Convierte un espacio ANULAR ya construido por `Sueno.espacio()` en la
## presentación de castillo sin duplicar navegación ni tocar estado jugable.
##
## Este adaptador es deliberadamente independiente de la selección nocturna:
## #279 mantiene ahora reservados `sueno.gd`/`sueno_formas.gd`. Cuando ese corte
## termine, conectar el castillo consiste en llamar a esta función sobre la sala
## `patio`; no hace falta volver a implementar geometría, salida ni contenido.
##
## `contenido_conocido` solo aporta material que el sueño ya obtuvo de #87. Si
## no hay frase conocida, no se crea una interacción de códice vacía ni se
## inventa texto de ambientación.
static func adaptar_espacio(
	espacio_base: Dictionary,
	estado_presentacion: Dictionary = {},
	contenido_conocido: Dictionary = {}
) -> Dictionary:
	if espacio_base.is_empty():
		return {}

	var configurada := configuracion(estado_presentacion)
	if configurada.is_empty():
		return espacio_base.duplicate(true)

	var resultado := espacio_base.duplicate(true)
	resultado["identidad_onirica"] = ID
	resultado["contorno"] = configurada["contorno"]
	resultado["altura_contorno"] = float(configurada.get("altura", 3.4))
	resultado["seleccion_onirica"] = configurada["seleccion"].duplicate(true)
	resultado["anomalias_oniricas"] = configurada["anomalias"].duplicate(true)

	var anomalias: Dictionary = configurada.get("anomalias", {})
	var retorno: Dictionary = anomalias.get("retorno_patio", {})
	if bool(retorno.get("activa", false)):
		resultado["entrada"] = retorno.get("entrada", configurada["entrada"])
	else:
		resultado["entrada"] = configurada["entrada"]

	# Interacción ambiental: el primer fragmento de contenido YA conocido se
	# vuelve una lectura localizada. `Espacio3D` entiende una salida con frase y
	# destino vacío como zona de proximidad; no abre otra fase ni muta progreso.
	var frases: Array = contenido_conocido.get("frases", [])
	var codice: Dictionary = anomalias.get("codice_desplazado", {})
	if not frases.is_empty() and bool(codice.get("activa", false)):
		var ancla_codice: Vector3 = codice.get("ancla", Vector3.ZERO)
		var salidas: Array = resultado.get("salidas", []).duplicate(true)
		(
			salidas
			. append(
				{
					"pos": ancla_codice + Vector3(0, 1.0, 0),
					"destino": "",
					"frase": frases[0],
					"tam": Vector3(2.4, 2.0, 2.4),
					"visible": false,
				}
			)
		)
		resultado["salidas"] = salidas

		# La luz no representa el códice ni añade otro objeto provisional: solo
		# hace legible dónde ocurre la anomalía hasta que haya prop con procedencia.
		var luces: Array = resultado.get("luces", []).duplicate(true)
		(
			luces
			. append(
				{
					"pos": ancla_codice + Vector3(0, 1.4, 0),
					"color": COLOR_CODICE,
					"energia": ENERGIA_CODICE,
					"alcance": ALCANCE_CODICE,
					"carcasa": false,
				}
			)
		)
		resultado["luces"] = luces

	return resultado


static func malla_base() -> ArrayMesh:
	return SuenoFamilias.malla(SuenoFamilias.ANULAR)


static func valida() -> bool:
	if not SuenoFamilias.valida(SuenoFamilias.ANULAR):
		return false
	if SELECCION_MINIMA.size() != 6:
		return false
	for pieza in SELECCION_MINIMA:
		if pieza.get("fuente", "").is_empty() or pieza.get("categoria", "").is_empty():
			return false
	return true
