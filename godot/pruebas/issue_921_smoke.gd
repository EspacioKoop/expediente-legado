## Regresión standalone del primer vertical de doctrinas de #921.
##
##     godot4 --headless --path godot --script pruebas/issue_921_smoke.gd
extends SceneTree

var pasadas := 0
var fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_cargas_transversales()
	_probar_tags_rituales()
	_probar_identidad_funcional()
	await _probar_runtime_doctrinas()
	await process_frame
	print("issue_921: %d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _probar_cargas_transversales() -> void:
	var estado := {
		"historias_cartas":
		{
			"la-luna": "centrista",
			"la-justicia": "centrista",
		}
	}
	_comprobar(
		Prometeo.registrar_eleccion_ideologica(
			estado, "expediente:9:a", "expediente", "neoliberal"
		),
		"una decision nueva puede conceder doctrina",
	)
	_comprobar(
		Prometeo.registrar_eleccion_ideologica(
			estado, "expediente:9:b", "expediente", "neoliberal"
		),
		"dos decisiones nuevas del mismo eje se acumulan",
	)
	_comprobar(
		Prometeo.registrar_eleccion_ideologica(
			estado, "expediente:9:c", "expediente", "neoliberal"
		),
		"una tercera decision sigue registrada aunque luego haya tope",
	)
	_comprobar(
		Prometeo.registrar_exposicion_ideologica(estado, "prensa:1", "prensa", "comunismo"),
		"la exposicion puede registrarse por separado",
	)

	var esperadas := {
		"comunismo": 0,
		"socialdemocrata": 0,
		"centrista": 2,
		"neoliberal": 2,
	}
	_comprobar(
		Prometeo.cargas_ideologicas(estado, 2) == esperadas,
		"las cargas usan elecciones, aplican tope e ignoran exposicion",
	)
	_comprobar(
		Historias.new().cargas(estado) == esperadas,
		"Ventanilla y Juicio comparten la misma fuente de cargas",
	)


func _probar_tags_rituales() -> void:
	var laberinto := JuicioSimbolico.ritual_para({"id": "la-luna"}, "minotauro")
	var robo_sol := JuicioSimbolico.ritual_para({"id": "el-sol"}, "maui_tamanuitera")
	var talon := JuicioSimbolico.ritual_para({"id": "la-fuerza"}, "aquiles")

	_comprobar(
		laberinto.get("tags", []).has("control_espacio"),
		"Laberinto lunar declara control de espacio",
	)
	_comprobar(
		robo_sol.get("tags", []).has("telegraph"),
		"Robo del Sol declara telegraph",
	)
	_comprobar(
		robo_sol.get("tags", []).has("neutralizar"),
		"Robo del Sol declara neutralizar",
	)
	_comprobar(
		talon.get("tags", []).has("riesgo"),
		"Talon de la Fuerza declara riesgo",
	)
	_comprobar(
		(
			JuicioCombate3D.duracion_doctrina("comunismo", laberinto)
			> JuicioCombate3D.DURACION_DOCTRINA
		),
		"Asamblea cruza genericamente con control de espacio",
	)
	_comprobar(
		(
			JuicioCombate3D.duracion_telegrafo(true, robo_sol)
			> JuicioCombate3D.duracion_telegrafo(true, {})
		),
		"Comision cruza genericamente con telegraph",
	)
	_comprobar(
		JuicioCombate3D.recarga_mesa(robo_sol) > JuicioCombate3D.RECARGA_RIVAL,
		"Mesa cruza genericamente con neutralizar",
	)
	_comprobar(
		JuicioCombate3D.duracion_doctrina("neoliberal", talon) > JuicioCombate3D.DURACION_DOCTRINA,
		"Externalizar cruza genericamente con riesgo",
	)


func _probar_identidad_funcional() -> void:
	_comprobar(
		JuicioCombate3D.asamblea_interrumpe("comunismo", true),
		"Asamblea convierte un choque telegrafiado en iniciativa",
	)
	_comprobar(
		not JuicioCombate3D.asamblea_interrumpe("comunismo", false),
		"Asamblea no actua fuera de su ventana",
	)
	_comprobar(
		JuicioCombate3D.dano_externalizado(2, "neoliberal") == 4,
		"Externalizar duplica lo que esta en juego",
	)
	_comprobar(
		JuicioCombate3D.dano_externalizado(2, "centrista") == 2,
		"otra doctrina no recibe el efecto de Externalizar",
	)
	_comprobar(
		is_equal_approx(
			(
				JuicioCombate3D
				. duracion_telegrafo(
					false,
					JuicioSimbolico.ritual_para({"id": "el-sol"}, "maui_tamanuitera"),
				)
			),
			JuicioCombate3D.TELEGRAFO_RIVAL,
		),
		"el ritual no activa Comision de forma pasiva",
	)
	_comprobar(
		(
			JuicioCombate3D
			. modificadores_doctrina_ritual(
				"comunismo",
				JuicioSimbolico.ritual_para({"id": "la-fuerza"}, "aquiles"),
			)
			. is_empty()
		),
		"un tag no relacionado no inventa una combinacion especial",
	)


func _probar_runtime_doctrinas() -> void:
	var asamblea := await _nuevo_juicio({})
	_acercar(asamblea)
	asamblea._cargas_doctrina = {"comunismo": 1}
	asamblea._pintar_doctrinas()
	asamblea._ataque_rival_pendiente = true
	_comprobar(asamblea.activar_doctrina("comunismo"), "Asamblea se activa con carga")
	_comprobar(
		int(asamblea._cargas_doctrina["comunismo"]) == 0,
		"Asamblea consume exactamente una carga",
	)
	asamblea._recarga_jugador = 0.0
	asamblea._atacar(1, JuicioCombate3D.ALCANCE_LIGERO, JuicioCombate3D.RECARGA_LIGERA, false)
	_comprobar(not asamblea._ataque_rival_pendiente, "Asamblea corta la iniciativa rival")
	_comprobar(
		asamblea._determinacion_rival == 7,
		"Asamblea no inventa dano adicional al golpe ligero",
	)
	_comprobar(asamblea._doctrina_activa.is_empty(), "Asamblea termina tras aprovechar su ventana")
	asamblea.free()

	var mesa := await _nuevo_juicio({})
	_acercar(mesa)
	mesa._cargas_doctrina = {"centrista": 1}
	mesa._pintar_doctrinas()
	mesa._ataque_rival_pendiente = true
	_comprobar(mesa.activar_doctrina("centrista"), "Mesa se activa con carga")
	_comprobar(
		int(mesa._cargas_doctrina["centrista"]) == 0,
		"Mesa consume exactamente una carga",
	)
	_comprobar(not mesa._ataque_rival_pendiente, "Mesa neutraliza el ataque anunciado")
	_comprobar(
		mesa._jugador.position.distance_to(mesa._rival.position) >= 2.95,
		"Mesa restablece distancia sin mover decorativamente la regla",
	)
	_comprobar(
		mesa._determinacion_jugador == 8 and mesa._determinacion_rival == 8,
		"Mesa no concede dano gratis a ninguna parte",
	)
	mesa.free()

	var robo_sol := JuicioSimbolico.ritual_para({"id": "el-sol"}, "maui_tamanuitera")
	var comision := await _nuevo_juicio(robo_sol)
	_acercar(comision)
	comision._cargas_doctrina = {"socialdemocrata": 1}
	comision._pintar_doctrinas()
	_comprobar(
		comision.activar_doctrina("socialdemocrata"),
		"Comision se activa con carga",
	)
	_comprobar(comision._comision_pendiente, "Comision espera la siguiente intencion")
	_comprobar(
		int(comision._cargas_doctrina["socialdemocrata"]) == 0,
		"Comision consume exactamente una carga",
	)
	comision._iniciar_ataque_rival()
	_comprobar(
		comision._doctrina_activa == "socialdemocrata",
		"Comision acompana el telegráfico que revela",
	)
	_comprobar(
		comision._telegrafo_rival > JuicioCombate3D.TELEGRAFO_RIVAL,
		"Comision amplia de verdad la ventana de lectura",
	)
	comision._esquiva = 0.34
	comision._resolver_ataque_rival()
	_comprobar(
		comision._doctrina_activa.is_empty(),
		"Comision termina al resolverse la intencion observada",
	)
	comision.free()

	var talon := JuicioSimbolico.ritual_para({"id": "la-fuerza"}, "aquiles")
	var externaliza := await _nuevo_juicio(talon)
	_acercar(externaliza)
	externaliza._cargas_doctrina = {"neoliberal": 1}
	externaliza._pintar_doctrinas()
	_comprobar(externaliza.activar_doctrina("neoliberal"), "Externalizar se activa con carga")
	externaliza._recarga_jugador = 0.0
	externaliza._atacar(1, JuicioCombate3D.ALCANCE_LIGERO, JuicioCombate3D.RECARGA_LIGERA, false)
	_comprobar(
		externaliza._determinacion_rival == 6,
		"Externalizar duplica el primer impacto saliente",
	)
	_comprobar(
		externaliza._doctrina_activa.is_empty(),
		"Externalizar termina tras resolverse la apuesta saliente",
	)
	_comprobar(
		int(externaliza._cargas_doctrina["neoliberal"]) == 0,
		"Externalizar consume exactamente una carga",
	)
	externaliza.free()

	var exposicion := await _nuevo_juicio({})
	_acercar(exposicion)
	exposicion._cargas_doctrina = {"neoliberal": 1}
	_comprobar(exposicion.activar_doctrina("neoliberal"), "la apuesta entrante puede activarse")
	exposicion._ataque_rival_pendiente = true
	exposicion._resolver_ataque_rival()
	_comprobar(
		exposicion._determinacion_jugador == 6,
		"Externalizar duplica tambien el primer impacto recibido",
	)
	_comprobar(
		exposicion._doctrina_activa.is_empty(),
		"la apuesta entrante tambien consume la ventana",
	)
	exposicion.free()

	var base := await _nuevo_juicio({})
	_acercar(base)
	_comprobar(
		not base.activar_doctrina("comunismo"),
		"sin cargas ninguna doctrina se activa por defecto",
	)
	base._recarga_jugador = 0.0
	base._atacar(1, JuicioCombate3D.ALCANCE_LIGERO, JuicioCombate3D.RECARGA_LIGERA, false)
	_comprobar(
		base._determinacion_rival == 7,
		"sin cargas el combate base conserva su dano normal",
	)
	base.free()


func _nuevo_juicio(ritual: Dictionary) -> JuicioCombate3D:
	var juicio := JuicioCombate3D.new()
	juicio.configurar({"id": "prueba_921", "nombre": "PRUEBA #921"}, 0, true)
	juicio._ritual = ritual.duplicate(true)
	juicio._aplicar_configuracion_ritual()
	root.add_child(juicio)
	await process_frame
	return juicio


func _acercar(juicio: JuicioCombate3D) -> void:
	juicio._jugador.position = Vector3.ZERO
	juicio._rival.position = Vector3(0.0, 0.0, -1.0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		pasadas += 1
		return
	fallos += 1
	push_error("FALLO #921: %s" % nombre)
