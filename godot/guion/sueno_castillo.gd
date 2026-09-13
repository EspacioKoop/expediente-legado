## Primer vertical reutilizable del castillo onírico (#296).
##
## No importa un pack entero ni decide todavía cuándo aparece el castillo. Toma
## la familia anular de #279 como patio reconocible, fija una selección mínima
## de categorías CC0 verificadas y deriva dos anomalías de presentación de un
## estado explícito y reproducible.
class_name SuenoCastillo
extends RefCounted

const ID := "castillo"
const LICENCIA := "CC0-1.0"
const FUENTE_ARQUITECTURA := "https://valsekamerplant.itch.io/psx-style-going-medieval"
const FUENTE_PROPS := "https://quaternius.com/packs/fantasypropsmegakit.html"

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
		# Al volver al mismo patio, la composición se presenta invertida. La
		{
			# geometría base es la misma: cambia la lectura, no la navegación.
			"retorno_patio":
			{
				"activa": vuelta > 0,
				"giro_grados": 180.0 if vuelta % 2 == 1 else 0.0,
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
