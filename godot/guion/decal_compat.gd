## Decals planos para el renderer Compatibility.
##
## Godot no renderiza el nodo `Decal` con `gl_compatibility`, así que las
## manchas y señales transparentes se montan como `Sprite3D`: no tienen
## colisión, no miran a cámara y conservan el alfa de la textura.
##
## El catálogo puede declarar una lista `decals` con entradas como:
##
##     {
##         "archivo": "sbs-stain-03.png",
##         "pos": Vector3(1.2, 1.1, -4.89),
##         "rot": Vector3(0, 0, 0),
##         "ancho": 1.4,
##         "opacidad": 0.55,
##     }
##
## `archivo` se resuelve dentro de `assets/texturas/decals/`. También se puede
## pasar una `ruta` completa `res://...`. La clave `textura` existe para pruebas
## y usos generados en memoria; los assets reales deben entrar por ruta para que
## procedencia/LFS puedan auditarlos.
class_name DecalCompat
extends RefCounted

const CARPETA := "res://assets/texturas/decals/"
const SEPARACION := 0.004


## Monta todos los decals declarados por un espacio.
static func montar_todos(raiz: Node3D, espacio: Dictionary) -> Array[Sprite3D]:
	var montados: Array[Sprite3D] = []
	for entrada in espacio.get("decals", []):
		var decal := montar(raiz, entrada)
		if decal != null:
			montados.append(decal)
	return montados


## Monta un plano transparente, fijo y sin colisión.
##
## `ancho` está expresado en metros y conserva la proporción original del PNG.
## `separacion` desplaza el plano unos milímetros en su normal local para evitar
## z-fighting con el muro/suelo sobre el que se coloca.
static func montar(raiz: Node3D, datos: Dictionary) -> Sprite3D:
	var textura: Texture2D = datos.get("textura", null)
	if textura == null:
		var ruta := String(datos.get("ruta", ""))
		if ruta.is_empty():
			var archivo := String(datos.get("archivo", ""))
			if not archivo.is_empty():
				ruta = CARPETA + archivo
		if ruta.is_empty() or not ResourceLoader.exists(ruta):
			push_warning("Decal omitido: textura inexistente '%s'" % ruta)
			return null
		textura = ResourceLoader.load(ruta, "Texture2D") as Texture2D
		if textura == null:
			push_warning("Decal omitido: no se pudo cargar '%s' como Texture2D" % ruta)
			return null

	var decal := Sprite3D.new()
	decal.texture = textura
	decal.position = datos.get("pos", Vector3.ZERO)
	decal.rotation = datos.get("rot", Vector3.ZERO)
	decal.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	decal.shaded = datos.get("sombreado", true)
	decal.double_sided = datos.get("doble_cara", false)
	decal.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

	var ancho := maxf(float(datos.get("ancho", 1.0)), 0.01)
	decal.pixel_size = ancho / maxf(float(textura.get_width()), 1.0)
	decal.modulate.a = clampf(float(datos.get("opacidad", 1.0)), 0.0, 1.0)

	# Sprite3D vive en su plano XY; +Z es su normal local. Separarlo después de
	# aplicar la rotación funciona igual para pared, suelo o techo.
	var separacion := maxf(float(datos.get("separacion", SEPARACION)), 0.0)
	decal.position += decal.transform.basis.z * separacion

	raiz.add_child(decal)
	return decal
