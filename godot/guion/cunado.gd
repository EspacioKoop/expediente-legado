## El compañero que se acerca a mirar.
##
## Aparece en tres superficies: forma parte de la plantilla estable de la oficina,
## se acerca cuando empieza un careo y es la única persona que dice algo cuando
## te reasignan. Es la única voz cotidiana que no es el sistema, y su función es
## **desinflar** sin convertirse en un sistema de pistas.
##
## La regla dura, y hay prueba que la exige: **el cuñado no da información**.
## Ni una de sus frases nombra una jugada, un sospechoso, un folio o una pista,
## ni acierta lo que viene, ni dice qué deberías hacer. En cuanto una lo hiciera
## dejaría de ser un cuñado y pasaría a ser un sistema de ayuda con acento.
##
## Lo que sí hace es tener razón sobre cosas que no importan y equivocarse con
## aplomo sobre las que sí.
class_name Cunado
extends RefCounted

const AL_LLEGAR := [
	"CUNADO_LLEGADA_1",
	"CUNADO_LLEGADA_2",
	"CUNADO_LLEGADA_3",
	"CUNADO_LLEGADA_4",
	"CUNADO_LLEGADA_5",
]

const AL_GANAR_RONDA := [
	"CUNADO_GANA_1",
	"CUNADO_GANA_2",
	"CUNADO_GANA_3",
	"CUNADO_GANA_4",
]

const AL_PERDER_RONDA := [
	"CUNADO_PIERDE_1",
	"CUNADO_PIERDE_2",
	"CUNADO_PIERDE_3",
	"CUNADO_PIERDE_4",
	"CUNADO_PIERDE_5",
]

const AL_EMPATAR := [
	"CUNADO_EMPATE_1",
	"CUNADO_EMPATE_2",
	"CUNADO_EMPATE_3",
]

const AL_GASTAR_HABILIDAD := [
	"CUNADO_HABILIDAD_1",
	"CUNADO_HABILIDAD_2",
	"CUNADO_HABILIDAD_3",
]

const AL_VENCER := [
	"CUNADO_VICTORIA_1",
	"CUNADO_VICTORIA_2",
	"CUNADO_VICTORIA_3",
]

const AL_CAER := [
	"CUNADO_DERROTA_1",
	"CUNADO_DERROTA_2",
	"CUNADO_DERROTA_3",
	"CUNADO_DERROTA_4",
]

## No necesita vocabulario nuevo para el despido: estas tres frases ya forman
## parte de su voz y, fuera del contexto del duelo, siguen siendo deliberadamente
## ambiguas. Reutilizarlas evita que la tercera superficie cree una segunda voz.
const AL_DESPEDIR := [
	"CUNADO_DERROTA_2",
	"CUNADO_PIERDE_4",
	"CUNADO_PIERDE_1",
]

const POR_MOMENTO := {
	"llegada": AL_LLEGAR,
	"gana_jugador": AL_GANAR_RONDA,
	"gana_rival": AL_PERDER_RONDA,
	"empate": AL_EMPATAR,
	"habilidad": AL_GASTAR_HABILIDAD,
	"victoria": AL_VENCER,
	"derrota": AL_CAER,
	"despido": AL_DESPEDIR,
}


## Nombrar una jugada = estar diciéndote qué hacer. Nombrar un sospechoso,
## folio o texto de pista = estar diciéndote dónde mirar. La prueba recorre esta
## lista contra TODO lo que puede decir en oficina, careo y despido.
##
## Se deriva del combate y del catálogo real, no se copia a mano: si aparece
## una jugada, sospechoso o folio nuevo, entra automáticamente en la guarda.
static func palabras_prohibidas() -> Array:
	var palabras := []
	for tipo in Combate.ETIQUETAS:
		_anotar_prohibida(palabras, Combate.etiqueta(tipo))

	var contenido := Contenido.new()
	if contenido.cargar():
		for caso in contenido.casos:
			for sospechoso in caso.get("sospechosos", []):
				_anotar_prohibida(palabras, String(sospechoso.get("nombre", "")))
			for registro in caso.get("registros", []):
				_anotar_prohibida(palabras, String(registro.get("folio", "")))
			for pista in caso.get("pistas", []):
				for campo in ["frase", "descripcion", "texto", "nombre"]:
					_anotar_prohibida(palabras, String(pista.get(campo, "")))
	return palabras


static func _anotar_prohibida(palabras: Array, texto: String) -> void:
	var limpia := texto.strip_edges()
	if limpia.length() < 4:
		return
	if not palabras.has(limpia):
		palabras.append(limpia)
	var minuscula := limpia.to_lower()
	if not palabras.has(minuscula):
		palabras.append(minuscula)


## Lo que dice en un momento dado. [param azar] es el mismo generador del
## combate: el cuñado es ambiente y no debe tener su propia suerte.
static func comentario(momento: String, azar: Callable) -> String:
	var frases: Array = POR_MOMENTO.get(momento, [])
	if frases.is_empty():
		return ""
	return TranslationServer.translate(frases[int(azar.call() * frases.size()) % frases.size()])


## La frase del despido se elige por un dato persistido, no por azar de escena.
## Recargar la misma reasignación no puede hacer que el cuñado cambie de opinión.
static func clave_despido(indice: int) -> String:
	return AL_DESPEDIR[absi(indice) % AL_DESPEDIR.size()]


## Lo que comenta de una ronda, a partir de su crónica. Habla de la habilidad
## si se ha gastado una, porque es lo que un cuñado miraría; si no, del
## resultado.
static func sobre_ronda(ronda: Dictionary, azar: Callable) -> String:
	if not ronda.get("habilidad", "").is_empty():
		return comentario("habilidad", azar)
	return comentario(ronda.get("veredicto", ""), azar)


## Todo lo que puede llegar a decir en las tres superficies. Existe para que la
## prueba pueda recorrerlo entero: una regla sobre lo que se dice solo vale si
## se comprueba sobre TODO lo que se puede decir, no sobre una muestra.
static func todas_las_frases() -> Array:
	var claves := []
	for momento in POR_MOMENTO:
		for clave in POR_MOMENTO[momento]:
			if not claves.has(clave):
				claves.append(clave)
	for clave in Companeros.CUNADO["frases"]:
		if not claves.has(clave):
			claves.append(clave)
	return claves.map(TranslationServer.translate)
