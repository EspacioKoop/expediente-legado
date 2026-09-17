## Regresión standalone de #779.
##
##     godot4 --headless --path godot --script pruebas/issue_779_smoke.gd
extends SceneTree

var pasadas := 0
var fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	var contenido := Contenido.new()
	contenido.casos = [
		{
			"pistas":
			[
				{"id": "p_conocida", "descripcion": "dato conocido"},
				{"id": "p_ajena", "descripcion": "dato ajeno"},
			]
		}
	]
	var rival := {
		"id": "rival_prueba",
		"nombre": "RIVAL_PRUEBA",
		"pistas": ["p_conocida"],
		"ataques": [],
	}

	var evidencias := CareoDocumental.evidencias_relevantes(
		rival, contenido, ["p_conocida", "p_ajena"]
	)
	_comprobar(evidencias.size() == 1, "solo ofrece pistas vinculadas al rival")
	_comprobar(evidencias[0]["id"] == "p_conocida", "conserva la pista catalogada")

	var careo := CareoDocumental.nuevo(rival, {}, evidencias)
	careo["revelada"] = Combate.TIPOS.find("objecion")
	var ronda := CareoDocumental.jugar(careo, "objecion", "p_conocida", "", func(): return 0.0)
	_comprobar(ronda["impacto_evidencia"] == 1, "la prueba rompe un empate")
	_comprobar(careo["vida_rival"] == 2, "la prueba resta credibilidad")
	_comprobar(careo["evidencias_usadas"] == ["p_conocida"], "la prueba se consume una vez")
	_comprobar(CareoDocumental.bono_juicio(careo) == 1, "el acierto alimenta el juicio")

	careo["revelada"] = Combate.TIPOS.find("objecion")
	var repetida := CareoDocumental.jugar(careo, "objecion", "p_conocida", "", func(): return 0.0)
	_comprobar(repetida["impacto_evidencia"] == 0, "una prueba usada no vuelve a impactar")

	var derrota := CareoDocumental.nuevo(rival, {}, evidencias)
	derrota["revelada"] = Combate.TIPOS.find("objecion")
	var ronda_derrota := CareoDocumental.jugar(
		derrota, "silencio", "p_conocida", "", func(): return 0.0
	)
	_comprobar(ronda_derrota["impacto_evidencia"] == 0, "la prueba no rescata una mala lectura")
	_comprobar(CareoDocumental.bono_juicio(derrota) == 0, "una prueba fallida no da ventaja")

	_comprobar(JuicioCombate3D.determinacion_rival(0) == 8, "juicio sin expediente parte entero")
	_comprobar(JuicioCombate3D.determinacion_rival(3) == 5, "el expediente debilita al acusado")
	_comprobar(JuicioCombate3D.determinacion_rival(99) == 4, "el juicio conserva un suelo jugable")
	_comprobar(
		JuicioCombate3D.resultado_ataque_rival(1.0, 0.0) == "impacto",
		"un ataque a alcance impacta sin esquiva",
	)
	_comprobar(
		JuicioCombate3D.resultado_ataque_rival(1.0, 0.12) == "esquiva",
		"la ventana de esquiva evita el impacto",
	)
	_comprobar(
		JuicioCombate3D.resultado_ataque_rival(2.0, 0.0) == "falla",
		"salir del alcance durante el telegrafo hace fallar el ataque",
	)

	_comprobar(
		PrevisualizadorReclamante3D.sonido_jugada("objecion") == "firmar",
		"objecion tiene sonido propio",
	)
	_comprobar(
		PrevisualizadorReclamante3D.sonido_jugada("silencio") == "pulsar",
		"silencio tiene sonido propio",
	)
	_comprobar(
		PrevisualizadorReclamante3D.sonido_jugada("insistencia") == "marcar",
		"insistencia tiene sonido propio",
	)
	_comprobar(
		PrevisualizadorReclamante3D.sonido_jugada("desconocida").is_empty(),
		"una jugada desconocida no inventa sonido",
	)

	var tarot := [
		{"id": "la-luna", "nombre": "La Luna", "recogida": true, "gastada": false},
		{"id": "el-sol", "nombre": "El Sol", "recogida": false, "gastada": false},
		{"id": "la-justicia", "nombre": "La Justicia", "recogida": true, "gastada": true},
	]
	var arcano := JuicioSimbolico.arcano_para(tarot, "rival_prueba")
	_comprobar(arcano.get("id", "") == "la-luna", "solo entra Tarot recogido y no gastado")
	_comprobar(
		(
			JuicioSimbolico
			. arcano_para(
				[{"id": "la-justicia", "recogida": true, "gastada": true}], "rival_prueba"
			)
			. is_empty()
		),
		"una carta gastada no vuelve al combate",
	)
	_comprobar(
		JuicioSimbolico.ruta_arcano(arcano).ends_with("/la-luna.png"),
		"el Arcano usa el arte canónico por id",
	)

	var jornada := {"dia": 4}
	SemillasOniricas.activar_semilla_onirica(jornada, "minotauro", "prueba:ventanilla")
	var mito := JuicioSimbolico.mito_para(jornada, "rival_prueba")
	_comprobar(mito == "minotauro", "el Juicio hereda una mitologia activada hoy")
	_comprobar(
		JuicioSimbolico.descriptor_mito(mito).get("forma", "") == "laberinto",
		"Minotauro conserva vocabulario visual propio",
	)

	var ritual_laberinto := JuicioSimbolico.ritual_para(arcano, mito)
	_comprobar(
		ritual_laberinto.get("id", "") == "laberinto_lunar",
		"Luna y Minotauro activan Laberinto lunar",
	)
	_comprobar(
		is_equal_approx(float(ritual_laberinto.get("radio_arena", 0.0)), 4.15),
		"Laberinto lunar estrecha la arena",
	)
	_comprobar(
		is_equal_approx(float(ritual_laberinto.get("velocidad_rival_mul", 0.0)), 0.86),
		"Laberinto lunar ralentiza la persecucion",
	)

	var ritual_balanza := JuicioSimbolico.ritual_para({"id": "la-justicia"}, "duat")
	_comprobar(
		ritual_balanza.get("id", "") == "balanza_duat",
		"Justicia y Duat activan Balanza del Duat",
	)
	_comprobar(
		int(ritual_balanza.get("contraataque_esquiva", 0)) == 1,
		"Balanza del Duat premia la esquiva sincronizada",
	)

	var ritual_talon := JuicioSimbolico.ritual_para({"id": "la-fuerza"}, "aquiles")
	_comprobar(
		ritual_talon.get("id", "") == "talon_fuerza",
		"Fuerza y Aquiles activan Talon de la Fuerza",
	)
	_comprobar(
		int(ritual_talon.get("dano_fuerte_bonus", 0)) == 1,
		"Talon de la Fuerza potencia el golpe fuerte",
	)
	_comprobar(
		is_equal_approx(float(ritual_talon.get("recarga_fuerte", 0.0)), 0.82),
		"Talon de la Fuerza aumenta la recuperacion del golpe fuerte",
	)

	var ritual_sol := JuicioSimbolico.ritual_para({"id": "el-sol"}, "maui_tamanuitera")
	_comprobar(
		ritual_sol.get("id", "") == "robo_del_sol",
		"Sol y Maui activan Robo del Sol",
	)
	_comprobar(
		bool(ritual_sol.get("interrumpe_telegrafo_fuerte", false)),
		"Robo del Sol permite cortar un ataque anunciado",
	)
	_comprobar(
		int(ritual_sol.get("dano_interrupcion_bonus", 0)) == 1,
		"Robo del Sol premia la interrupcion",
	)
	_comprobar(
		JuicioCombate3D.interrumpe_ataque(true, true, ritual_sol),
		"el golpe fuerte interrumpe durante el telegrafo",
	)
	_comprobar(
		not JuicioCombate3D.interrumpe_ataque(false, true, ritual_sol),
		"el golpe ligero no roba el Sol",
	)
	_comprobar(
		not JuicioCombate3D.interrumpe_ataque(true, false, ritual_sol),
		"sin ataque rival pendiente no hay interrupcion",
	)

	var ritual_nudo := JuicioSimbolico.ritual_para({"id": "el-colgado"}, "anansi_akan")
	_comprobar(
		ritual_nudo.get("id", "") == "nudo_suspendido",
		"Colgado y Anansi activan Nudo suspendido",
	)
	_comprobar(
		is_equal_approx(float(ritual_nudo.get("enredo_ligero_segundos", 0.0)), 1.10),
		"Nudo suspendido deja una ventana de enredo",
	)
	_comprobar(
		is_equal_approx(float(ritual_nudo.get("velocidad_enredado_mul", 0.0)), 0.45),
		"el enredo frena la persecucion rival",
	)

	var ritual_hidra := JuicioSimbolico.ritual_para({"id": "la-muerte"}, "hidra")
	_comprobar(
		ritual_hidra.get("id", "") == "retorno_hidra",
		"Muerte e Hidra activan Retorno de la Hidra",
	)
	_comprobar(
		int(ritual_hidra.get("retornos_rival", 0)) == 1,
		"Retorno de la Hidra solo permite una segunda fase",
	)
	_comprobar(
		int(ritual_hidra.get("determinacion_retorno", 0)) == 2,
		"la segunda fase vuelve con dos puntos",
	)
	_comprobar(
		JuicioCombate3D.determinacion_retorno(ritual_hidra, 0) == 2,
		"la Hidra retorna la primera vez",
	)
	_comprobar(
		JuicioCombate3D.determinacion_retorno(ritual_hidra, 1) == 0,
		"la Hidra no encadena retornos infinitos",
	)

	_comprobar(
		JuicioSimbolico.ritual_para({"id": "el-sol"}, "minotauro").is_empty(),
		"una pareja no declarada no inventa bonificador",
	)

	var raiz := Node3D.new()
	var simbolos := JuicioSimbolico3D.montar(raiz, arcano, mito)
	var arcano_3d := simbolos.get_node_or_null("ArcanoRector")
	var mito_3d := simbolos.get_node_or_null("EcoMitologico")
	_comprobar(arcano_3d != null, "el Arcano se materializa en la arena")
	_comprobar(mito_3d != null, "el mito se materializa en la arena")
	_comprobar(
		arcano_3d != null and arcano_3d.get_meta("arcano_id", "") == "la-luna",
		"la carta 3D conserva su id",
	)
	_comprobar(
		mito_3d != null and mito_3d.get_meta("mito_id", "") == "minotauro",
		"el eco 3D conserva su familia mitologica",
	)
	raiz.free()

	print("issue_779: %d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		pasadas += 1
		return
	fallos += 1
	push_error("FALLO #779: %s" % nombre)
