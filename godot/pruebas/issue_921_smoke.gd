## Regresión standalone del primer vertical de doctrinas de #921.
##
##     godot4 --headless --path godot --script pruebas/issue_921_smoke.gd
extends SceneTree

var pasadas := 0
var fallos := 0


func _init() -> void:
	_probar_cargas_transversales()
	_probar_tags_rituales()
	_probar_identidad_funcional()
	print("issue_921: %d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _probar_cargas_transversales() -> void:
	var estado := {
		"historias_cartas": {
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
		Prometeo.registrar_exposicion_ideologica(
			estado, "prensa:1", "prensa", "comunismo"
		),
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
	var robo_sol := JuicioSimbolico.ritual_para(
		{"id": "el-sol"}, "maui_tamanuitera"
	)
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
		JuicioCombate3D.duracion_doctrina("comunismo", laberinto)
		> JuicioCombate3D.DURACION_DOCTRINA,
		"Asamblea cruza genericamente con control de espacio",
	)
	_comprobar(
		JuicioCombate3D.duracion_telegrafo(true, robo_sol)
		> JuicioCombate3D.duracion_telegrafo(true, {}),
		"Comision cruza genericamente con telegraph",
	)
	_comprobar(
		JuicioCombate3D.recarga_mesa(robo_sol) > JuicioCombate3D.RECARGA_RIVAL,
		"Mesa cruza genericamente con neutralizar",
	)
	_comprobar(
		JuicioCombate3D.duracion_doctrina("neoliberal", talon)
		> JuicioCombate3D.DURACION_DOCTRINA,
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
			JuicioCombate3D.duracion_telegrafo(
				false,
				JuicioSimbolico.ritual_para({"id": "el-sol"}, "maui_tamanuitera"),
			),
			JuicioCombate3D.TELEGRAFO_RIVAL,
		),
		"el ritual no activa Comision de forma pasiva",
	)
	_comprobar(
		JuicioCombate3D.modificadores_doctrina_ritual(
			"comunismo",
			JuicioSimbolico.ritual_para({"id": "la-fuerza"}, "aquiles"),
		).is_empty(),
		"un tag no relacionado no inventa una combinacion especial",
	)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		pasadas += 1
		return
	fallos += 1
	push_error("FALLO #921: %s" % nombre)
