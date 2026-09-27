extends SceneTree

const Papeleria := preload("res://guion/papeleria_siga98.gd")
const UtileriaOficina := preload("res://guion/oficina_utileria.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_biblioteca()
	_probar_integracion()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_biblioteca() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	var conjunto := Papeleria.montar_mesa_clasificacion(mundo, 1472)
	var repetido := Papeleria.montar_mesa_clasificacion(mundo, 9999)

	_comprobar(conjunto == repetido, "el montaje es idempotente")
	_comprobar(Papeleria.familias().size() >= 10, "hay al menos diez familias reutilizables")
	_comprobar(int(conjunto.get_meta("familias_visuales", 0)) >= 10, "el conjunto declara sus familias")
	_comprobar(int(conjunto.get_meta("semilla_visual", -1)) == 1472, "la semilla queda trazable")

	for nombre in [
		"FormularioA4",
		"FormularioA5",
		"FormularioMulticopia",
		"CarpetaCartulina",
		"Separadores",
		"SobreInternoDetallado",
		"SelloYTampon",
		"ClipsGrapasNotas",
		"BandejasEntradaSalida",
		"LomosExpediente",
	]:
		_comprobar(conjunto.get_node_or_null(nombre) != null, "existe familia " + nombre)

	_comprobar(
		conjunto.find_children("*", "CollisionShape3D", true, false).is_empty(),
		"la papelería no añade colisiones"
	)
	_comprobar(
		conjunto.find_children("*", "Label3D", true, false).is_empty(),
		"la papelería no introduce texto visible"
	)

	var mallas := conjunto.find_children("*", "MeshInstance3D", true, false)
	_comprobar(mallas.size() >= 45, "la composición gráfica tiene detalle geométrico")
	var texto_malla := false
	for nodo in mallas:
		if (nodo as MeshInstance3D).mesh is TextMesh:
			texto_malla = true
	_comprobar(not texto_malla, "ninguna malla contiene texto")

	var formulario := conjunto.get_node("FormularioA4") as Node3D
	_comprobar(formulario.position.x >= 3.0 and formulario.position.x <= 4.2, "A4 queda sobre la mesa")
	_comprobar(formulario.position.z >= -0.45 and formulario.position.z <= 0.45, "A4 no sobresale en profundidad")
	mundo.queue_free()


func _probar_integracion() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	UtileriaOficina.montar(mundo, 12)
	var conjunto := mundo.get_node_or_null("PapeleriaSiga98")
	_comprobar(conjunto != null, "OficinaUtileria monta la biblioteca en archivo")
	_comprobar(
		mundo.get_node_or_null("MaquinaCafeInteractuable") != null,
		"la papelería no desplaza el montaje de la máquina"
	)
	mundo.queue_free()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO PapeleriaSiga98: " + nombre)
