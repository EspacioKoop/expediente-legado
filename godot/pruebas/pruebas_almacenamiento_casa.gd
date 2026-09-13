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

	var posicion_cerrada := almacenamiento.posicion_cajon()
	_comprobar(almacenamiento.interactuar(root), "acepta la interacción semántica")
	_comprobar(almacenamiento.esta_abierto(), "abre tras interactuar")
	_comprobar(almacenamiento.texto_accion() == "Cerrar cajón", "actualiza el verbo")
	_comprobar(
		almacenamiento.posicion_cajon().z < posicion_cerrada.z,
		"el cajón se desplaza de forma visible"
	)

	_comprobar(almacenamiento.interactuar(root), "acepta cerrar")
	_comprobar(not almacenamiento.esta_abierto(), "vuelve a cerrado")
	_comprobar(almacenamiento.texto_accion() == "Abrir cajón", "restaura el prompt")
	_comprobar(
		almacenamiento.posicion_cajon().is_equal_approx(posicion_cerrada),
		"restaura la posición física"
	)
	almacenamiento.queue_free()


func _probar_distribucion_domestica() -> void:
	var casa := Node3D.new()
	root.add_child(casa)
	CasaUtileriaScript.montar_zonas_domesticas(casa)

	var sofa := casa.get_node_or_null("SofaCasa") as Node3D
	var cocina := casa.get_node_or_null("CocinaCasa") as Node3D
	var ventana := casa.get_node_or_null("VentanaCasa") as Node3D
	var estanteria := casa.get_node_or_null("EstanteriaComprasCasa") as Node3D

	_comprobar(sofa != null, "la zona de estar tiene sofá")
	_comprobar(cocina != null, "la casa tiene una zona de cocina")
	_comprobar(ventana != null, "la vivienda tiene ventana declarada")
	_comprobar(estanteria != null, "hay superficie vacía reservada para compras")
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
		sofa != null and sofa.position.x < -1.0 and sofa.position.z > 0.5,
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
