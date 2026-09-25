extends SceneTree

## Convierte avatares de Microsoft Rocketbox (MIT) a los `.glb` de
## `assets/modelos/rocketbox/` (#275).
##
## Cada avatar original pesa ~90 MB: un FBX y siete TGA de 2048 px. Aquí se
## reduce a ~1 MB sin tocar malla ni esqueleto: texturas de color, normal y
## opacidad a 1024 px en WebP con pérdida, y materiales PBR montados a mano,
## porque el FBX referencia los TGA por rutas absolutas de la máquina del autor.
## Los mapas specular se descartan; la rugosidad es un valor común.
##
## Uso, con un clon de https://github.com/microsoft/Microsoft-Rocketbox:
## godot4 --headless --path godot --script res://herramientas/convertir_rocketbox.gd -- \
##     /ruta/Microsoft-Rocketbox/Assets/Avatars /ruta/salida Adults/Male_Adult_13 ...
##
## El `.import` de cada `.glb` lleva el `BoneMap` Biped → perfil humanoide con
## `fix_silhouette`: sin él, los clips UAL retuercen los brazos.

const LADO := 1024
const CALIDAD_WEBP := 0.82
const RUGOSIDAD := 0.72
const ESPECULAR := 0.35


func _initialize() -> void:
	var argumentos := OS.get_cmdline_user_args()
	if argumentos.size() < 3:
		push_error("Uso: -- <Assets/Avatars> <salida> <Categoria/Avatar>...")
		quit(2)
		return
	var fallos := 0
	for avatar in argumentos.slice(2):
		if not _convertir(argumentos[0], argumentos[1], String(avatar)):
			fallos += 1
	quit(1 if fallos else 0)


func _convertir(origen: String, salida: String, avatar: String) -> bool:
	var nombre := avatar.get_file()
	var carpeta := origen.path_join(avatar)
	var fbx := FBXDocument.new()
	var estado_fbx := FBXState.new()
	if fbx.append_from_file(carpeta.path_join("Export/%s.fbx" % nombre), estado_fbx) != OK:
		push_error("No se pudo leer %s" % avatar)
		return false
	var escena := fbx.generate_scene(estado_fbx) as Node3D
	root.add_child(escena)
	for instancia in escena.find_children("*", "MeshInstance3D", true, false):
		var malla: ArrayMesh = (instancia as MeshInstance3D).mesh.duplicate()
		for superficie in malla.get_surface_count():
			var original := malla.surface_get_material(superficie)
			var base := String(original.resource_name) if original != null else ""
			malla.surface_set_material(superficie, _material(carpeta.path_join("Textures"), base))
		(instancia as MeshInstance3D).mesh = malla

	var gltf := GLTFDocument.new()
	gltf.image_format = "Lossy WebP"
	gltf.lossy_quality = CALIDAD_WEBP
	var estado := GLTFState.new()
	var destino := salida.path_join("%s.glb" % nombre.to_lower())
	var error := gltf.append_from_scene(escena, estado)
	if error == OK:
		error = gltf.write_to_filesystem(estado, destino)
	escena.free()
	print("%s -> %s (%s)" % [avatar, destino, error_string(error)])
	return error == OK


func _material(texturas: String, base: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = base
	var raiz := texturas.path_join(base)
	var recorte := base.ends_with("_opacity")
	var color := _textura(raiz + "_color.tga", recorte)
	if color == null:
		# Las gafas solo traen color con alfa, sin mapa de color aparte.
		color = _textura(raiz + "_opacity_color.tga", true)
		recorte = color != null
	if color != null:
		material.albedo_texture = color
	var normal := _textura(raiz + "_normal.tga", false)
	if normal != null:
		material.normal_enabled = true
		material.normal_texture = normal
	material.roughness = RUGOSIDAD
	material.metallic_specular = ESPECULAR
	if recorte:
		# Pestañas, cejas, mechones y cristales: recorte duro, sin ordenar
		# transparencias entre figuras.
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		material.alpha_scissor_threshold = 0.5
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _textura(ruta: String, alfa: bool) -> ImageTexture:
	if not FileAccess.file_exists(ruta):
		return null
	var imagen := Image.load_from_file(ruta)
	if imagen == null:
		return null
	imagen.convert(Image.FORMAT_RGBA8 if alfa else Image.FORMAT_RGB8)
	imagen.resize(LADO, LADO, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(imagen)
