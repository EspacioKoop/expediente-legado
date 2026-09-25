## Contrato de los efectos ligeros de ambiente: presupuesto cerrado, cada efecto
## donde toca, sin duplicarse al rehacer la fase, y quietos o fuera con
## reducción de movimiento.
extends SceneTree

## Tope de partículas vivas que puede sumar un espacio: menos que una décima
## parte de la lluvia exterior.
const PRESUPUESTO := (
	EfectosLigeros.PARTICULAS_VAPOR * EfectosLigeros.MAX_TAZAS
	+ (EfectosLigeros.PARTICULAS_POLVO * EfectosLigeros.MAX_LUCES_POLVO)
)

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	_probar_interior()
	_probar_calle_con_lluvia()
	_probar_reduccion()
	_probar_sin_nada()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _mundo() -> Node3D:
	var mundo := Node3D.new()
	root.add_child(mundo)
	# Como en la oficina: cada taza cuelga de su puesto.
	for i in 12:
		var puesto := Node3D.new()
		puesto.position = Vector3(i, 0, 0)
		mundo.add_child(puesto)
		var taza := MeshInstance3D.new()
		taza.name = "TazaPuesto"
		taza.position = Vector3(0, 0.86, 0)
		puesto.add_child(taza)
	var foco := SpotLight3D.new()
	foco.light_energy = 1.2
	foco.position = Vector3(0, 3, 0)
	mundo.add_child(foco)
	for i in 5:
		var punto := OmniLight3D.new()
		punto.light_energy = 0.9
		mundo.add_child(punto)
	var tenue := OmniLight3D.new()
	tenue.light_energy = 0.2
	mundo.add_child(tenue)
	var sol := DirectionalLight3D.new()
	mundo.add_child(sol)
	var cristal := MeshInstance3D.new()
	cristal.name = "CristalVista3D"
	var quad := QuadMesh.new()
	quad.size = Vector2(1.2, 0.9)
	cristal.mesh = quad
	mundo.add_child(cristal)
	return mundo


func _probar_interior() -> void:
	var mundo := _mundo()
	var raiz := EfectosLigeros.montar(mundo, "archivo", Clima.DESPEJADO, false)
	_comprobar(raiz != null, "un interior con tazas y luces lleva efectos")
	var vapores := mundo.find_children(EfectosLigeros.NOMBRE_VAPOR, "GPUParticles3D", true, false)
	var polvos := raiz.find_children("Polvo*", "GPUParticles3D", false, false)
	_comprobar(vapores.size() == EfectosLigeros.MAX_TAZAS, "vapor en las tazas, con tope")
	_comprobar(polvos.size() == EfectosLigeros.MAX_LUCES_POLVO, "polvo en las luces, con tope")
	_comprobar(
		EfectosLigeros.particulas_totales(mundo) <= PRESUPUESTO,
		"no pasa del presupuesto (%d)" % EfectosLigeros.particulas_totales(mundo)
	)
	_comprobar(
		raiz.find_children("Charco*", "", false, false).is_empty(), "sin lluvia no hay charcos"
	)
	_comprobar(
		mundo.find_children("Gotas*", "MeshInstance3D", true, false).is_empty(),
		"sin lluvia el cristal está seco"
	)
	EfectosLigeros.montar(mundo, "archivo", Clima.DESPEJADO, false)
	_comprobar(
		mundo.find_children(EfectosLigeros.NOMBRE, "", false, false).size() == 1,
		"rehacer la fase no duplica los efectos"
	)
	_comprobar(
		(
			mundo.find_children(EfectosLigeros.NOMBRE_VAPOR, "", true, false).size()
			== EfectosLigeros.MAX_TAZAS
		),
		"ni el vapor de las tazas"
	)
	var fuera := EfectosLigeros.montar(mundo, "trayecto", Clima.DESPEJADO, false, true)
	_comprobar(
		fuera == null or fuera.find_children("Polvo*", "", false, false).is_empty(),
		"al aire libre no flota polvo"
	)
	mundo.free()


func _probar_calle_con_lluvia() -> void:
	var mundo := _mundo()
	var raiz := EfectosLigeros.montar(mundo, "trayecto", Clima.LLUVIA, false)
	var charcos := raiz.find_children("Charco*", "MeshInstance3D", false, false)
	_comprobar(charcos.size() == EfectosLigeros.CHARCOS, "la calle mojada tiene charcos")
	var dentro := true
	for charco in charcos:
		var p: Vector3 = (charco as MeshInstance3D).position
		dentro = dentro and EfectosLigeros.SUELO_CALLE.has_point(Vector2(p.x, p.z))
	_comprobar(dentro, "ningún charco sale del suelo de la calle")
	var primeros := EfectosLigeros.sitios_charcos()
	var segundos := EfectosLigeros.sitios_charcos()
	_comprobar(
		primeros == segundos and not primeros.is_empty(),
		"los charcos caen siempre en el mismo sitio"
	)
	var gotas := mundo.find_children("Gotas*", "MeshInstance3D", true, false)
	_comprobar(gotas.size() == 1, "la ventana se moja")
	# Como la ventana de casa: su propio nodo, montado después de entrar.
	var ventana := Node3D.new()
	mundo.add_child(ventana)
	var tardio := MeshInstance3D.new()
	tardio.name = "CristalVista3D"
	tardio.mesh = QuadMesh.new()
	ventana.add_child(tardio)
	_comprobar(
		EfectosLigeros.mojar_cristales(mundo, false) == 1,
		"un cristal que se monta después también se moja, y solo una vez"
	)
	_comprobar(raiz.get_node_or_null("MojarCristales") is Timer, "y hay quien vuelve a mirar")
	_comprobar(
		gotas.size() == 1 and (gotas[0] as MeshInstance3D).mesh.size == Vector2(1.2, 0.9),
		"las gotas cubren el cristal entero"
	)
	var otra := EfectosLigeros.montar(mundo, "casa", Clima.LLUVIA, false)
	_comprobar(
		otra.find_children("Charco*", "", false, false).is_empty(), "no hay charcos dentro de casa"
	)
	mundo.free()


func _probar_reduccion() -> void:
	var mundo := _mundo()
	var raiz := EfectosLigeros.montar(mundo, "trayecto", Clima.LLUVIA, true)
	_comprobar(
		EfectosLigeros.particulas_totales(mundo) == 0,
		"con reducción de movimiento no hay partículas"
	)
	var charco := raiz.get_node("Charco0") as MeshInstance3D
	_comprobar(
		(charco.material_override as ShaderMaterial).get_shader_parameter("velocidad") == 0.0,
		"y las ondas del charco se quedan quietas"
	)
	var gotas := mundo.find_children("Gotas*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	_comprobar(
		(gotas.material_override as ShaderMaterial).get_shader_parameter("velocidad") == 0.0,
		"y las gotas no resbalan"
	)
	mundo.free()


func _probar_sin_nada() -> void:
	var vacio := Node3D.new()
	root.add_child(vacio)
	_comprobar(
		EfectosLigeros.montar(vacio, "sueño", Clima.DESPEJADO, false) == null,
		"un espacio sin nada que adornar no gana nodos"
	)
	_comprobar(vacio.get_child_count() == 0, "ni un nodo vacío")
	vacio.free()


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO: " + descripcion)
