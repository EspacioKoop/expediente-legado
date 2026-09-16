## Integración de los aviones de papel con la jornada (#160).
##
## Mantiene fuera del núcleo de vuelo tres reglas que pertenecen al día:
## - el descanso no aparece en todas las jornadas;
## - una misma oportunidad no reaparece al recargar ni al volver al pasillo;
## - el comentario posterior reutiliza la voz del cuñado y, por tanto, la misma
##   guarda de información de #81.
##
## No gasta acciones, no concede dinero/pistas y no toca dificultad. El sello
## cosmético queda deliberadamente fuera de este corte: la única salida adicional
## es un comentario ambiental.
class_name AvionesPapelDescanso
extends RefCounted

const CICLO_APARICION := 3
const CLAVE_ULTIMO_DIA := "aviones_papel_ultimo_dia"


## La oportunidad existe aproximadamente una de cada tres jornadas. La fórmula
## depende solo de datos guardados de la vida laboral: recargar no vuelve a tirar.
static func disponible(jornada: Dictionary) -> bool:
	if jornada.get("fase", "") != "archivo":
		return false
	var dia := maxi(1, int(jornada.get("dia", 1)))
	if int(jornada.get(CLAVE_ULTIMO_DIA, 0)) == dia:
		return false
	var raiz := int(jornada.get("raiz", 0))
	var vuelta := maxi(1, int(jornada.get("vuelta", 1)))
	return posmod(raiz + vuelta + dia, CICLO_APARICION) == 0


## Consumir la oportunidad solo anota el día. No usa Jornada.gastar_accion ni
## ningún contador económico: abandonar el minijuego sigue sin afectar al ciclo.
static func marcar_jugado(jornada: Dictionary) -> void:
	if jornada.is_empty():
		return
	jornada[CLAVE_ULTIMO_DIA] = maxi(1, int(jornada.get("dia", 1)))


## Cierra la integración de una ronda. El resultado del núcleo se conserva
## intacto y se añade únicamente una frase ambiental ya cubierta por #81.
static func finalizar(jornada: Dictionary, resultado: Dictionary) -> Dictionary:
	marcar_jugado(jornada)
	if resultado.get("abandonada", false):
		return {"comentario": "", "jugado": true}

	var ganador := String(resultado.get("ganador", "empate"))
	var momento := "empate"
	if ganador == "jugador":
		momento = "gana_jugador"
	elif ganador != "empate":
		momento = "gana_rival"
	return {
		"comentario": _comentario_seguro(momento, jornada),
		"jugado": true,
	}


## No mantiene un catálogo paralelo de frases. Selecciona de Cunado.POR_MOMENTO,
## que Cunado.todas_las_frases() ya recorre contra palabras_prohibidas().
static func _comentario_seguro(momento: String, jornada: Dictionary) -> String:
	var claves: Array = Cunado.POR_MOMENTO.get(momento, [])
	if claves.is_empty():
		return ""
	var dia := maxi(1, int(jornada.get("dia", 1)))
	var vuelta := maxi(1, int(jornada.get("vuelta", 1)))
	var indice := posmod(dia + vuelta, claves.size())
	return TranslationServer.translate(String(claves[indice]))
