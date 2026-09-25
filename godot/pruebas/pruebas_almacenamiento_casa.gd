extends SceneTree

const Almacenamiento := preload("res://guion/almacenamiento_casa_interactivo_3d.gd")
const CasaUtileriaScript := preload("res://guion/casa_utileria.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_almacenamiento()
	_probar_distribucion_domestica()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_almacenamiento() -> void:
	var almacenamiento := Almacenamiento.new()
	root.add_child(almacenamiento)
	almacenamiento.configurar()

	_comprobar(not almacenamiento.esta_abierto(), "empieza cerrado")
	_comprobar(almacenamiento.texto_accion() == "Abrir cajón", "anuncia abrir")
	_comprobar(
		almacenamiento.get_node_or_null("CajonCasa") != null,
		"el cajón visible forma parte del objeto"
	)
	_comprobar(
		almacenamiento.find_children("*", "CollisionShape3D", true, false).size() == 1,
		"expone un volumen de interacción"
	)

	var inventario := Inventario.nuevo()
	_comprobar(
		Inventario.recoger(
			inventario, {"id": "sello_oficina", "origen": "archivo", "usos": ["archivo"]}
		),
		"prepara un objeto llevado para probar la cómoda"
	)
	_comprobar(
		not almacenamiento.guardar_objeto(inventario, "sello_oficina"),
		"el cajón cerrado no guarda objetos"
	)
	_comprobar(
		(
			inventario[Inventario.CARRIED].size() == 1
			and inventario[Inventario.HOME_STORAGE].is_empty()
		),
		"rechazar con el cajón cerrado no muta el inventario"
	)
	_comprobar(
		almacenamiento.contenido(inventario).is_empty(),
		"el contenido doméstico no se expone con el cajón cerrado"
	)

	var posicion_cerrada := almacenamiento.posicion_cajon()
	_comprobar(almacenamiento.interactuar(root), "acepta la interacción semántica")
	_comprobar(almacenamiento.esta_abierto(), "abre tras interactuar")
	_comprobar(almacenamiento.texto_accion() == "Cerrar cajón", "actualiza el verbo")
	_comprobar(
		almacenamiento.posicion_cajon().z < posicion_cerrada.z,
		"el cajón se desplaza de forma visible"
	)
	_comprobar(
		almacenamiento.guardar_objeto(inventario, "sello_oficina"),
		"guardar mueve un objeto llevado al almacenamiento doméstico"
	)
	_comprobar(
		(
			inventario[Inventario.CARRIED].is_empty()
			and inventario[Inventario.HOME_STORAGE].size() == 1
		),
		"guardar usa carried/home_storage como fuente de verdad"
	)
	var contenido := almacenamiento.contenido(inventario)
	_comprobar(
		contenido.size() == 1 and String(contenido[0].get("id", "")) == "sello_oficina",
		"el cajón abierto enumera su contenido"
	)
	_comprobar(
		not almacenamiento.guardar_objeto(inventario, "sello_oficina"),
		"no duplica un objeto que ya está guardado"
	)
	_comprobar(
		almacenamiento.sacar_objeto(inventario, "sello_oficina"),
		"sacar devuelve el objeto al inventario llevado"
	)
	_comprobar(
		(
			inventario[Inventario.CARRIED].size() == 1
			and inventario[Inventario.HOME_STORAGE].is_empty()
		),
		"sacar conserva una única copia del objeto"
	)
	_comprobar(
		not almacenamiento.sacar_objeto(inventario, "no_existe"),
		"sacar un id inexistente falla sin inventar objetos"
	)

	_comprobar(almacenamiento.interactuar(root), "acepta cerrar")
	_comprobar(not almacenamiento.esta_abierto(), "vuelve a cerrado")
	_comprobar(almacenamiento.texto_accion() == "Abrir cajón", "restaura el prompt")
	_comprobar(
		almacenamiento.posicion_cajon().is_equal_approx(posicion_cerrada),
		"restaura la posición física"
	)
	_comprobar(
		not almacenamiento.guardar_objeto(inventario, "sello_oficina"),
		"cerrar vuelve a bloquear operaciones de almacenamiento"
	)
	_comprobar(
		(
			inventario[Inventario.CARRIED].size() == 1
			and inventario[Inventario.HOME_STORAGE].is_empty()
		),
		"el bloqueo al cerrar tampoco muta estado"
	)
	almacenamiento.queue_free()


func _probar_distribucion_domestica() -> void:
	var casa := Node3D.new()
	root.add_child(casa)
	CasaUtileriaScript.montar_zonas_domesticas(casa)

	var cama := casa.get_node_or_null("CamaCasa") as Node3D
	var cuenco := casa.get_node_or_null("CuencoGato3D") as Node3D
	var sofa := casa.get_node_or_null("SofaCasa") as Node3D
	var cocina := casa.get_node_or_null("CocinaCasa") as Node3D
	var ventana := casa.get_node_or_null("VentanaCasa") as Node3D
	var estanteria := casa.get_node_or_null("EstanteriaComprasCasa") as Node3D

	_comprobar(cama != null, "el descanso se lee como cama 3D")
	_comprobar(cuenco != null, "el punto de alimentación tiene cuenco 3D")
	_comprobar(sofa != null, "la zona de estar tiene sofá")
	_comprobar(cocina != null, "la casa tiene una zona de cocina")
	_comprobar(ventana != null, "la vivienda tiene ventana declarada")
	_comprobar(estanteria != null, "hay superficie vacía reservada para compras")
	_comprobar(
		cama != null and cama.find_children("*", "MeshInstance3D", true, false).size() >= 9,
		"la cama añade marco, cabecero, ropa y patas al volumen histórico"
	)
	_comprobar(
		cuenco != null and cuenco.get_node_or_null("VisualCuencoOriginal98") is MeshInstance3D,
		"el cuenco usa la malla original 98"
	)
	_comprobar(
		cama != null and cama.position.is_equal_approx(Vector3(-2.4, 0.0, -2.0)),
		"la cama conserva el ancla de la salida a sueño"
	)
	_comprobar(
		cuenco != null and cuenco.position.is_equal_approx(Vector3(2.8, 0.0, 1.5)),
		"el cuenco conserva el primer sitio del gato"
	)
	_comprobar(
		sofa != null and sofa.find_children("*", "MeshInstance3D", true, false).size() >= 4,
		"el sofá se compone como mueble reconocible"
	)
	_comprobar(
		cocina != null and cocina.get_node_or_null("FregaderoCasa") != null,
		"la cocina incluye fregadero"
	)
	_comprobar(
		cocina != null and cocina.get_node_or_null("NeveraCasa") != null, "la cocina incluye nevera"
	)
	_comprobar(
		(
			estanteria != null
			and estanteria.find_children("*", "MeshInstance3D", true, false).size() >= 6
		),
		"la estantería ofrece varios huecos físicos"
	)
	_comprobar(
		sofa != null and sofa.position.x < -0.5 and sofa.position.z > 0.5,
		"el estar queda agrupado junto al televisor del lado izquierdo"
	)
	_comprobar(
		cocina != null and cocina.position.x > 3.0 and cocina.position.z < 0.5,
		"la cocina se agrupa contra el muro derecho"
	)
	_comprobar(
		ventana != null and ventana.position.z < -3.3,
		"la ventana queda vinculada al muro exterior del fondo"
	)
	_comprobar(
		sofa != null and cocina != null and sofa.position.distance_to(cocina.position) > 3.0,
		"estar y cocina son zonas distintas, no props dispersos en el mismo punto"
	)
	casa.queue_free()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO AlmacenamientoCasa: " + nombre)
