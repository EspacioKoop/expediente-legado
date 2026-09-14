## Suite del primer corte del port a Godot. Se ejecuta sin abrir el editor:
##
##     godot4 --headless --path godot --script pruebas/pruebas.gd
##
## Los casos vienen de las pruebas JUnit del backend Java (WikiLinkServiceTest,
## HotspotServiceTest, CartaOcultaServiceTest, ProgresoServiceTest), portadas
## una a una: si el port cambia una decisión del original, la prueba lo dice.
extends SceneTree

var fallos := 0
var pasadas := 0

func _init() -> void:
    _marcas_hotspot()
    _marcas_cartas()
    _marcas_referencias()
    _marcas_solapamiento()
    _bbcode()
    _progreso()
    _contenido()

    var comprobar_cb := Callable(self, "comprobar")

    PruebasPrometeoYCombate._prometeo(comprobar_cb)
    PruebasPrometeoYCombate._partida(comprobar_cb)
    _partida_validacion(comprobar_cb)
    PruebasPrometeoYCombate._guardado_seguro(comprobar_cb)
    PruebasPrometeoYCombate._borrar_el_avance(comprobar_cb)
    PruebasPrometeoYCombate._historias(comprobar_cb)
    PruebasPrometeoYCombate._combate(comprobar_cb)
    PruebasPrometeoYCombate._ventanilla(comprobar_cb)
    PruebasPrometeoYCombate._jornada(comprobar_cb)
    PruebasAlquiler.todo(comprobar_cb)
    PruebasPrometeoYCombate._procedencia(comprobar_cb)
    PruebasGrabacionOnirica.todo(comprobar_cb)  # <-- Added test for dream recording contract

    PruebasEspaciosYSueno._espacios(comprobar_cb)
    PruebasEspaciosYSueno._acciones_y_vuelta(comprobar_cb)
    PruebasEspaciosYSueno._acusacion(comprobar_cb)
    PruebasEspaciosYSueno._careo(comprobar_cb)
    PruebasCinematicasYMando._cinematicas(comprobar_cb)
    PruebasCinematicasYMando._mando(comprobar_cb)
    PruebasEspaciosYSueno._plantas(comprobar_cb)
    PruebasEspaciosYSueno._sueno(comprobar_cb)
    PruebasEspaciosYSueno._traducciones(comprobar_cb)
    PruebasEspaciosYSueno._sueno_contenido(comprobar_cb)
    _noche_degradada(comprobar_cb)

    PruebasSuenoFinal._compilan(comprobar_cb)
    PruebasSuenoFinal._salida_del_sueno(comprobar_cb)
    PruebasSuenoFinal._jornada_antigua(comprobar_cb)
    PruebasSuenoFinal._companeros(comprobar_cb)
    PruebasSuenoFinal._sonido(comprobar_cb)
    PruebasSuenoFinal._sueno_combate(comprobar_cb)

    PruebasGato._gato(comprobar_cb)
    PruebasGato._cuenco(comprobar_cb)
    PruebasGato._malla(comprobar_cb)

    PruebasSemilla._semilla(comprobar_cb)

    PruebasHistoria.catalogo(comprobar_cb)
    _archivado(comprobar_cb)

    print("\\n%d pasadas, %d fallos" % [pasadas, fallos])
    quit(1 if fallos > 0 else 0)