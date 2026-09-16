## Malla de navegación de un espacio del día (#400).
##
## Los muebles de `EspaciosCatalogo` ya son `StaticBody3D` con su caja de
## colisión (`Espacio3D`): la malla se hornea de ellos al montar el mundo, así
## que mover una mesa en el catálogo mueve también por dónde se puede pasar, sin
## una segunda lista de pasillos que mantener.
class_name NavegacionOficina
extends RefCounted

## Holgura alrededor de cada mueble: medio hombro de una figura de `persona.fbx`.
const RADIO_AGENTE := 0.3
const ALTURA_AGENTE := 1.7
## Un escalón de más y la figura se subiría a una silla o a un tablero.
const ESCALON := 0.1
const CELDA := 0.1


## Hornea la malla del [param mundo] y la cuelga de él. Síncrono: la oficina son
## unas decenas de cajas y hornearla cuesta menos que montarla.
static func montar(mundo: Node3D) -> NavigationRegion3D:
	var malla := NavigationMesh.new()
	malla.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	malla.agent_radius = RADIO_AGENTE
	malla.agent_height = ALTURA_AGENTE
	malla.agent_max_climb = ESCALON
	malla.cell_size = CELDA
	malla.cell_height = CELDA
	var fuente := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(malla, fuente, mundo)
	NavigationServer3D.bake_from_source_geometry_data(malla, fuente)

	var region := NavigationRegion3D.new()
	region.name = "NavegacionOficina"
	region.navigation_mesh = malla
	mundo.add_child(region)
	var mapa := region.get_navigation_map()
	NavigationServer3D.map_set_cell_size(mapa, CELDA)
	NavigationServer3D.map_set_cell_height(mapa, CELDA)
	return region


## Camino por el suelo entre dos puntos. Vacío si la malla aún no está lista o
## no hay forma de llegar: quien pide la ruta decide qué hacer entonces.
static func ruta(region: NavigationRegion3D, desde: Vector3, hasta: Vector3) -> PackedVector3Array:
	if not is_instance_valid(region) or not region.is_inside_tree():
		return PackedVector3Array()
	var mapa := region.get_navigation_map()
	NavigationServer3D.map_force_update(mapa)
	return NavigationServer3D.map_get_path(mapa, desde, hasta, true)
