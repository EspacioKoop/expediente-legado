extends SceneTree

const MaquinaCafe := preload("res://guion/maquina_cafe_interactiva_3d.gd")
const UtileriaOficina := preload("res://guion/oficina_utileria.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_maquina()
	_probar_puestos()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_maquina() -> void:
	var maquina := MaquinaCafe.new()
	root.add_child(maquina)
	maquina.configurar(12)
	var taza := maquina.get_node("TazaServida") as MeshInstance3D
	var piloto := maquina.get_node("PilotoCafe") as MeshInstance3D
	var material := piloto.material_override as StandardMaterial3D

	_comprobar(maquina.texto_accion() == "Comprar café (12)", "el prompt enseña el coste")
	_comprobar(not maquina.taza_visible(), "empieza sin taza servida")
	_comprobar(taza != null, "tiene taza visible de feedback")
	_comprobar(piloto != null, "tiene piloto visible")
	_comprobar(
		maquina.find_children("*", "CollisionShape3D", true, false).size() == 1,
		"expone un único volumen de interacción"
	)

	# Interactuar solo solicita la compra. El nodo físico no puede concederse a sí
	# mismo dinero/acciones: eso pertenece al controller de Jornada.
	_comprobar(maquina.interactuar(root), "acepta la solicitud de café")
	_comprobar(not maquina.taza_visible(), "solicitar no sirve una taza por sí solo")

	maquina.servir()
	_comprobar(maquina.taza_visible(), "el dueño puede servir la taza aprobada")
	_comprobar(taza.visible, "el feedback físico se hace visible")
	_comprobar(material != null and material.emission_enabled, "el piloto se enciende")
	_comprobar(maquina.texto_accion() == "Coger café", "la taza servida se puede recoger")

	maquina.retirar_taza()
	_comprobar(not maquina.taza_visible(), "recoger limpia el feedback")
	_comprobar(not taza.visible, "la taza vuelve a ocultarse")
	_comprobar(not material.emission_enabled, "el piloto vuelve a apagarse")

	maquina.marcar_agotado()
	_comprobar(
		maquina.texto_accion() == "Ya has tomado café hoy", "el tope diario se explica en el objeto"
	)
	maquina.marcar_sin_dinero()
	_comprobar(
		maquina.texto_accion() == "No te alcanza para el café (12)",
		"la falta de saldo se explica en el objeto"
	)
	maquina.queue_free()


func _probar_puestos() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	UtileriaOficina.montar(mundo, 12)

	for i in range(1, 5):
		var puesto := mundo.get_node_or_null("PuestoUtileria%d" % i)
		_comprobar(puesto != null, "existe puesto vestido %d" % i)
		if puesto == null:
			continue
		_comprobar(puesto.get_node_or_null("Teclado") != null, "puesto %d tiene teclado" % i)
		_comprobar(puesto.get_node_or_null("TelefonoBase") != null, "puesto %d tiene teléfono" % i)
		_comprobar(puesto.get_node_or_null("Auricular") != null, "puesto %d tiene auricular" % i)

	_comprobar(
		mundo.get_node_or_null("PuestoUtileria1/BandejaEntrada") != null,
		"primer puesto tiene bandeja"
	)
	_comprobar(
		mundo.get_node_or_null("PuestoUtileria2/TazaPuesto") != null, "segundo puesto tiene taza"
	)
	_comprobar(
		mundo.get_node_or_null("PuestoUtileria3/BandejaEntrada") != null,
		"tercer puesto alterna bandeja"
	)
	_comprobar(
		mundo.get_node_or_null("PuestoUtileria4/TazaPuesto") != null, "cuarto puesto alterna taza"
	)
	var maquina := mundo.get_node_or_null("MaquinaCafeInteractuable") as MaquinaCafeInteractiva3D
	_comprobar(maquina != null, "la máquina se integra en la oficina")
	_comprobar(maquina.texto_accion() == "Comprar café (12)", "la oficina inyecta el precio real")
	mundo.queue_free()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO OficinaUtileria: " + nombre)
