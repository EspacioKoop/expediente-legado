## Filtro de pantalla de época opcional (#1270): qué preajustes hay y dónde se
## ponen.
##
## Un único punto monta el filtro en un `WorldEnvironment`: quien crea un mundo
## 3D llama a `aplicar` y se olvida. El entorno queda en un grupo para que el
## menú de opciones pueda cambiar el filtro en vivo sin saber qué mundos hay.
##
## Los preajustes son intensidades y no sliders sueltos: «monitor», «televisor»
## y «VHS» son máquinas que se reconocen, no una mesa de mezclas.
class_name FiltroPantalla
extends RefCounted

const NINGUNO := "ninguno"
const GRUPO := "filtro_pantalla"

## El orden es el del selector del menú. `ninguno` es el valor por defecto.
const PREAJUSTES := {
	NINGUNO: {},
	# El monitor del archivo: barrido fino y apenas color corrido.
	"monitor":
	{
		"lineas": 0.35,
		"sangrado": 0.2,
		"franjas": 0.15,
		"vineta": 0.25,
		"grano": 0.02,
		"temblor": 0.0,
		"desfase_color": 0.1,
		"lineas_pantalla": 360.0,
	},
	# El televisor de casa por antena: más barrido, más color corrido.
	"televisor":
	{
		"lineas": 0.6,
		"sangrado": 0.55,
		"franjas": 0.45,
		"vineta": 0.5,
		"grano": 0.035,
		"temblor": 0.1,
		# Poco: los nombres que flotan sobre la gente son texto del mundo y
		# pasan por el filtro; con más desfase se desdoblaban.
		"desfase_color": 0.15,
		"lineas_pantalla": 240.0,
	},
	# Una cinta de videoclub gastada.
	"vhs":
	{
		"lineas": 0.3,
		"sangrado": 0.7,
		"franjas": 0.4,
		"vineta": 0.35,
		"grano": 0.06,
		"temblor": 1.0,
		"desfase_color": 0.6,
		"lineas_pantalla": 240.0,
	},
}


## Un identificador que no existe vuelve a `ninguno`: unas preferencias viejas o
## tocadas a mano no pueden dejar la pantalla con un filtro a medias.
static func valido(id: Variant) -> String:
	var texto := String(id) if id is String else ""
	return texto if PREAJUSTES.has(texto) else NINGUNO


static func ids() -> Array:
	return PREAJUSTES.keys()


## Pone (o quita) el filtro que piden [param preferencias] en [param entorno].
static func aplicar(entorno: WorldEnvironment, preferencias: Dictionary) -> void:
	if not entorno.is_in_group(GRUPO):
		entorno.add_to_group(GRUPO)
	var id := valido(preferencias.get("filtro_pantalla", NINGUNO))
	if id == NINGUNO:
		entorno.compositor = null
		return
	var efecto := EfectoPantalla98.new()
	efecto.configurar(PREAJUSTES[id], bool(preferencias.get("reduccion_movimiento", false)))
	var compositor := Compositor.new()
	compositor.compositor_effects = [efecto]
	entorno.compositor = compositor


## Vuelve a aplicar el filtro en todos los mundos montados.
static func refrescar(arbol: SceneTree, preferencias: Dictionary) -> void:
	for entorno in arbol.get_nodes_in_group(GRUPO):
		if entorno is WorldEnvironment:
			aplicar(entorno, preferencias)
