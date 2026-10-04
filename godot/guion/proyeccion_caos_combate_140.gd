## Contrato puro del remate CAOS de la cámara onírica (#140/#2336).
##
## La cinta ya llega resuelta. Esta capa solo decide si hay incidente de público
## y prepara un rival anónimo para el motor común de Juicio por Combate.
class_name ProyeccionCaosCombate140
extends RefCounted

const ESTADO_CAOS := "caos"
const ID_PUBLICO := "publico_proyeccion_caos"
const CLAVE_NOMBRE_PUBLICO := "PROYECCION_CAOS_PUBLICO"
## Con cuatro puntos de apoyo documental, el Juicio común baja la determinación
## rival de 8 a su mínimo de 4: mantiene el remate deliberadamente breve.
const BONO_COMBATE_BREVE := 4


static func debe_abrir(resultado: Dictionary) -> bool:
	var cinta = resultado.get("cinta_onirica", {})
	return typeof(cinta) == TYPE_DICTIONARY and String(cinta.get("estado", "")) == ESTADO_CAOS


static func objetivo_publico() -> Dictionary:
	return {
		"id": ID_PUBLICO,
		"nombre": CLAVE_NOMBRE_PUBLICO,
	}
