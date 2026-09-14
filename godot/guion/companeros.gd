## Quién se sienta en las otras mesas.
##
## La planta 4 tenía cuatro mesas idénticas y nadie en ellas. Con gente deja de
## ser un decorado, y lo que la hace interesante es que **no sea la misma gente
## cada vuelta**: te reasignan, empiezas otra vida laboral, y los de al lado son
## otros. La única constante es el cuñado, igual que el gato.
##
## **Ninguno da información.** Es la regla de `Cunado` extendida a todos: un
## compañero que nombre un documento o un sospechoso es un sistema de pistas con
## silla. Hay prueba que recorre todo lo que pueden decir.
##
## El roster mezcla dos vetas a propósito. Una son arquetipos de oficina de
## 1998. La otra es gente REAL que de verdad acabó archivando —Puyi, que tras la
## reeducación trabajó de archivero y editor en Pekín; Melville, diecinueve años
## de inspector de aduanas; Pessoa, auxiliar de correspondencia comercial;
## Cavafis, treinta años en el Departamento de Riegos; Rousseau, toda la vida en
## un fielato pintando selvas que no vio— y de ninguno hace falta inventar nada,
## que es lo que hace que el chiste aguante. Aquí no se les nombra: se les
## reconoce, o no, y las dos cosas están bien.
class_name Companeros
extends RefCounted

## Cuántos se sientan alrededor, sin contar al cuñado.
const POR_VUELTA := 3

## El cuerpo, uno para todos.
##
## Once mallas distintas serían once descargas de dos megas para que la
## diferencia entre dos oficinistas sea el corte del pelo. Lo que distingue a
## estos es otra cosa: el color de la ropa, que declara cada uno, y la CARA, que
## cinco de ellos tienen y es la suya de verdad. Reutilizar el cuerpo y cambiar
## la cara es además cómo se resolvía esto en la máquina que el juego imita.
const CUERPO := "persona"

## El que está siempre. No entra en el sorteo.
const CUNADO := {
	"id": "cunado",
	"nombre": "COMPA_CUNADO",
	"frases": ["COMPA_CUNADO_1", "COMPA_CUNADO_2", "COMPA_CUNADO_3"],
	"color": Color(0.34, 0.33, 0.31),
}

const ROSTER := [
	# --- Los que fueron alguien ---
	{
		"id": "emperador",
		"retrato": "emperador",
		"nombre": "COMPA_EMPERADOR",
		"frases": ["COMPA_EMPERADOR_1", "COMPA_EMPERADOR_2", "COMPA_EMPERADOR_3"],
		"color": Color(0.30, 0.28, 0.30),
	},
	{
		"id": "aduanero_ny",
		"retrato": "aduanero_ny",
		"nombre": "COMPA_ADUANERO_NY",
		"frases": ["COMPA_ADUANERO_NY_1", "COMPA_ADUANERO_NY_2", "COMPA_ADUANERO_NY_3"],
		"color": Color(0.28, 0.29, 0.33),
	},
	{
		"id": "correspondencia",
		"retrato": "correspondencia",
		"nombre": "COMPA_CORRESPONDENCIA",
		"frases": ["COMPA_CORRESPONDENCIA_1", "COMPA_CORRESPONDENCIA_2", "COMPA_CORRESPONDENCIA_3"],
		"color": Color(0.31, 0.30, 0.33),
	},
	{
		"id": "riegos",
		"retrato": "riegos",
		"nombre": "COMPA_RIEGOS",
		"frases": ["COMPA_RIEGOS_1", "COMPA_RIEGOS_2", "COMPA_RIEGOS_3"],
		"color": Color(0.33, 0.32, 0.29),
	},
	{
		"id": "fielato",
		"retrato": "fielato",
		"nombre": "COMPA_FIELATO",
		"frases": ["COMPA_FIELATO_1", "COMPA_FIELATO_2", "COMPA_FIELATO_3"],
		"color": Color(0.29, 0.32, 0.30),
	},
	# --- Los de siempre ---
	{
		"id": "becario",
		"nombre": "COMPA_BECARIO",
		"frases": ["COMPA_BECARIO_1", "COMPA_BECARIO_2", "COMPA_BECARIO_3"],
		"color": Color(0.32, 0.31, 0.34),
	},
	{
		"id": "jubilacion",
		"nombre": "COMPA_JUBILACION",
		"frases": ["COMPA_JUBILACION_1", "COMPA_JUBILACION_2", "COMPA_JUBILACION_3"],
		"color": Color(0.34, 0.30, 0.28),
	},
	{
		"id": "mesa_de_en_medio",
		"nombre": "COMPA_EN_MEDIO",
		"frases": ["COMPA_EN_MEDIO_1", "COMPA_EN_MEDIO_2", "COMPA_EN_MEDIO_3"],
		"color": Color(0.30, 0.30, 0.30),
	},
	{
		"id": "telefono",
		"nombre": "COMPA_TELEFONO",
		"frases": ["COMPA_TELEFONO_1", "COMPA_TELEFONO_2", "COMPA_TELEFONO_3"],
		"color": Color(0.33, 0.29, 0.31),
	},
]


## Quiénes están esta vida laboral. El cuñado el primero, siempre.
##
## Determinista por [param semilla], que se guarda en la partida: la misma
## vuelta tiene siempre los mismos compañeros y volver a cargar no los cambia.
## Si cambiaran al recargar, la planta 4 sería un generador de gente y no una
## oficina.
static func plantilla(semilla: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var sorteo := ROSTER.duplicate()
	for i in range(sorteo.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var guardado = sorteo[i]
		sorteo[i] = sorteo[j]
		sorteo[j] = guardado
	return [CUNADO] + sorteo.slice(0, mini(POR_VUELTA, sorteo.size()))


## Quiénes fueron antes, para ponerles su cara.
##
## Cinco del roster existieron y acabaron de oficinistas: Puyi ordenando papeles
## después de haber sido emperador, Melville diecinueve años de inspector de
## aduanas, Pessoa en la correspondencia comercial, el aduanero Rousseau
## pintando selvas que no vio, Cavafis treinta años en la Oficina de Riegos de
## Alejandría. Sus frases solo funcionan si se les reconoce, así que el retrato
## se declara AQUÍ, al lado de quien es: al revés que el cuerpo, que se deriva
## porque da igual cuál toque.
## Qué cuerpo tiene alguien: el de todos, salvo que no sea nadie.
##
## Sigue siendo una función y no una constante suelta porque quien la llama no
## tiene por qué saber que hoy hay un solo cuerpo. El día que haya varios, cambia
## aquí y no en la oficina.
static func cuerpo_de(companero: Dictionary) -> String:
	return "" if String(companero.get("id", "")).is_empty() else CUERPO


## Lo que dice hoy. Rota con el día y no al azar: alguien que dijera otra cosa
## cada vez que pasas por delante no está hablando, está sorteando.
static func frase_de(companero: Dictionary, dia: int) -> String:
	var frases: Array = companero["frases"]
	if frases.is_empty():
		return ""
	return frases[maxi(dia - 1, 0) % frases.size()]


## Todo lo que la plantilla puede llegar a decir. Existe para que la prueba lo
## recorra ENTERO: una regla sobre lo que se dice solo vale si se comprueba
## sobre todo lo que se puede decir.
static func todas_las_frases() -> Array:
	var todas := []
	for quien in [CUNADO] + ROSTER:
		for clave in quien["frases"]:
			todas.append(TranslationServer.translate(clave))
	return todas
