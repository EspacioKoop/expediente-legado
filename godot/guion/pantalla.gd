## Pantalla encendida del escaparate (#142).
##
## El contenido está separado de la geometría: una pantalla sin fichero muestra
## nieve; con un fichero de vídeo válido reproduce ese contenido en silencio.
class_name Pantalla
extends RefCounted

const SHADER_NIEVE := "res://arte/nieve.gdshader"
const RESOLUCION := Vector2i(256, 192)


static func montar(raiz: Node3D, declaracion: Dictionary) -> Node3D:
	var vista := SubViewport.new()
	vista.size = RESOLUCION
	vista.disable_3d = true
	vista.transparent_bg = false
	vista.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	raiz.add_child(vista)

	if not _montar_video(vista, String(declaracion.get("fichero", ""))):
		_montar_nieve(vista, float(declaracion.get("semilla", 0.0)))

	var cristal := MeshInstance3D.new()
	var plano := QuadMesh.new()
	plano.size = declaracion.get("tam", Vector2(0.5, 0.38))
	cristal.mesh = plano
	cristal.position = declaracion.get("pos", Vector3.ZERO)
	cristal.rotation_degrees.y = float(declaracion.get("giro", 0.0))
	var cristal_material := StandardMaterial3D.new()
	cristal_material.albedo_texture = vista.get_texture()
	cristal_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cristal_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	cristal.material_override = cristal_material
	raiz.add_child(cristal)
	return cristal


static func _montar_video(vista: SubViewport, fichero: String) -> bool:
	if fichero.is_empty() or not ResourceLoader.exists(fichero):
		return false
	var recurso := load(fichero)
	if not recurso is VideoStream:
		return false

	var video := VideoStreamPlayer.new()
	video.name = "Emision"
	video.stream = recurso
	video.autoplay = true
	video.loop = true
	video.volume_db = -80.0
	video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vista.add_child(video)
	return true


static func _montar_nieve(vista: SubViewport, semilla: float) -> void:
	var lienzo := ColorRect.new()
	lienzo.name = "Nieve"
	lienzo.size = Vector2(RESOLUCION)
	var material := ShaderMaterial.new()
	material.shader = load(SHADER_NIEVE)
	material.set_shader_parameter("semilla", semilla)
	lienzo.material = material
	vista.add_child(lienzo)
