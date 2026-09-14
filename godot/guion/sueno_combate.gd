## Los combates oníricos (#88): pelear, dentro del sueño, con lo que firmaste.
##
## El motor es el mismo `Combate` de siempre. Lo que este módulo decide es lo
## único que hacía falta decidir: **contra quién**, y **qué pasa después**.
##
## - **Contra quién: solo contra los que acusaste.** El sueño como conciencia
##   —te persigue lo que hiciste, no lo que había—, y encaja con la regla
##   general de #79: el sueño no contiene nada que no hayas tocado. Su
##   consecuencia práctica es que una partida donde no has firmado a nadie no
##   tiene combates oníricos, y eso está bien: el sueño de quien no ha firmado
##   nada es un sitio vacío.
## - **Qué pasa después: aquí SÍ pasa algo.** Es la razón de existir de este
##   combate frente al careo. En el careo el veredicto ya está firmado y el
##   duelo no lo cambia, así que ganar no da nada y perder cuesta una vida.
##   Aquí no hay veredicto que respetar, y el trato es simétrico:
##   **ganar devuelve una vida** (con el tope de la dificultad — no es una
##   fuente infinita, porque la única forma de ganar más es firmar más) y
##   **perder corta la noche**, que es despertarse de golpe: el mapa no crece
##   esa noche y las salas que quedaban no se pisan.
##
## Y a quien ganas **deja de aparecer**. Es la consecuencia que se VE, sin
## texto que la explique: la sala donde estaba está vacía la próxima vez. Por
## eso `vencidos` vive en el estado de la partida y no en la jornada — va con
## los veredictos, que tampoco los borra un despido: otra persona en el mismo
## puesto hereda tus firmas, pero no tus pesadillas ya cerradas.
class_name SuenoCombate
extends RefCounted

## El modo del motor. `reactiva` y no `ciclo`: el careo es una escena autorada
## y se juega contra un patrón aprendible, pero esto es tu conciencia y
## contesta a lo último que hiciste. Se puede cebar, y eso es exactamente lo
## que es discutir con uno mismo.
const MODO := "reactiva"

## Dónde se apunta a quién ya has vencido, dentro del estado de la partida.
const CLAVE_VENCIDOS := "sueno_vencidos"


## A quiénes ya has callado.
static func vencidos(estado: Dictionary) -> Array:
	return estado.get(CLAVE_VENCIDOS, [])


## Si esta figura del sueño se deja pelear.
##
## Solo los acusados, y solo una vez: al vencido ya no se le vuelve a ver, así
## que preguntarlo por segunda vez no debería pasar — pero si pasa, la
## respuesta es no.
static func se_pelea(figura: Dictionary, estado: Dictionary) -> bool:
	if not figura.get("acusado", false):
		return false
	return not vencidos(estado).has(figura.get("id", ""))


## Un combate contra esta figura, listo para `Combate.jugar`.
##
## Las cargas son las de siempre (`Historias.cargas`): las decisiones políticas
## de la partida valen aquí igual que en la Ventanilla. El careo no las ofrece
## porque es una escena; esto se juega.
static func nuevo(figura: Dictionary, cargas: Dictionary = {}) -> Dictionary:
	return (
		Combate
		. nuevo(
			MODO,
			{
				"nombre": figura.get("nombre", ""),
				"ataques": figura.get("ataques", []),
			},
			cargas
		)
	)


## Cierra el combate y cobra sus consecuencias. Devuelve qué ha pasado, que es
## lo que la pantalla cuenta.
##
## Muta el estado y la jornada: es el único sitio donde un sueño cambia algo
## fuera del sueño, y por eso está entero aquí y no repartido por la pantalla.
static func resolver(
	estado: Dictionary, jornada: Dictionary, figura: Dictionary, gano: bool
) -> Dictionary:
	if not gano:
		# Perder no cuesta una vida: ya te costó una firmarlo mal, y cobrar dos
		# veces por el mismo acusado convertiría dormir en un riesgo que se
		# esquiva no durmiendo. Lo que cuesta es la noche.
		return {
			"gano": false,
			"vida": int(estado.get("vida", 3)),
			"recuperada": false,
			"dia": Jornada.despertar_de_golpe(jornada),
		}

	var lista: Array = vencidos(estado).duplicate()
	var id: String = figura.get("id", "")
	if not id.is_empty() and not lista.has(id):
		lista.append(id)
	estado[CLAVE_VENCIDOS] = lista

	var tope: int = Acusacion.ajustes(estado)["vidas"]
	var antes := int(estado.get("vida", 3))
	estado["vida"] = mini(tope, antes + 1)
	return {
		"gano": true,
		"vida": int(estado["vida"]),
		"recuperada": estado["vida"] > antes,
		"dia": jornada["dia"],
	}
