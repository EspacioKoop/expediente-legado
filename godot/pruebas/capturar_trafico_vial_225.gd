## Evidencia reproducible del gate visual de #225.
##
## Captura cuatro vistas del trayecto real con la camara jugable y sin HUD:
## barrera/conos, las dos tapas y el corredor central. El manifiesto inventaria
## las cinco instancias CC0 y registra en que encuadres cae el centro visual.
##
## La cobertura de frustum y las medidas son evidencia objetiva; no sustituyen
## el juicio humano de epoca, escala, clipping o legibilidad.
extends SceneTree

const TAMANO := Vector2i(1280, 720)
const FOV := 75.0
const FRAMES_ESTABILIZACION := 3

const CASOS := [
    {
        "id": "barrera_conos",
        "posicion": Vector3(0.0, 0.0, 2.0),
        "objetivo": Vector3(3.25, 0.55, 6.0),
        "criterio": "barrera y conos se leen como dressing secundario, plausibles para 1998 y sin clipping",
    },
    {
        "id": "tapa_sur",
        "posicion": Vector3(0.0, 0.0, -2.0),
        "objetivo": Vector3(-2.0, 0.05, -5.0),
        "criterio": "la tapa sur queda apoyada y legible sin z-fighting ni escala impropia",
    },
    {
        "id": "tapa_norte",
        "posicion": Vector3(0.0, 0.0, 8.0),
        "objetivo": Vector3(2.0, 0.05, 11.0),
        "criterio": "la tapa norte se integra en el asfalto sin destacar como objetivo interactivo",
    },
    {
        "id": "paso_central",
        "posicion": Vector3(0.0, 0.0, 0.0),
        "objetivo": Vector3(0.0, 1.45, 13.0),
        "criterio": "el eje central sigue libre y el lote no domina la lectura del trayecto",
    },
]

const OBJETOS := ["TapaSur", "TapaNorte", "Barrera", "ConoSur", "ConoNorte"]


func _init() -> void:
    var argumentos := OS.get_cmdline_user_args()
    var salida := (
        String(argumentos[0])
        if argumentos.size() > 0
        else OS.get_user_data_dir().path_join("evidencia-trafico-vial-225")
    )
    if not salida.is_absolute_path():
        salida = ProjectSettings.globalize_path("res://").path_join(salida)
    var error_dir := DirAccess.make_dir_recursive_absolute(salida)
    if error_dir != OK:
        printerr("No se pudo crear %s (error %d)" % [salida, error_dir])
        quit(1)
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
    dia._entrar_en("trayecto")
    await process_frame

    var lote := dia._mundo.get_node_or_null("TraficoVialCC0") as Node3D
    if lote == null:
        printerr("Falta TraficoVialCC0: #225 no esta montado en el trayecto real")
        quit(1)
        return

    var objetos := _inventariar_objetos(lote)
    if objetos.size() != OBJETOS.size():
        quit(1)
        return

    var manifiesto := {
        "issue": 225,
        "escena": "res://escenas/dia.tscn",
        "fase": "trayecto",
        "locale": TranslationServer.get_locale(),
        "tamano": [TAMANO.x, TAMANO.y],
        "fov": FOV,
        "hud": false,
        "camara": "jugable",
        "criterio": "evidencia_para_revision_humana",
        "veredicto_automatico": false,
        "instancias_cc0": objetos.size(),
        "objetos": objetos,
        "casos": [],
    }

    for caso in CASOS:
        var camara := _preparar_camara(dia, caso)
        if camara == null:
            quit(1)
            return
        for i in FRAMES_ESTABILIZACION:
            await process_frame
        _ocultar_hud(dia)
        await RenderingServer.frame_post_draw

        _registrar_cobertura(objetos, lote, camara, String(caso["id"]))

        var archivo := "%s.png" % String(caso["id"])
        var destino := salida.path_join(archivo)
        if not _guardar_captura(destino):
            quit(1)
            return
        manifiesto["casos"].append(
            {
                "id": String(caso["id"]),
                "captura": archivo,
                "criterio": String(caso["criterio"]),
                "camara_mundo": _vector_a_array(camara.global_position),
                "sha256": FileAccess.get_sha256(destino),
            }
        )

    var ruta_manifiesto := salida.path_join("manifest.json")
    var archivo_manifiesto := FileAccess.open(ruta_manifiesto, FileAccess.WRITE)
    if archivo_manifiesto == null:
        printerr("No se pudo crear %s" % ruta_manifiesto)
        quit(1)
        return
    archivo_manifiesto.store_string(JSON.stringify(manifiesto, "\t") + "\n")
    archivo_manifiesto.close()
    print("evidencia #225 -> %s" % salida)
    quit(0)


func _inventariar_objetos(lote: Node3D) -> Array:
    var inventario := []
    for nombre in OBJETOS:
        var nodo := lote.get_node_or_null(nombre) as Node3D
        if nodo == null:
            printerr("Falta instancia de #225: %s" % nombre)
            continue
        var caja := _aabb_visual(nodo)
        if caja.size == Vector3.ZERO:
            printerr("Instancia de #225 sin malla visible: %s" % nombre)
            continue
        inventario.append(
            {
                "nodo": String(nombre),
                "tamano_m": _vector_a_array(caja.size),
                "centro_mundo": _vector_a_array(caja.get_center()),
                "vistas": [],
                "pantalla_por_vista": {},
            }
        )
    return inventario


func _preparar_camara(dia, caso: Dictionary) -> Camera3D:
    dia._caminante.situar(Vector3(caso["posicion"]), 0.0)
    dia._caminante.set_physics_process(false)
    var camara := dia._caminante.get_node("Camara") as Camera3D
    if camara == null:
        printerr("No existe la camara jugable")
        return null
    camara.fov = FOV
    camara.make_current()
    camara.look_at(Vector3(caso["objetivo"]), Vector3.UP)
    return camara


func _registrar_cobertura(
    objetos: Array, lote: Node3D, camara: Camera3D, vista: String
) -> void:
    for objeto in objetos:
        var nodo := lote.get_node_or_null(String(objeto["nodo"])) as Node3D
        if nodo == null:
            continue
        var centro := _aabb_visual(nodo).get_center()
        if not camara.is_position_in_frustum(centro):
            continue
        objeto["vistas"].append(vista)
        var punto := camara.unproject_position(centro)
        objeto["pantalla_por_vista"][vista] = [roundi(punto.x), roundi(punto.y)]


func _aabb_visual(nodo: Node3D) -> AABB:
    var caja := AABB()
    for hijo in nodo.find_children("*", "MeshInstance3D", true, false):
        var malla := hijo as MeshInstance3D
        if malla == null or malla.mesh == null:
            continue
        var limites: AABB = malla.global_transform * malla.get_aabb()
        caja = limites if caja.size == Vector3.ZERO else caja.merge(limites)
    return caja


func _ocultar_hud(dia) -> void:
    if dia._hud_prioridades != null:
        dia._hud_prioridades.visible = false
    for capa in dia.find_children("*", "CanvasLayer", true, false):
        if capa is CanvasLayer:
            capa.visible = false


func _guardar_captura(destino: String) -> bool:
    var imagen := root.get_texture().get_image()
    if imagen == null or imagen.is_empty():
        printerr("Viewport vacio para %s" % destino)
        return false
    if imagen.get_size() != TAMANO:
        printerr("Resolucion inesperada para #225: %s; esperada %s" % [imagen.get_size(), TAMANO])
        return false
    var error_png := imagen.save_png(destino)
    if error_png != OK:
        printerr("No se pudo guardar %s (error %d)" % [destino, error_png])
        return false
    print("captura -> %s" % destino)
    return true


func _vector_a_array(vector: Vector3) -> Array:
    return [vector.x, vector.y, vector.z]
