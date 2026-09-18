## Presentación 3D del castillo onírico (#284).
##
## La navegación sigue perteneciendo a la familia ANULAR: esta capa solo viste
## el hueco interior con el patio medieval original de #587 y añade la anomalía
## sonora. No crea colisión paralela ni cambia entrada, salida o progreso.
class_name SuenoCastillo3D
extends RefCounted

const ESCENA_PATIO := preload("res://escenas/suenos/props_284/patio_castillo_onirico.tscn")
const ESCENA_SCRIPTORIUM := preload(
	"res://escenas/suenos/props_284/galeria_scriptorium_castillo.tscn"
)
const ESCENA_TORRE_CAPILLA := preload("res://escenas/suenos/props_284/torre_capilla_castillo.tscn")
const ESCENA_CLAUSTRO := preload("res://escenas/suenos/props_284/claustro_reflejado_castillo.tscn")


static func montar(mundo: Node3D, espacio: Dictionary) -> Node3D:
	if mundo == null or String(espacio.get("identidad_onirica", "")) != SuenoCastillo.ID:
		return null

	var presentacion := Node3D.new()
	presentacion.name = "PresentacionCastillo284"
	mundo.add_child(presentacion)

	# La variante solo cambia la lectura del hueco central. Ninguna composición
	# añade física: el contorno ANULAR sigue siendo la única navegación.
	var variante := String(espacio.get("variante_castillo", "patio"))
	var escena := _escena_para(variante)
	var arquitectura := escena.instantiate() as Node3D
	arquitectura.name = "ArquitecturaCastillo_" + variante
	presentacion.add_child(arquitectura)
	var mutacion := String(espacio.get("mutacion_castillo", "estable"))
	_aplicar_mutacion(arquitectura, mutacion)

	# Los umbrales ya existentes insinúan la siguiente ala mediante ecos de
	# arquitectura propia. Son presentación pura y no cambian la navegación.
	SuenoCastilloUmbrales3D.montar(arquitectura, variante)

	# La evidencia comparativa de #1011 dejó las torres casi en silueta negra.
	# Dos luces locales pertenecen a esta presentación y conservan el carácter
	# nocturno sin tocar el Environment global ni la física ANULAR.
	_montar_luz_identidad(presentacion)

	# La fuente no tiene campana visible. La posición alta y central hace que el
	# sonido pertenezca al patio completo en lugar de delatar un objeto emisor.
	var campanas := AudioStreamPlayer3D.new()
	campanas.name = "CampanasSinFuente"
	campanas.stream = SuenoCastilloAudio.campanadas()
	campanas.position = Vector3(0.0, 5.5, 0.0)
	campanas.volume_db = -14.0
	campanas.unit_size = 7.0
	campanas.max_distance = 52.0
	presentacion.add_child(campanas)

	# Solo las piezas etiquetadas como anomalía responden a las campanadas. La
	# arquitectura principal, el suelo y la física ANULAR permanecen inmóviles.
	var pulso := SuenoCastilloPulso3D.new()
	pulso.name = "PulsoArquitectonico"
	presentacion.add_child(pulso)
	pulso.configurar(arquitectura, campanas)
	campanas.play()

	return presentacion


## La lectura del códice no cambia la sala ni el progreso: solo pone la
## presentación ya montada en un estado visual de respuesta durante esta visita.
static func reaccionar_a_lectura(mundo: Node3D) -> bool:
	if mundo == null:
		return false
	var presentacion := mundo.get_node_or_null("PresentacionCastillo284") as Node3D
	if presentacion == null:
		return false
	var pulso := presentacion.get_node_or_null("PulsoArquitectonico") as SuenoCastilloPulso3D
	if pulso != null:
		pulso.activar_lectura()
	SuenoCastilloUmbrales3D.activar_lectura(presentacion)
	return pulso != null


static func _escena_para(variante: String) -> PackedScene:
	match variante:
		"scriptorium":
			return ESCENA_SCRIPTORIUM
		"torre_capilla":
			return ESCENA_TORRE_CAPILLA
		"claustro_reflejado":
			return ESCENA_CLAUSTRO
		_:
			return ESCENA_PATIO


static func _aplicar_mutacion(arquitectura: Node3D, mutacion: String) -> void:
	match mutacion:
		"desfase":
			arquitectura.position += Vector3(0.65, 0.18, -0.45)
			arquitectura.rotation_degrees.y += 7.0
		"contraccion":
			arquitectura.scale = Vector3(0.92, 1.12, 0.92)
			arquitectura.position.y += 0.12
		"giro":
			arquitectura.rotation_degrees.y += 18.0
			arquitectura.position.y += 0.35
		_:
			pass


static func _montar_luz_identidad(presentacion: Node3D) -> void:
	var patio := OmniLight3D.new()
	patio.name = "LuzPatioCalida"
	patio.position = Vector3(-2.0, 3.6, 1.5)
	patio.light_color = Color(0.92, 0.58, 0.31)
	patio.light_energy = 2.15
	patio.omni_range = 17.0
	patio.shadow_enabled = true
	presentacion.add_child(patio)

	var torres := OmniLight3D.new()
	torres.name = "ContraluzTorres"
	torres.position = Vector3(7.5, 7.2, -7.0)
	torres.light_color = Color(0.38, 0.46, 0.58)
	torres.light_energy = 1.35
	torres.omni_range = 24.0
	presentacion.add_child(torres)
