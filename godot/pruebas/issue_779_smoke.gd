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

	print("issue_779: %d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		pasadas += 1
		return
	fallos += 1
	push_error("FALLO #779: %s" % nombre)
