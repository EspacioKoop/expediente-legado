extends SceneTree

## #195: los tres marcos de la oficina montan su lámina piramidal real y, si un
## fichero falta, el marco sigue en pie con el relleno neutro.

const TAM_LAMINA := Vector2i(320, 224)

var pasadas := 0
var fallos := 0


func _init() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	CuadrosOficina.montar(mundo)
	var conjunto := mundo.get_node_or_null("CuadrosOficina")
	comprobar("se monta el conjunto", conjunto != null, true)

	var texturas := {}
	for declaracion in CuadrosOficina.CUADROS:
		var nombre := String(declaracion["nombre"])
		var ruta := Cuadros.ruta_textura(declaracion)
		comprobar("%s tiene fichero" % nombre, ResourceLoader.exists(ruta), true)
		var lamina := mundo.get_node_or_null("CuadrosOficina/%s/Lamina" % nombre) as MeshInstance3D
		comprobar("%s tiene lámina" % nombre, lamina != null, true)
		if lamina == null:
			continue
		var material := lamina.material_override as StandardMaterial3D
		var textura := material.albedo_texture if material != null else null
		comprobar("%s usa su textura" % nombre, textura != null, true)
		if textura == null:
			continue
		comprobar("%s carga la ruta declarada" % nombre, textura.resource_path, ruta)
		comprobar("%s conserva el tamaño" % nombre, Vector2i(textura.get_size()), TAM_LAMINA)
		texturas[textura.resource_path] = true
	comprobar("tres láminas distintas", texturas.size(), 3)

	var sin_fichero := {"nombre": "Falta", "textura": "cuadro-que-no-existe.png"}
	comprobar(
		"sin fichero no usa textura", Cuadros.materializar(sin_fichero)["usar_textura"], false
	)

	mundo.free()
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		pasadas += 1
	else:
		fallos += 1
		print("FALLO %s: obtenido %s, esperado %s" % [nombre, obtenido, esperado])
