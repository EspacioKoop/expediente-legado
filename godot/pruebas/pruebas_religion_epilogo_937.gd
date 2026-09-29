extends SceneTree

var fallos := 0


func _init() -> void:
	_probar_tres_modulos_sin_reetiquetar()
	_probar_sin_declaracion()
	_probar_final_base_estable()
	_probar_integracion_final_visible()
	_probar_snapshot_invalido()
	print("pruebas religión epílogo #937: %d fallos" % fallos)
	quit(1 if fallos > 0 else 0)


func _probar_tres_modulos_sin_reetiquetar() -> void:
	var estado := Partida.nueva()
	var registro := ReligionEventos.asegurar_en_estado(estado)
	_registrar(
		registro,
		"exp:archivo",
		ReligionEventos.CANAL_EXPOSICION,
		"archivo:revista",
		"estanteria:hemeroteca",
		1,
		{},
	)
	_registrar(
		registro,
		"practica:comida",
		ReligionEventos.CANAL_PRACTICA,
		"evento:barrio",
		"mesa:comunitaria",
		2,
		{},
	)
	_registrar(
		registro,
		"decl:duda",
		ReligionEventos.CANAL_CONVICCION,
		"dialogo:amistad",
		"plaza:tarde",
		3,
		{"declaracion": ReligionEventos.DECLARACION_DUDA},
	)
	_registrar(
		registro,
		"decl:cambio",
		ReligionEventos.CANAL_CONVICCION,
		"dialogo:amistad",
		"plaza:noche",
		4,
		{"declaracion": ReligionEventos.DECLARACION_CAMBIO},
	)
	_registrar(
		registro,
		"vinculo:archivo",
		ReligionEventos.CANAL_VINCULO,
		"comunidad:archivo",
		"sala:consulta",
		5,
		{"actor": "comunidad:archivo"},
	)

	var snapshot := ReligionEventos.archivar_trayectoria(estado, "prueba_epilogo")
	var epilogo := ReligionTrayectoria.derivar_epilogo("final_base_a", snapshot)
	var resumen: Dictionary = epilogo["religion"]
	var modulos: Array = resumen["modulos"]

	_comprobar(epilogo["final_base"] == "final_base_a", "conserva el final base")
	_comprobar(not epilogo["bloquea_final_base"], "religión no bloquea el final base")
	_comprobar(modulos.size() == 3, "los cuatro canales caben en tres módulos")
	_comprobar(modulos[0]["id"] == "declaraciones", "declaraciones van en módulo propio")
	_comprobar(
		modulos[1]["id"] == "practicas_exposiciones",
		"práctica y exposición comparten módulo factual",
	)
	_comprobar(modulos[2]["id"] == "vinculos", "vínculos van en módulo propio")
	_comprobar(modulos[0]["hechos"].size() == 2, "conserva dos declaraciones contradictorias")
	_comprobar(
		modulos[0]["hechos"][0]["declaracion"] == ReligionEventos.DECLARACION_DUDA,
		"conserva duda explícita",
	)
	_comprobar(
		modulos[0]["hechos"][1]["declaracion"] == ReligionEventos.DECLARACION_CAMBIO,
		"conserva cambio explícito",
	)
	_comprobar(
		modulos[2]["hechos"][0]["actor"] == "comunidad:archivo",
		"vínculo conserva actor concreto",
	)

	for modulo_valor in modulos:
		var modulo: Dictionary = modulo_valor
		_comprobar(modulo["requiere_citar_hechos"], "cada módulo exige citar hechos")
		for hecho_valor in modulo["hechos"]:
			var hecho: Dictionary = hecho_valor
			_comprobar(not String(hecho.get("fuente", "")).is_empty(), "hecho conserva fuente")
			_comprobar(
				not String(hecho.get("procedencia", "")).is_empty(),
				"hecho conserva procedencia",
			)
			_comprobar(not String(hecho.get("contexto", "")).is_empty(), "hecho conserva contexto")

	var serializado := JSON.stringify(epilogo).to_lower()
	for prohibido in ["identidad", "puntuacion", "ranking", "ganador"]:
		_comprobar(not serializado.contains(prohibido), "epílogo no serializa %s" % prohibido)


func _probar_sin_declaracion() -> void:
	var estado := Partida.nueva()
	var registro := ReligionEventos.asegurar_en_estado(estado)
	_registrar(
		registro,
		"exp:sin-declaracion",
		ReligionEventos.CANAL_EXPOSICION,
		"documento:archivo",
		"mesa:lectura",
		1,
		{},
	)
	var snapshot := ReligionEventos.archivar_trayectoria(estado, "sin_declaracion")
	var resumen := ReligionTrayectoria.resumir(snapshot)
	var modulos: Array = resumen["modulos"]
	_comprobar(modulos.size() == 1, "exposición sola produce un módulo")
	_comprobar(
		modulos[0]["id"] == "practicas_exposiciones",
		"exposición no inventa módulo de declaraciones",
	)
	_comprobar(
		not JSON.stringify(resumen).contains(ReligionEventos.DECLARACION_NO_ADSCRIPCION),
		"ausencia de declaración no inventa no adscripción",
	)


func _probar_final_base_estable() -> void:
	var vacio := {
		"vuelta": 1,
		"motivo": "prueba",
		"canales":
		{
			ReligionEventos.CANAL_EXPOSICION: [],
			ReligionEventos.CANAL_PRACTICA: [],
			ReligionEventos.CANAL_CONVICCION: [],
			ReligionEventos.CANAL_VINCULO: [],
		},
	}
	var a := ReligionTrayectoria.derivar_epilogo("mismo_final", vacio)
	var con_hecho := vacio.duplicate(true)
	con_hecho["canales"][ReligionEventos.CANAL_VINCULO] = [
		(
			ReligionEventos
			. crear_evento(
				"vinculo:persona",
				ReligionEventos.CANAL_VINCULO,
				"npc:persona",
				"cafeteria",
				2,
				"",
				[],
				[],
				false,
				[],
				{
					"vuelta": 1,
					"procedencia": "dialogo:cafeteria",
					"actor": "npc:persona",
				},
			)
		)
	]
	var b := ReligionTrayectoria.derivar_epilogo("mismo_final", con_hecho)
	_comprobar(a["final_base"] == b["final_base"], "trayectoria no sustituye el final")
	_comprobar(a["religion"] != b["religion"], "hechos distintos producen capa distinta")



func _probar_integracion_final_visible() -> void:
	var estado := Partida.nueva()
	var registro := ReligionEventos.asegurar_en_estado(estado)
	_registrar(
		registro,
		"exp:final-visible",
		ReligionEventos.CANAL_EXPOSICION,
		"rom:archivo",
		"casa:portatil",
		1,
		{},
	)
	_registrar(
		registro,
		"decl:final-visible",
		ReligionEventos.CANAL_CONVICCION,
		"dialogo:familia",
		"casa:salon",
		2,
		{"declaracion": ReligionEventos.DECLARACION_DUDA},
	)

	var resumen := FinalPolitico.resumen(estado)
	_comprobar(resumen.has("religion"), "el cierre político expone la capa religiosa")
	_comprobar(resumen["religion"]["estado"] == "factual", "la capa visible usa hechos actuales")
	_comprobar(
		resumen["religion"]["modulos"].size() == 2,
		"exposición y declaración permanecen separadas en el cierre",
	)

	_comprobar(
		ReligionEventos.historial_trayectorias(estado).is_empty(),
		"mostrar el resumen no sella ni muta el historial",
	)
	FinalPolitico.confirmar_cierre(estado)
	var historial := ReligionEventos.historial_trayectorias(estado)
	_comprobar(historial.size() == 1, "confirmar el cierre sella una trayectoria religiosa")
	_comprobar(
		historial[0]["motivo"] == "final_narrativo",
		"el snapshot conserva el motivo de cierre",
	)
	FinalPolitico.confirmar_cierre(estado)
	_comprobar(
		ReligionEventos.historial_trayectorias(estado).size() == 1,
		"confirmar dos veces no duplica la trayectoria",
	)


func _probar_snapshot_invalido() -> void:
	var resumen := ReligionTrayectoria.resumir({"vuelta": 3, "canales": "roto"})
	_comprobar(resumen["estado"] == "ausente", "snapshot inválido degrada a ausencia")
	_comprobar(resumen["modulos"].is_empty(), "snapshot inválido no inventa módulos")


func _registrar(
	registro: Dictionary,
	id_evento: String,
	canal: String,
	fuente: String,
	contexto: String,
	jornada: int,
	metadatos: Dictionary,
) -> void:
	var datos := metadatos.duplicate(true)
	datos["vuelta"] = 1
	datos["procedencia"] = "prueba:937:%s" % id_evento
	var evento := (
		ReligionEventos
		. crear_evento(
			id_evento,
			canal,
			fuente,
			contexto,
			jornada,
			"",
			[],
			[],
			false,
			[],
			datos,
		)
	)
	_comprobar(ReligionEventos.registrar(registro, evento), "registra %s" % id_evento)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos += 1
		push_error(mensaje)
