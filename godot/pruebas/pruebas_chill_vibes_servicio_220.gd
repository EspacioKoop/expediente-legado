extends SceneTree

## #220: con los GLB de Chill Vibes presentes, la zona de servicio de la calle
## monta palé + caja en lugar del trolley procedural. Ese montaje encaja los
## muebles antes de colgarlos del árbol, así que `Modelos._limites` tiene que
## medir igual dentro y fuera de él.

const TOLERANCIA := 0.001

var pasadas := 0
var fallos := 0


func _init() -> void:
	_limites_fuera_del_arbol()
	_zona_de_servicio()
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


## Un nodo intermedio con escala 2 y giro: si se ignorase su transformación, un
## cubo de 1 m mediría 1 m en vez de 2 × 2 × 2.
func _limites_fuera_del_arbol() -> void:
	var raiz := Node3D.new()
	var intermedio := Node3D.new()
	intermedio.transform = Transform3D(Basis(Vector3.UP, PI / 2.0).scaled(Vector3.ONE * 2.0))
	raiz.add_child(intermedio)
	var malla := MeshInstance3D.new()
	malla.mesh = BoxMesh.new()
	malla.position = Vector3(0.5, 0.0, 0.0)
	intermedio.add_child(malla)

	var fuera := Modelos._limites(raiz)
	comprobar(
		"fuera del árbol respeta el nodo intermedio", _cerca(fuera.size, Vector3(2, 2, 2)), true
	)

	root.add_child(raiz)
	raiz.position = Vector3(3.0, 1.0, -4.0)
	var dentro := Modelos._limites(raiz)
	comprobar("dentro y fuera del árbol miden lo mismo", _cerca(dentro.size, fuera.size), true)
	comprobar("y colocan la caja en el mismo sitio", _cerca(dentro.position, fuera.position), true)
	raiz.free()


func _zona_de_servicio() -> void:
	comprobar("los dos GLB aprobados están disponibles", ChillVibesCC0.disponible(), true)
	var zona := IndustrialCC0.crear_zona_servicio()
	var lote := zona.get_node_or_null("ChillVibesServicio")
	comprobar("monta el lote de Chill Vibes", lote != null, true)
	comprobar("y retira el trolley procedural", zona.has_node("PlatformTrolley"), false)
	if lote != null:
		_pieza_encajada(lote, "Pallet", ChillVibesCC0.TAM_PALLET)
		_pieza_encajada(lote, "Crate", ChillVibesCC0.TAM_CRATE)
		_caja_sobre_el_pale(lote)
	zona.free()


## Palé y caja no pueden compartir volumen: la base de la caja queda justo en la
## cara superior del palé y su centro dentro de la huella de este.
func _caja_sobre_el_pale(lote: Node3D) -> void:
	var pale := lote.get_node_or_null("Pallet") as Node3D
	var caja := lote.get_node_or_null("Crate") as Node3D
	if pale == null or caja == null:
		return
	var base_caja := caja.position.y - ChillVibesCC0.TAM_CRATE.y / 2.0
	var tapa_pale := pale.position.y + ChillVibesCC0.TAM_PALLET.y / 2.0
	comprobar(
		"la caja descansa en la tapa del palé", absf(base_caja - tapa_pale) < TOLERANCIA, true
	)
	var desvio := Vector2(caja.position.x - pale.position.x, caja.position.z - pale.position.z)
	var medio_pale := Vector2(ChillVibesCC0.TAM_PALLET.x, ChillVibesCC0.TAM_PALLET.z) / 2.0
	comprobar(
		"y su centro cae dentro del palé",
		absf(desvio.x) < medio_pale.x and absf(desvio.y) < medio_pale.y,
		true
	)


func _pieza_encajada(lote: Node3D, nombre: String, tam: Vector3) -> void:
	var cuerpo := lote.get_node_or_null(nombre) as Node3D
	comprobar("%s montado" % nombre, cuerpo != null and cuerpo.get_child_count() > 0, true)
	if cuerpo == null:
		return
	var caja := Modelos._limites(cuerpo)
	comprobar("%s ocupa su bulto" % nombre, _cerca(caja.size, tam), true)
	# El bulto se centra en el origen del cuerpo: la base queda a -tam.y / 2.
	comprobar(
		"%s apoya en su base" % nombre, absf(caja.position.y + tam.y / 2.0) < TOLERANCIA, true
	)


func _cerca(a: Vector3, b: Vector3) -> bool:
	return (a - b).length() < TOLERANCIA


func comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		pasadas += 1
	else:
		fallos += 1
		print("FALLO %s: obtenido %s, esperado %s" % [nombre, obtenido, esperado])
