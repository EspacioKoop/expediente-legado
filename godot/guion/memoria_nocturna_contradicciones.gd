## Catálogo explícito de contradicciones documentales para la memoria nocturna (#162).
##
## Las reglas solo contienen IDs canónicos ya presentes en el catálogo de casos.
## No se infieren contradicciones desde texto, fechas, similitud ni tipos documentales.
## MemoriaNocturna exige además que las pistas requeridas ya estén descubiertas
## antes de exponer una regla al sueño.
class_name MemoriaNocturnaContradicciones
extends RefCounted

const REGLAS: Array[Dictionary] = [
	{
		"id": "caso1_revision_previa_vs_acta",
		"caso_id": "caso@1",
		"registros": ["memo1@1", "actaContraloria1@1"],
		"pistas_requeridas": ["pista1@1", "pista20@1"],
	},
]


static func todas() -> Array:
	return REGLAS.duplicate(true)
