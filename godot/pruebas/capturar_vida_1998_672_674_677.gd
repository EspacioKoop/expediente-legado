## Evidencia reproducible conjunta para #672, #674 y #677.
##
## Captura el recorrido real sin HUD para revisar:
## 1) el buzón postal integrado junto al portal;
## 2) una publicación encontrable en casa antes de recogerla;
## 3) la acumulación doméstica alimentada por tres productores reales;
## 4) el calendario postal colocado en la nevera.
##
## El runner no concede un PASS artístico ni sustituye el pase con teclado/mando.
extends SceneTree

const TAMANO := Vector2i(1280, 720)
const FOV := 70.0
const FRAMES_ESTABILIZACION := 4

const ID_COMERCIO := "lampara_verde_usada"
const ID_POSTAL := "postal_iman_calendario"
const ID_PUBLICACION := "manual_casa_98"

const CASOS := [
	{
		"id": "buzon_portal",
		"fase": "trayecto",
		"criterio":
		"el buzón se localiza junto al portal, se reconoce como objeto interactivo y no bloquea el paso",
	},
	{
		"id": "publicacion_encontrable",
		"fase": "casa",
		"criterio": "Manual de Casa se reconoce como publicación física encontrable sobre el sofá",
	},
	{
		"id": "acumulacion_tres_fuentes",
		"fase": "casa",
		"criterio":
		"la estantería presenta objetos persistentes sin clipping ni lectura de colección puntuable",
	},
	{
		"id": "calendario_nevera",
		"fase": "casa",
		"criterio":
		"el calendario recibido por correo se lee como papel o imán colocado sobre la nevera",
	},
]


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-vida-1998")
	)
	if not salida.is_absolute_path():
		salida = ProjectSettings.globalize_path("res://").path_join(salida)
	var error_dir := DirAccess.make_dir_recursive_absolute(salida)
	if error_dir != OK:
		_fallar("No se pudo crear %s (error %d)" % [salida, error_dir])
		return

	TranslationServer.set_locale("es")
	root.size = TAMANO
	var dia = load("res://escenas/dia.tscn").instantiate()
	root.add_child(dia)
	await process_frame

	if dia._entrada != null:
		dia._entrada.saltar()
		await process_frame
	dia.set_process(false)

	dia.jornada["dia"] = 4
	dia.jornada["dinero"] = maxi(200, int(dia.jornada.get("dinero", 0)))
	var inventario = dia.partida.estado.get("inventario", {})
	if typeof(inventario) != TYPE_DICTIONARY:
		inventario = Inventario.nuevo()
		dia.partida.estado["inventario"] = inventario
	Inventario.completar(inventario)

	dia._entrar_en("trayecto")
	if not await _esperar_nodo(dia, "BuzonPostal"):
		_fallar("El trayecto no montó BuzonPostal")
		return
	var buzon := dia._mundo.get_node_or_null("BuzonPostal") as Node3D
	if buzon == null:
		_fallar("BuzonPostal no es Node3D")
		return
	if not await _capturar_objetivo(
		dia,
		salida,
		CASOS[0],
		Vector3(0.15, 0.0, 12.7),
		buzon.global_position + Vector3(0.0, 0.12, 0.0)
	):
		return

	var compra := ComercioBarrio.comprar(dia.jornada, inventario, "segunda_mano", ID_COMERCIO)
	if not bool(compra.get("ok", false)):
		_fallar("No se pudo preparar objeto de comercio: %s" % String(compra.get("motivo", "")))
		return

	var postal := CorreoPostal.recoger(dia.jornada, inventario, "paquete_calendario_magnetico")
	if not bool(postal.get("ok", false)):
		_fallar("No se pudo preparar objeto postal: %s" % String(postal.get("motivo", "")))
		return
	if not Inventario.guardar_en_casa(inventario, ID_POSTAL):
		_fallar("El calendario postal no pudo pasar a home_storage")
		return

	dia._entrar_en("casa")
	if not await _esperar_nodo(dia, "PublicacionEncontrable_%s" % ID_PUBLICACION, true):
		_fallar("La casa no montó la publicación encontrable de #674")
		return
	var publicacion_mundo := (
		dia._mundo.find_child("PublicacionEncontrable_%s" % ID_PUBLICACION, true, false) as Node3D
	)
	if publicacion_mundo == null:
		_fallar("La publicación encontrable no es Node3D")
		return
	if not await _capturar_objetivo(
		dia,
		salida,
		CASOS[1],
		Vector3(0.55, 0.0, 2.35),
		publicacion_mundo.global_position + Vector3(0.0, 0.08, 0.0)
	):
		return

	var objeto_publicacion := PublicacionesEncontrables3D.objeto_inventario(ID_PUBLICACION)
	if objeto_publicacion.is_empty() or not Inventario.recoger(inventario, objeto_publicacion):
		_fallar("No se pudo preparar la publicación en Inventario")
		return
	if not Inventario.guardar_en_casa(inventario, ID_PUBLICACION):
		_fallar("La publicación no pudo pasar a home_storage")
		return

	if not await _esperar_nodo(dia, "AcumulacionCasa"):
		_fallar("La casa no refrescó AcumulacionCasa")
		return
	for _i in FRAMES_ESTABILIZACION:
		await process_frame

	var estanteria := dia._mundo.get_node_or_null("EstanteriaComprasCasa") as Node3D
	if estanteria == null:
		_fallar("Falta EstanteriaComprasCasa")
		return
	if not await _capturar_objetivo(
		dia,
		salida,
		CASOS[2],
		Vector3(1.25, 0.0, -0.90),
		estanteria.global_position + Vector3(0.0, 0.88, 0.0)
	):
		return

	if not await _esperar_nodo(dia, CasaAcumulacion3D.NOMBRE_IMAN_CALENDARIO, true):
		_fallar("El calendario postal no se materializó en la nevera")
		return
	var calendario := (
		dia._mundo.find_child(CasaAcumulacion3D.NOMBRE_IMAN_CALENDARIO, true, false) as Node3D
	)
	if calendario == null:
		_fallar("El calendario postal materializado no es Node3D")
		return
	if not await _capturar_objetivo(
		dia,
		salida,
		CASOS[3],
		Vector3(2.85, 0.0, -1.55),
		calendario.global_position + Vector3(0.0, 0.08, 0.0)
	):
		return

	var fuentes := _fuentes_home_storage(inventario)
	if fuentes.size() != 3:
		_fallar("Se esperaban tres productores reales en home_storage")
		return

	var manifiesto := {
		"issues": [672, 674, 677],
		"escena": "res://escenas/dia.tscn",
		"locale": TranslationServer.get_locale(),
		"tamano": [TAMANO.x, TAMANO.y],
		"fov": FOV,
		"hud": false,
		"camara": "jugable",
		"criterio": "evidencia_para_revision_humana",
		"veredicto_automatico": false,
		"fuentes_home_storage": fuentes,
		"capturas": [],
	}
	for caso in CASOS:
		var archivo := "%s.png" % String(caso["id"])
		var destino := salida.path_join(archivo)
		(
			manifiesto["capturas"]
			. append(
				{
					"id": String(caso["id"]),
					"fase": String(caso["fase"]),
					"captura": archivo,
					"criterio": String(caso["criterio"]),
					"sha256": FileAccess.get_sha256(destino),
				}
			)
		)

	var ruta_manifiesto := salida.path_join("manifest.json")
	var archivo_manifiesto := FileAccess.open(ruta_manifiesto, FileAccess.WRITE)
	if archivo_manifiesto == null:
		_fallar("No se pudo crear %s" % ruta_manifiesto)
		return
	archivo_manifiesto.store_string(JSON.stringify(manifiesto, "\t") + "\n")
	archivo_manifiesto.close()
	print("evidencia #672/#674/#677 -> %s" % salida)
	quit(0)


func _esperar_nodo(dia, nombre: String, recursivo := false) -> bool:
	for _i in 12:
		var nodo = (
			dia._mundo.find_child(nombre, true, false)
			if recursivo
			else dia._mundo.get_node_or_null(nombre)
		)
		if nodo != null:
			return true
		await process_frame
	return false


func _capturar_objetivo(
	dia,
	salida: String,
	caso: Dictionary,
	posicion: Vector3,
	objetivo: Vector3,
) -> bool:
	dia._caminante.situar(posicion, 0.0)
	dia._caminante.set_physics_process(false)
	var camara := dia._caminante.get_node("Camara") as Camera3D
	if camara == null:
		_fallar("Falta la cámara jugable")
		return false
	camara.fov = FOV
	camara.look_at(objetivo, Vector3.UP)
	_ocultar_hud(dia)
	for _i in FRAMES_ESTABILIZACION:
		await process_frame
	await RenderingServer.frame_post_draw

	var destino := salida.path_join("%s.png" % String(caso["id"]))
	var imagen := root.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		_fallar("Viewport vacío para %s" % destino)
		return false
	var error_png := imagen.save_png(destino)
	if error_png != OK:
		_fallar("No se pudo guardar %s (error %d)" % [destino, error_png])
		return false
	print("captura -> %s" % destino)
	return true


func _fuentes_home_storage(inventario: Dictionary) -> Array[Dictionary]:
	var esperados := {
		ID_COMERCIO: "comercio_barrio",
		ID_POSTAL: "correo_postal",
		ID_PUBLICACION: PublicacionesEncontrables3D.ORIGEN,
	}
	var salida: Array[Dictionary] = []
	for objeto in inventario.get(Inventario.HOME_STORAGE, []):
		if not objeto is Dictionary:
			continue
		var objeto_id := String(objeto.get("id", ""))
		if not esperados.has(objeto_id):
			continue
		(
			salida
			. append(
				{
					"id": objeto_id,
					"origen": String(objeto.get("origen", "")),
					"origen_esperado": String(esperados[objeto_id]),
					"ubicacion": Inventario.HOME_STORAGE,
				}
			)
		)
	salida.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["id"] < b["id"])
	return salida


func _ocultar_hud(dia) -> void:
	if dia._hud_prioridades != null:
		dia._hud_prioridades.visible = false
	for capa in dia.find_children("*", "CanvasLayer", true, false):
		if capa is CanvasLayer:
			capa.visible = false


func _fallar(mensaje: String) -> void:
	printerr(mensaje)
	quit(1)
