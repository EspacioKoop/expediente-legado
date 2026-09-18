## Regresión ejecutable de la escalada visual del Horror Texture Pack (#231).
##
##     godot4 --headless --path godot --script pruebas/horror_texturas_smoke.gd
extends SceneTree

var fallos := 0


func _init() -> void:
	var carteles := [
		{"pos": Vector3(-2.0, 0.0, -4.0), "giro": 0.0},
		{"pos": Vector3(3.0, 0.0, 5.0), "giro": PI},
		{"pos": Vector3(6.0, 0.0, 1.0), "giro": PI / 2.0},
	]
	var escuela := {
		"identidad_onirica": "escuela",
		"carteles": carteles,
		"figuras": [],
	}

	var suave := HorrorTexturas.planificar(escuela, "crucero", 1)
	var intenso := HorrorTexturas.planificar(escuela, "crucero", 3)
	comprobar("la identidad manda sobre la forma", suave["perfil"] == "escuela")
	comprobar("nivel uno conserva el suelo", not suave.has("textura_suelo"))
	comprobar("nivel dos o más invade el suelo", intenso.has("textura_suelo"))
	comprobar("nivel uno monta una marca como máximo", suave["decals"].size() == 1)
	comprobar("nivel tres puede usar tres marcas", intenso["decals"].size() == 3)
	comprobar(
		"la opacidad escala sin hacerse opaca",
		float(suave["decals"][0]["opacidad"]) < float(intenso["decals"][0]["opacidad"])
		and float(intenso["decals"][0]["opacidad"]) < 0.5,
	)

	for entrada in intenso["decals"]:
		var ruta := String(entrada["ruta"])
		comprobar("ninguna selección automática usa sangre", not _es_mancha_excluida(ruta))

	comprobar("primera sala = desgaste suave", HorrorTexturas.nivel_para_noche(3, 3) == 1)
	comprobar("segunda sala = desgaste medio", HorrorTexturas.nivel_para_noche(3, 2) == 2)
	comprobar("última sala = desgaste alto", HorrorTexturas.nivel_para_noche(3, 1) == 3)
	comprobar("noche de una sala no fuerza clímax", HorrorTexturas.nivel_para_noche(1, 1) == 2)

	var con_duelo := escuela.duplicate(true)
	con_duelo["figuras"] = [{"duelo": "acusado-1"}]
	comprobar(
		"un acusado refuerza una sala ya cargada",
		HorrorTexturas.nivel_para_noche(3, 2, con_duelo) == 3,
	)

	var montana := {"identidad_onirica": "montana"}
	comprobar(
		"montaña usa perfil mineral propio",
		HorrorTexturas.perfil_de(montana, "embudo") == "montana",
	)
	comprobar(
		"una forma genérica conserva lectura de archivo",
		HorrorTexturas.perfil_de({}, "escalera") == "archivo",
	)

	print("horror_texturas_smoke: %d fallos" % fallos)
	quit(1 if fallos > 0 else 0)


func _es_mancha_excluida(ruta: String) -> bool:
	for indice in range(1, 6):
		if ruta.contains("Horror_Stain_%02d" % indice):
			return true
	return false


func comprobar(nombre: String, condicion: bool) -> void:
	if condicion:
		print("  OK  %s" % nombre)
		return
	fallos += 1
	printerr("FALLO %s" % nombre)
