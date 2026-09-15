## Carga un set PBR opcional sin romper el fallback procedural de #399.
##
## Un set vive en `res://assets/texturas/pbr/<nombre>/` y puede entrar por LFS
## más tarde. Si no hay albedo, `crear()` devuelve null y el llamador conserva
## su material PSX actual. Normal, roughness y AO son opcionales por separado.
class_name TexturasPBR
extends RefCounted

const SHADER_PBR := "res://arte/psx_pbr.gdshader"
const RAIZ := "res://assets/texturas/pbr/%s/%s"
const EXTENSIONES := [".png", ".jpg", ".jpeg"]


static func hay(nombre: String) -> bool:
	return _cargar(nombre, "albedo") != null


static func crear(
	nombre: String,
	color: Color = Color.WHITE,
	escala: float = 1.0,
	usar_uv: bool = true
) -> ShaderMaterial:
	var albedo := _cargar(nombre, "albedo")
	if albedo == null:
		return null

	var material := ShaderMaterial.new()
	material.shader = load(SHADER_PBR)
	material.set_shader_parameter("color_base", color)
	material.set_shader_parameter("textura", albedo)
	material.set_shader_parameter("escala_textura", escala)
	material.set_shader_parameter("usar_uv", usar_uv)

	var normal := _cargar(nombre, "normal")
	if normal != null:
		material.set_shader_parameter("mapa_normal", normal)
		material.set_shader_parameter("con_normal", true)

	var roughness := _cargar(nombre, "roughness")
	if roughness != null:
		material.set_shader_parameter("mapa_roughness", roughness)
		material.set_shader_parameter("con_roughness", true)

	var ao := _cargar(nombre, "ao")
	if ao != null:
		material.set_shader_parameter("mapa_ao", ao)
		material.set_shader_parameter("con_ao", true)

	return material


static func _cargar(nombre: String, tipo: String) -> Texture2D:
	for extension in EXTENSIONES:
		var ruta := (RAIZ % [nombre, tipo]) + String(extension)
		if not ResourceLoader.exists(ruta):
			continue
		var textura := ResourceLoader.load(ruta, "Texture2D")
		if textura is Texture2D:
			return textura
	return null
