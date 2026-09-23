## Recetas de combinación ya autorizadas por contenido para #955.
##
## Mantiene la lista pequeña y explícita. Cada receta reutiliza objetos reales del
## inventario; no crea un inventario paralelo ni convierte las combinaciones en una
## vía obligatoria de progreso.
class_name CombinacionesObjetosCatalogo
extends RefCounted

const RECETA_PALANCA_CUNA := "palanca_cuna_imposible"


static func recetas() -> Array[Dictionary]:
	var palanca := PropsUtilizablesCC0.objeto_inventario("palanca_kkryy")
	if palanca.is_empty():
		return []

	palanca["nombre"] = "Palanca calzada"
	palanca["descripcion"] = (
		"Has encajado la cuña imposible en el extremo de la palanca. "
		+ "La herramienta sigue sirviendo para forzar, pero ahora conserva la huella del sueño."
	)
	palanca["combinada_con"] = RecompensaOnirica.ID
	palanca["receta_combinacion"] = RECETA_PALANCA_CUNA

	var salida: Array[Dictionary] = []
	salida.append(
		{
			"id": RECETA_PALANCA_CUNA,
			"ingredientes": ["palanca_kkryy", RecompensaOnirica.ID],
			"resultado": palanca,
		}
	)
	return salida
