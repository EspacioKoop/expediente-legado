## Contrato común para que la vida fuera de la oficina pueda contaminar el sueño.
##
## Las semillas viven DENTRO de `Jornada`: no hay singleton paralelo ni estado
## que se pierda al guardar. Una interacción deliberada registra una clave
## estable `semilla_onirica_<mito>` y la selección nocturna solo consulta esas
## entradas del día actual.
##
## Este módulo no monta escenas ni decide su presentación. #436–#441 pueden
## consumir la misma salida sin añadir `if mito_x` al generador base.
class_name SemillasOniricas
extends RefCounted

const CAMPO_JORNADA := "semillas_oniricas_hoy"
const PREFIJO_CLAVE := "semilla_onirica_"
const INTENSIDAD_MAX := 3

## Catálogo cerrado de la épica #435. Añadir una familia futura se hace aquí y
## no repartiendo booleanos por casa, trayecto y sueño.
const MITOS_VALIDOS := [
	"gilgamesh",
	"minotauro",
	"aquiles",
	"hidra",
	"dragon_japones",
	"duat",
	"simurgh",
	"yggdrasil",
	"tir_na_nog",
	"mari",
	"baba_yaga",
	"anansi_akan",
	"maui_tamanuitera",
]

## Mezclas excepcionales y declaradas. La existencia de dos semillas no inventa
## automáticamente una combinación procedural: solo estos pares pueden mezclar.
const MEZCLAS_DECLARADAS := {
	"gilgamesh|minotauro": "gilgamesh_minotauro",
}


## Clave persistente que una interacción de vigilia deja en la jornada.
static func clave(id_mito: String) -> String:
	if not MITOS_VALIDOS.has(id_mito):
		return ""
	return PREFIJO_CLAVE + id_mito


## Activa una familia para el día actual.
##
## Repetir la MISMA fuente es idempotente. Fuentes distintas aumentan la
## intensidad hasta `INTENSIDAD_MAX`; la fuente es un id estable de la
## interacción concreta (por ejemplo `RomsPropias.fuente_semilla("uruk_98")` o
## `tv:documental_duat`), no el texto que ve el jugador.
static func activar_semilla_onirica(
	jornada: Dictionary, id_mito: String, fuente: String, intensidad: int = 1
) -> bool:
	var clave_mito := clave(id_mito)
	var fuente_limpia := fuente.strip_edges()
	if clave_mito.is_empty() or fuente_limpia.is_empty() or intensidad <= 0:
		return false

	var estado := _normalizar_dia(jornada)
	if not estado.has(clave_mito):
		estado[clave_mito] = {
			"id_mito": id_mito,
			"fuentes": [],
			"intensidad": 0,
			"activada_en": int(jornada.get("dia", 0)),
		}

	var entrada: Dictionary = estado[clave_mito]
	var fuentes: Array = entrada["fuentes"]
	if fuentes.has(fuente_limpia):
		return true

	fuentes.append(fuente_limpia)
	entrada["intensidad"] = mini(int(entrada.get("intensidad", 0)) + intensidad, INTENSIDAD_MAX)
	return true


## Copia segura de las semillas válidas del día actual.
##
## Llamarlo después de avanzar `jornada.dia` limpia automáticamente las del día
## anterior. Así una partida guardada en mitad de la tarde conserva su estado y
## una jornada nueva nunca hereda semillas temporales por accidente.
static func obtener_semillas(jornada: Dictionary) -> Dictionary:
	return _normalizar_dia(jornada).duplicate(true)


## IDs de familias habilitadas hoy, en orden estable para UI/pruebas.
static func familias_activas(jornada: Dictionary) -> Array[String]:
	var familias: Array[String] = []
	for entrada in _normalizar_dia(jornada).values():
		familias.append(String(entrada.get("id_mito", "")))
	familias.sort()
	return familias


## Borra explícitamente las semillas temporales. Normalmente no hace falta:
## `_normalizar_dia` ya descarta todo lo que no pertenezca a `jornada.dia`.
static func reiniciar_dia(jornada: Dictionary) -> void:
	jornada[CAMPO_JORNADA] = {}


## Selección reproducible de las familias que pueden contaminar esta noche.
##
## - sin semillas devuelve una selección vacía y el sueño base sigue intacto;
## - la intensidad pesa cuando compiten más familias que huecos disponibles;
## - una familia solo puede salir una vez;
## - la mezcla solo existe para pares declarados;
## - `reduccion_movimiento` no participa aquí: cambia presentación, no selección.
static func seleccionar_para_noche(
	jornada: Dictionary, raiz: int = 0, cantidad_maxima: int = 2
) -> Dictionary:
	var estado := _normalizar_dia(jornada)
	var disponibles := familias_activas(jornada)
	var limite := clampi(cantidad_maxima, 0, disponibles.size())
	if limite == 0:
		return {"familias": [], "mezcla": ""}

	var firma := _firma(estado)
	var rng := RandomNumberGenerator.new()
	rng.seed = Azar.derivar_texto(
		raiz, "sueno", "semillas_oniricas|%s" % firma, [int(jornada.get("dia", 0))]
	)

	var elegidas: Array[String] = []
	for _paso in limite:
		var peso_total := 0
		for id_mito in disponibles:
			peso_total += int(estado[clave(id_mito)].get("intensidad", 0))
		if peso_total <= 0:
			break

		var tiro := rng.randi_range(1, peso_total)
		var acumulado := 0
		var elegida := ""
		for id_mito in disponibles:
			acumulado += int(estado[clave(id_mito)].get("intensidad", 0))
			if tiro <= acumulado:
				elegida = id_mito
				break
		if elegida.is_empty():
			break
		elegidas.append(elegida)
		disponibles.erase(elegida)

	return {"familias": elegidas, "mezcla": _mezcla_de(elegidas)}


## Normaliza el estado persistido y, sobre todo, aplica la frontera de día.
## También acepta provisionalmente el formato temprano `{ "gilgamesh": ... }`
## y `fuente` singular para que una rama/save experimental no quede atrapada.
static func _normalizar_dia(jornada: Dictionary) -> Dictionary:
	var dia := int(jornada.get("dia", 0))
	var crudo = jornada.get(CAMPO_JORNADA, {})
	if typeof(crudo) != TYPE_DICTIONARY:
		jornada[CAMPO_JORNADA] = {}
		return jornada[CAMPO_JORNADA]

	var normalizado := {}
	var claves: Array = crudo.keys()
	claves.sort()
	for clave_cruda in claves:
		var valor = crudo[clave_cruda]
		if typeof(valor) != TYPE_DICTIONARY:
			continue
		var entrada: Dictionary = valor
		var clave_texto := String(clave_cruda)
		var id_mito := String(entrada.get("id_mito", ""))
		if id_mito.is_empty():
			if MITOS_VALIDOS.has(clave_texto):
				id_mito = clave_texto
			elif clave_texto.begins_with(PREFIJO_CLAVE):
				id_mito = clave_texto.trim_prefix(PREFIJO_CLAVE)

		var clave_estable := clave(id_mito)
		if clave_estable.is_empty() or int(entrada.get("activada_en", -1)) != dia:
			continue

		var fuentes_crudas = entrada.get("fuentes", [])
		if (
			entrada.has("fuente")
			and (typeof(fuentes_crudas) != TYPE_ARRAY or fuentes_crudas.is_empty())
		):
			fuentes_crudas = [entrada["fuente"]]
		if typeof(fuentes_crudas) != TYPE_ARRAY:
			continue

		var fuentes: Array[String] = []
		for fuente_cruda in fuentes_crudas:
			var fuente := String(fuente_cruda).strip_edges()
			if not fuente.is_empty() and not fuentes.has(fuente):
				fuentes.append(fuente)
		if fuentes.is_empty():
			continue

		var intensidad := clampi(int(entrada.get("intensidad", 0)), 0, INTENSIDAD_MAX)
		if intensidad <= 0:
			continue
		normalizado[clave_estable] = {
			"id_mito": id_mito,
			"fuentes": fuentes,
			"intensidad": intensidad,
			"activada_en": dia,
		}

	jornada[CAMPO_JORNADA] = normalizado
	return normalizado


static func _firma(estado: Dictionary) -> String:
	var partes: Array[String] = []
	var claves: Array = estado.keys()
	claves.sort()
	for clave_mito in claves:
		var entrada: Dictionary = estado[clave_mito]
		var fuentes: Array = entrada.get("fuentes", []).duplicate()
		fuentes.sort()
		(
			partes
			. append(
				(
					"%s:%d:%s"
					% [
						String(clave_mito),
						int(entrada.get("intensidad", 0)),
						",".join(fuentes),
					]
				)
			)
		)
	return ";".join(partes)


static func _mezcla_de(familias: Array[String]) -> String:
	if familias.size() != 2:
		return ""
	var par := familias.duplicate()
	par.sort()
	return String(MEZCLAS_DECLARADAS.get("|".join(par), ""))
