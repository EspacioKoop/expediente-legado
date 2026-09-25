## Contrato de los dependientes de las tiendas: uno por comercio, cada uno con
## un cuerpo que no es el de nadie de la oficina, con texto para todo lo que
## puede decir, y una conversación que avanza en orden y no se inventa tiendas.
extends SceneTree

const TIENDAS := ["QuioscoAvenida", "ElTrastero", "InteriorElectrodomesticos", "InteriorBit98"]

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	TranslationServer.set_locale("es")
	_probar_reparto()
	_probar_textos()
	_probar_orden_de_la_charla()
	_probar_clientes()
	await _probar_montaje()
	_probar_sin_tiendas()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_reparto() -> void:
	var todos := DependientesTiendas.todos()
	_comprobar(todos.size() == 4, "un dependiente por tienda")
	var ids := {}
	var cuerpos := {}
	var tiendas := {}
	for d in todos:
		ids[d["id"]] = true
		cuerpos[d["cuerpo"]] = true
		tiendas[d["tienda"]] = true
		_comprobar(Modelos.es_realista(String(d["cuerpo"])), "%s tiene avatar realista" % d["id"])
		_comprobar(
			ResourceLoader.exists("%s%s.glb" % [Modelos.RUTA, d["cuerpo"]]),
			"%s: su avatar está en el repositorio" % d["id"]
		)
		# Un dependiente con la cara de un compañero se leería como el mismo
		# personaje trabajando en dos sitios.
		_comprobar(
			not Companeros.CUERPOS.values().has(d["cuerpo"]),
			"%s no comparte cuerpo con la oficina" % d["id"]
		)
	_comprobar(ids.size() == 4 and cuerpos.size() == 4, "ids y cuerpos distintos")
	_comprobar(tiendas.size() == 4, "cada uno en su tienda")


func _probar_textos() -> void:
	for d in DependientesTiendas.todos():
		for clave in DependientesTiendas.claves(d):
			_comprobar(TranslationServer.translate(clave) != clave, "%s tiene texto" % clave)


func _probar_orden_de_la_charla() -> void:
	var paco := DependientesTiendas.de("paco")
	var dia3 := {"dia": 3}
	# Con lluvia: primero el tiempo, luego el saludo del día y luego la
	# insistencia, que se queda.
	var orden := []
	for charla in 5:
		orden.append(DependientesTiendas.frase(paco, dia3, Clima.LLUVIA, charla))
	_comprobar(
		(
			orden
			== [
				"DEPEND_PACO_LLUVIA",
				"DEPEND_PACO_SALUDO_3",
				"DEPEND_PACO_INSISTE",
				"DEPEND_PACO_INSISTE",
				"DEPEND_PACO_INSISTE",
			]
		),
		"con lluvia: tiempo, saludo e insistencia (%s)" % [orden]
	)
	# Sin nada que comentar, abre con el saludo.
	_comprobar(
		DependientesTiendas.frase(paco, dia3, Clima.DESPEJADO, 0) == "DEPEND_PACO_SALUDO_3",
		"despejado: abre con el saludo del día"
	)
	# El saludo rota con el día y vuelve a empezar tras el quinto.
	var saludos := []
	for dia in [1, 2, 5, 6]:
		saludos.append(DependientesTiendas.frase(paco, {"dia": dia}, Clima.NUBLADO, 0))
	_comprobar(
		(
			saludos
			== [
				"DEPEND_PACO_SALUDO_1",
				"DEPEND_PACO_SALUDO_2",
				"DEPEND_PACO_SALUDO_5",
				"DEPEND_PACO_SALUDO_1",
			]
		),
		"el saludo rota con el día (%s)" % [saludos]
	)


func _probar_clientes() -> void:
	var paco := DependientesTiendas.de("paco")
	var remedios := DependientesTiendas.de("remedios")
	var julian := DependientesTiendas.de("julian")
	var kike := DependientesTiendas.de("kike")
	var nada := {"dia": 2}
	_comprobar(not DependientesTiendas.es_cliente(paco, nada), "sin compras no eres cliente")

	var del_quiosco := {"dia": 2, ComercioBarrio.CLAVE_COMPRAS: ["periodico_tarde_98"]}
	_comprobar(DependientesTiendas.es_cliente(paco, del_quiosco), "comprar en el quiosco")
	_comprobar(
		not DependientesTiendas.es_cliente(remedios, del_quiosco),
		"comprar en el quiosco no te hace cliente del Trastero"
	)
	_comprobar(
		DependientesTiendas.frase(paco, del_quiosco, Clima.DESPEJADO, 0) == "DEPEND_PACO_CLIENTE",
		"al cliente le pregunta por lo que se llevó"
	)
	# El tiempo va antes que la compra.
	_comprobar(
		DependientesTiendas.frase(paco, del_quiosco, Clima.NIEVE, 0) == "DEPEND_PACO_NIEVE",
		"con nieve habla de la nieve aunque seas cliente"
	)
	# En Electrodomésticos no se vende nada: nunca eres cliente.
	_comprobar(not DependientesTiendas.es_cliente(julian, del_quiosco), "Julián no tiene clientes")
	# Las ROMs compradas viven en el perfil del jugador (`user://`), no en la
	# partida: aquí solo se comprueba que Kike sí reconoce clientes.
	_comprobar(bool(kike.get("cliente", false)), "Kike reconoce a quien le compra")


func _probar_montaje() -> void:
	var mundo := _mundo_con_tiendas()
	var charlas := DependientesTiendas3D.montar(mundo)
	await process_frame
	_comprobar(charlas.size() == 4, "monta los cuatro")
	for charla in charlas:
		var id := String(charla.get_meta("dependiente"))
		var d := DependientesTiendas.de(id)
		var raiz := charla.get_parent() as Node3D
		_comprobar(raiz.get_parent().name == d["tienda"], "%s está en su tienda" % id)
		_comprobar(
			charla.nombre_visible == TranslationServer.translate(d["clave"]),
			"%s se presenta por su nombre" % id
		)
		var cuerpo := raiz.get_node("Cuerpo") as Node3D
		_comprobar(cuerpo.get_child_count() == 1, "%s tiene cuerpo" % id)
		var pieza := cuerpo.get_child(0) as Node3D
		_comprobar(
			String(pieza.scene_file_path).ends_with("%s.glb" % d["cuerpo"]),
			"%s lleva su avatar" % id
		)
		var reproductor := Modelos._reproductor(pieza)
		_comprobar(
			reproductor != null and reproductor.is_playing(), "%s se mueve con su gesto" % id
		)
		# La charla avanza con cada conversación.
		var primera := DependientesTiendas3D.siguiente_frase(charla, {"dia": 1}, Clima.LLUVIA)
		var segunda := DependientesTiendas3D.siguiente_frase(charla, {"dia": 1}, Clima.LLUVIA)
		_comprobar(
			primera.ends_with("_LLUVIA") and segunda.ends_with("_SALUDO_1"),
			"%s avanza la charla (%s, %s)" % [id, primera, segunda]
		)

	# Rehacer el trayecto no duplica a nadie.
	DependientesTiendas3D.montar(mundo)
	var cuenta := 0
	for tienda in TIENDAS:
		for hijo in mundo.find_child(tienda, true, false).get_children():
			if String(hijo.name).begins_with(DependientesTiendas3D.PREFIJO):
				cuenta += 1
	_comprobar(cuenta == 4, "montar dos veces no duplica (%d)" % cuenta)
	mundo.free()


func _probar_sin_tiendas() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	var solo_quiosco := Node3D.new()
	solo_quiosco.name = "QuioscoAvenida"
	mundo.add_child(solo_quiosco)
	var charlas := DependientesTiendas3D.montar(mundo)
	_comprobar(charlas.size() == 1, "sin tienda no hay dependiente")
	mundo.free()


func _mundo_con_tiendas() -> Node3D:
	var mundo := Node3D.new()
	root.add_child(mundo)
	var calle := Node3D.new()
	calle.name = "Calle"
	mundo.add_child(calle)
	for tienda in TIENDAS:
		var nodo := Node3D.new()
		nodo.name = tienda
		calle.add_child(nodo)
	return mundo


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO: " + mensaje)
