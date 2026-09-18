## Pantalla encendida del escaparate (#142).
##
## El contenido está separado de la geometría: un vídeo válido tiene prioridad;
## una imagen estática válida se muestra como textura UV; las emisiones CRT
## procedurales y la media luna usan shaders ligeros; cualquier otro caso
## conserva la nieve histórica como fallback.
class_name Pantalla
extends RefCounted

const SHADER_NIEVE := "res://arte/nieve.gdshader"
const SHADER_MEDIA_LUNA := "res://arte/media_luna.gdshader"
const SHADER_EMISION_CRT := "res://arte/emision_crt.gdshader"
const RESOLUCION := Vector2i(256, 192)


static func montar(raiz: Node3D, declaracion: Dictionary) -> Node3D:
	var vista := SubViewport.new()
	vista.size = declaracion.get("resolucion", RESOLUCION)
	vista.disable_3d = true
	vista.transparent_bg = false
	vista.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	raiz.add_child(vista)

	var fichero := String(declaracion.get("fichero", ""))
	if not _montar_video(vista, fichero) and not _montar_imagen(vista, fichero):
		var contenido := String(declaracion.get("contenido", ""))
		var semilla := float(declaracion.get("semilla", 0.0))
		if contenido == "emision_crt":
			_montar_emision_crt(vista, int(declaracion.get("canal", 0)), semilla)
		elif contenido == "media_luna":
			_montar_media_luna(vista, semilla)
		else:
			_montar_nieve(vista, semilla)

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


## Una imagen importada no se convierte en vídeo ni en material especial: se
## dibuja una vez en el mismo plano UV que ya usa el escaparate. Así una carta,
## un cartel o una foto pueden reutilizar esta superficie sin conocer el shader
## ni la geometría que los rodea.
static func _montar_imagen(vista: SubViewport, fichero: String) -> bool:
	if fichero.is_empty() or not ResourceLoader.exists(fichero):
		return false
	var recurso := load(fichero)
	if not recurso is Texture2D:
		return false

	var imagen := TextureRect.new()
	imagen.name = "Imagen"
	imagen.texture = recurso
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_SCALE
	imagen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vista.add_child(imagen)
	vista.render_target_update_mode = SubViewport.UPDATE_ONCE
	return true


static func _montar_emision_crt(vista: SubViewport, canal: int, semilla: float) -> void:
	var lienzo := ColorRect.new()
	lienzo.name = "EmisionCRT"
	lienzo.size = Vector2(vista.size)
	var material := ShaderMaterial.new()
	material.shader = load(SHADER_EMISION_CRT)
	material.set_shader_parameter("canal", clampi(canal, 0, 5))
	material.set_shader_parameter("semilla", semilla)
	lienzo.material = material
	vista.add_child(lienzo)
	# Las seis familias son composiciones estáticas: un render por aparato.
	vista.render_target_update_mode = SubViewport.UPDATE_ONCE


static func _montar_media_luna(vista: SubViewport, semilla: float) -> void:
	var lienzo := ColorRect.new()
	lienzo.name = "MediaLuna"
	lienzo.size = Vector2(vista.size)
	var material := ShaderMaterial.new()
	material.shader = load(SHADER_MEDIA_LUNA)
	material.set_shader_parameter("semilla", semilla)
	lienzo.material = material
	vista.add_child(lienzo)
	# El motivo es estático: se renderiza una vez y no consume un refresco por TV.
	vista.render_target_update_mode = SubViewport.UPDATE_ONCE


static func _montar_nieve(vista: SubViewport, semilla: float) -> void:
	var lienzo := ColorRect.new()
	lienzo.name = "Nieve"
	lienzo.size = Vector2(vista.size)
	var material := ShaderMaterial.new()
	material.shader = load(SHADER_NIEVE)
	material.set_shader_parameter("semilla", semilla)
	lienzo.material = material
	vista.add_child(lienzo)
