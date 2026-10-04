## Incidente efímero posterior a una proyección CAOS (#2336 / #140).
##
## Reutiliza JuicioCombate3D como pelea breve contra un público colectivo.
## No recibe Partida ni Jornada: solo una fotografía del estado necesaria para
## preferencias visuales, perfil y semilla determinista.
class_name ProyeccionCaosCombateApp
extends RefCounted

const PUBLICO_CAOS := {
	"id": "publico-caos",
	"nombre": "PÚBLICO ALTERADO",
}
const BONO_BREVE := 4


static func abrir(
	anfitrion: Node,
	estado_partida: Dictionary,
	al_terminar: Callable,
) -> JuicioCombate3D:
	if anfitrion == null or not al_terminar.is_valid():
		return null

	var combate := JuicioCombate3D.new()
	combate.name = "CombatePublicoCaos"
	combate.arquetipo_onirico = JuicioCombateArquetipos.ENJAMBRE
	combate.interaccion_ambiental_habilitada = false

	var preferencias := PreferenciasSiga.cargar()
	var reducir_movimiento := bool(preferencias.get("reduccion_movimiento", false))
	var raiz := int(estado_partida.get("semilla", 0))
	combate.configurar(PUBLICO_CAOS, BONO_BREVE, reducir_movimiento, raiz)

	var perfil = estado_partida.get("perfil_jugador", {})
	if typeof(perfil) == TYPE_DICTIONARY:
		combate.perfil_jugador = (perfil as Dictionary).duplicate(true)

	combate.terminado.connect(al_terminar)
	anfitrion.add_child(combate)
	return combate
