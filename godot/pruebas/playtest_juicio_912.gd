## Baseline cuantitativo reproducible del Juicio por Combate (#912).
##
## No pretende sustituir un playtest físico: mide el suelo matemático de las
## reglas reales para saber qué extremos conviene observar primero. Importa las
## constantes de JuicioCombate3D y los rituales declarados por JuicioSimbolico;
## no replica valores de balance en una segunda fuente de verdad.
extends SceneTree

var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	var escenarios := _escenarios()
	_comprobar(escenarios.size() == 7, "la matriz contiene base + seis rituales")

	var base: Dictionary = escenarios[0]
	var dps_ligero := float(base["dps_ligero"])
	var dps_fuerte := float(base["dps_fuerte"])
	var ratio_base := dps_fuerte / dps_ligero
	_comprobar(
		ratio_base >= 0.90 and ratio_base <= 1.10,
		"ligero y fuerte base conservan rendimiento bruto cercano",
	)

	var luna: Dictionary = escenarios[1]
	_comprobar(
		is_equal_approx(float(luna["radio_ratio"]), 0.83),
		"Laberinto lunar conserva el radio actual de arena",
	)
	_comprobar(
		is_equal_approx(float(luna["velocidad_rival"]), 2.15),
		"Laberinto lunar conserva la velocidad rival actual",
	)

	var duat: Dictionary = escenarios[2]
	_comprobar(int(duat["contraataque"]) == 1, "Balanza del Duat conserva CONTRA +1")

	var aquiles: Dictionary = escenarios[3]
	var mejora_fuerte := float(aquiles["dps_fuerte"]) / dps_fuerte
	_comprobar(
		mejora_fuerte > 1.0 and mejora_fuerte < 1.15,
		"Talón de la Fuerza mejora el fuerte sin duplicar su rendimiento",
	)

	var sol: Dictionary = escenarios[4]
	_comprobar(
		bool(sol["puede_cubrir_cada_telegrafo"]),
		"Robo del Sol puede reservar un fuerte por ciclo rival y requiere playtest",
	)

	var anansi: Dictionary = escenarios[5]
	_comprobar(
		float(anansi["cobertura_enredo_recargas"]) > 3.0,
		"Nudo suspendido puede sostener el slow con ligeros conectados y requiere playtest",
	)

	var hidra: Dictionary = escenarios[6]
	_comprobar(
		is_equal_approx(float(hidra["determinacion_ratio"]), 1.25),
		"Retorno de la Hidra añade un 25 por ciento de determinación efectiva",
	)

	_imprimir_matriz(escenarios)
	print("playtest_juicio_912: %d escenarios, %d fallos" % [escenarios.size(), _fallos])
	quit(1 if _fallos > 0 else 0)


func _escenarios() -> Array:
	return [
		_metricas("Base", {}),
		_metricas(
			"Luna + Minotauro",
			JuicioSimbolico.ritual_para({"id": "la-luna"}, "minotauro"),
		),
		_metricas(
			"Justicia + Duat",
			JuicioSimbolico.ritual_para({"id": "la-justicia"}, "duat"),
		),
		_metricas(
			"Fuerza + Aquiles",
			JuicioSimbolico.ritual_para({"id": "la-fuerza"}, "aquiles"),
		),
		_metricas(
			"Sol + Maui",
			JuicioSimbolico.ritual_para({"id": "el-sol"}, "maui_tamanuitera"),
		),
		_metricas(
			"Colgado + Anansi",
			JuicioSimbolico.ritual_para({"id": "el-colgado"}, "anansi_akan"),
		),
		_metricas(
			"Muerte + Hidra",
			JuicioSimbolico.ritual_para({"id": "la-muerte"}, "hidra"),
		),
	]


func _metricas(nombre: String, ritual: Dictionary) -> Dictionary:
	var radio := float(ritual.get("radio_arena", JuicioCombate3D.RADIO_ARENA))
	var velocidad_mul := float(ritual.get("velocidad_rival_mul", 1.0))
	var velocidad_rival := JuicioCombate3D.VELOCIDAD_RIVAL * velocidad_mul
	var recarga_fuerte := float(ritual.get("recarga_fuerte", JuicioCombate3D.RECARGA_FUERTE))
	var dano_fuerte := 2 + int(ritual.get("dano_fuerte_bonus", 0))
	var retorno := JuicioCombate3D.determinacion_retorno(ritual, 0)
	var determinacion := JuicioCombate3D.DETERMINACION_BASE + retorno
	var enredo := float(ritual.get("enredo_ligero_segundos", 0.0))
	var ciclo_rival := JuicioCombate3D.RECARGA_RIVAL + JuicioCombate3D.TELEGRAFO_RIVAL
	var puede_interrumpir := bool(ritual.get("interrumpe_telegrafo_fuerte", false))

	return {
		"nombre": nombre,
		"ritual_id": String(ritual.get("id", "base")),
		"determinacion": determinacion,
		"determinacion_ratio": float(determinacion) / JuicioCombate3D.DETERMINACION_BASE,
		"radio": radio,
		"radio_ratio": radio / JuicioCombate3D.RADIO_ARENA,
		"velocidad_rival": velocidad_rival,
		"dps_ligero": 1.0 / JuicioCombate3D.RECARGA_LIGERA,
		"dps_fuerte": float(dano_fuerte) / recarga_fuerte,
		"contraataque": int(ritual.get("contraataque_esquiva", 0)),
		"cobertura_enredo_recargas": enredo / JuicioCombate3D.RECARGA_LIGERA,
		"puede_cubrir_cada_telegrafo": puede_interrumpir and recarga_fuerte <= ciclo_rival,
	}


func _imprimir_matriz(escenarios: Array) -> void:
	print(
		"| escenario | det. | radio | vel. rival | DPS ligero | DPS fuerte | contra | enredo/recargas | cubre telegrafo |"
	)
	print("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | :---: |")
	for fila in escenarios:
		print(
			(
				"| %s | %d | %.2f | %.2f | %.2f | %.2f | %d | %.2f | %s |"
				% [
					fila["nombre"],
					fila["determinacion"],
					fila["radio"],
					fila["velocidad_rival"],
					fila["dps_ligero"],
					fila["dps_fuerte"],
					fila["contraataque"],
					fila["cobertura_enredo_recargas"],
					"sí" if fila["puede_cubrir_cada_telegrafo"] else "no",
				]
			)
		)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		return
	_fallos += 1
	push_error("FALLO #912: %s" % nombre)
