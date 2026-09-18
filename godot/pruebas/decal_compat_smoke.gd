## Smoke test independiente para los decals de Compatibility (#231).
##
##     godot4 --headless --path godot --script pruebas/decal_compat_smoke.gd
extends SceneTree

var fallos := 0


func _init() -> void:
	var raiz := Node3D.new()
	get_root().add_child(raiz)

	var imagen := Image.create(8, 4, false, Image.FORMAT_RGBA8)
	imagen.fill(Color(0.24, 0.19, 0.14, 0.5))
	var textura := ImageTexture.create_from_image(imagen)

	var decal := (
		DecalCompat
		. montar(
			raiz,
			{
				"textura": textura,
				"pos": Vector3(1.0, 2.0, 3.0),
				"ancho": 2.0,
				"opacidad": 0.4,
				"separacion": 0.01,
			}
		)
	)

	comprobar("se crea Sprite3D", decal != null)
	comprobar("se monta bajo la raíz", raiz.get_child_count() == 1)
	comprobar("conserva la textura RGBA", decal.texture == textura)
	comprobar("no sigue a la cámara", decal.billboard == BaseMaterial3D.BILLBOARD_DISABLED)
	comprobar("respeta ancho en metros", is_equal_approx(decal.pixel_size, 0.25))
	comprobar("respeta opacidad", is_equal_approx(decal.modulate.a, 0.4))
	comprobar("se separa de la superficie", decal.position.z > 3.0)

	var antes := raiz.get_child_count()
	var inexistente := DecalCompat.montar(
		raiz, {"ruta": "res://assets/texturas/decals/no-existe.png"}
	)
	comprobar("un recurso ausente no crea nodo", inexistente == null)
	comprobar("un recurso ausente no ensucia el árbol", raiz.get_child_count() == antes)

	var mundo := Node3D.new()
	get_root().add_child(mundo)
	Espacio3D.construir(
		mundo,
		{
			"suelo": Vector2(2.0, 2.0),
			"techo": false,
			"decals":
			[
				{
					"textura": textura,
					"pos": Vector3(0.0, 1.0, -1.0),
					"ancho": 1.0,
				}
			],
		}
	)
	var montados := mundo.find_children("*", "Sprite3D", true, false)
	comprobar("Espacio3D consume la colección decals", montados.size() == 1)
	mundo.free()

	raiz.free()
	print("decal_compat_smoke: %d fallos" % fallos)
	quit(1 if fallos > 0 else 0)


func comprobar(nombre: String, condicion: bool) -> void:
	if condicion:
		print("  OK  %s" % nombre)
		return
	fallos += 1
	printerr("FALLO %s" % nombre)
