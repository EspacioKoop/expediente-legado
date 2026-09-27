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
		(
			float(suave["decals"][0]["opacidad"]) < float(intenso["decals"][0]["opacidad"])
			and float(intenso["decals"][0]["opacidad"]) < 0.5
		),
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

	_comprobar_lote_materializado(carteles)
	_comprobar_material_declarado()

	print("horror_texturas_smoke: %d fallos" % fallos)
	quit(1 if fallos > 0 else 0)


## El lote 128x128 ya vive en Git LFS: todo lo que planifica un perfil debe
## aplicarse de verdad. Si falta una pieza, `aplicar` la salta en silencio y el
## sueño vuelve al fallback sin que nada lo avise; esta comprobación lo impide.
func _comprobar_lote_materializado(carteles: Array) -> void:
	for perfil in HorrorTexturas.PERFILES:
		var espacio := {"carteles": carteles, "figuras": []}
		var forma := "crucero"
		if perfil == "archivo":
			forma = "escalera"
		else:
			espacio["identidad_onirica"] = perfil
		var aplicado := HorrorTexturas.aplicar(espacio, forma, HorrorTexturas.NIVEL_MAX)
		comprobar(
			"%s aplica su perfil con el lote instalado" % perfil,
			aplicado.get("horror_perfil", "") == perfil,
		)
		for clave in ["textura_muro", "textura_suelo"]:
			comprobar(
				"%s: %s es la del perfil" % [perfil, clave],
				aplicado.has(clave) and _carga_128(String(aplicado[clave]), false),
			)
		var decals: Array = aplicado.get("decals", [])
		comprobar("%s: las tres marcas existen" % perfil, decals.size() == 3)
		for entrada in decals:
			var ruta := String(entrada["ruta"])
			comprobar("%s: %s carga con alfa" % [perfil, ruta.get_file()], _carga_128(ruta, true))


## Las presentaciones abiertas de montaña y desierto sustituyen la malla que
## Espacio3D vistió originalmente. Este puente debe trasladar también la textura,
## escala y warp declarados, o el perfil queda aplicado solo a una malla oculta.
func _comprobar_material_declarado() -> void:
	var base := {
		"identidad_onirica": "desierto",
		"carteles": [],
		"figuras": [],
		"deformacion_textura": Vector3(0.52, 1.0, 2.4),
		"preservar_detalle_textura": true,
	}
	var espacio := HorrorTexturas.aplicar(base, "peine", HorrorTexturas.NIVEL_MAX)
	var material := Espacio3D.material_declarado(
		espacio,
		"textura_suelo",
		Color(0.58, 0.39, 0.20),
	)
	var textura = material.get_shader_parameter("textura") as Texture2D
	comprobar(
		"la malla alternativa activa la textura declarada",
		bool(material.get_shader_parameter("con_textura")),
	)
	comprobar(
		"la malla alternativa carga el PNG 128x128",
		textura != null and textura.get_size() == Vector2(128, 128),
	)
	comprobar(
		"la malla alternativa conserva la escala del perfil",
		is_equal_approx(
			float(material.get_shader_parameter("escala_textura")),
			1.0 / float(espacio["escala_textura"]),
		),
	)
	comprobar(
		"la malla alternativa conserva el warp onírico",
		material.get_shader_parameter("deformacion_textura") == base["deformacion_textura"],
	)
	comprobar(
		"la malla alternativa conserva el detalle opt-in",
		bool(material.get_shader_parameter("preservar_detalle_textura")),
	)


func _carga_128(ruta: String, exigir_alfa: bool) -> bool:
	if not ResourceLoader.exists(ruta):
		return false
	var textura := ResourceLoader.load(ruta, "Texture2D") as Texture2D
	if textura == null or textura.get_size() != Vector2(128, 128):
		return false
	if not exigir_alfa:
		return true
	var imagen := textura.get_image()
	return imagen != null and imagen.detect_alpha() != Image.ALPHA_NONE


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
