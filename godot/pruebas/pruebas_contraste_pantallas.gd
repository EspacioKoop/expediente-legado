## Regla general de contraste sobre pantallas montadas de verdad.
##
## `pruebas_contraste_siga.gd` comprueba parejas del tema; esta monta el creador
## de personaje, cada panel del menú general y el escritorio OS98 con sus
## programas abiertos, y pasa `ContrasteTexto.auditar` por todo lo visible:
## ningún texto oscuro sobre gris y nada por debajo de AA. Un texto que falla
## sale con su ruta, sus dos colores y el motivo, para arreglarlo sin adivinar.
extends SceneTree

## Pantallas 2D que se montan solas, sin partida ni contexto que pasarles. El
## inicio no está: su menú flota sobre un diorama 3D, y lo que hay detrás de
## cada texto solo se sabe con GPU (lo cubre su gate de capturas).
const ESCENAS := [
	"res://escenas/visor.tscn",
	"res://escenas/ventanilla.tscn",
]

## Programas del OS98 que se abren como ventana real del escritorio. Los que
## necesitan una partida o un controlador para montarse se prueban en sus
## propias suites; aquí basta con que su contenido de serie se lea.
var _programas := {
	"calculadora": CalculadoraSiga,
	"bloc-notas": BlocNotasSiga,
	"correo": CorreoSiga,
	"catalogo": CatalogoAnomaliasSiga,
	"explorador": ExploradorSiga,
	"navegador": NavegadorSiga,
	"software": SoftwareSiga,
	"buscar": BuscarEjecutarSiga,
	"auditorias": AuditoriasSiga,
	"evaluacion": EvaluacionDesempenoSiga,
	"bingo": BingoSiga,
}

var _pasadas := 0
var _fallos := 0
var _fondo_ventana := Color(0.3, 0.3, 0.3)


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	TranslationServer.set_locale("es")
	_fondo_ventana = ProjectSettings.get_setting(
		"rendering/environment/defaults/default_clear_color", _fondo_ventana
	)
	_probar_regla()
	await _probar_creador()
	for escena in ESCENAS:
		await _probar_escena(escena)
	await _probar_menu_global()
	await _probar_escritorio()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


## La regla en sí, sobre colores conocidos: si esto falla, lo demás no prueba nada.
func _probar_regla() -> void:
	_comprobar(ContrasteTexto.es_gris(Color("c0c0c0")), "#c0c0c0 es gris")
	_comprobar(ContrasteTexto.es_gris(Color(0.3, 0.3, 0.3)), "el fondo de serie es gris")
	_comprobar(not ContrasteTexto.es_gris(EstiloSiga.PAPEL), "el papel del OS98 no es gris")
	_comprobar(not ContrasteTexto.es_gris(EstiloSiga.BLANCO), "el blanco no es gris")
	_comprobar(ContrasteTexto.es_oscuro(EstiloSiga.NEGRO), "el negro es oscuro")
	_comprobar(not ContrasteTexto.es_oscuro(EstiloJuego.TEXTO), "el texto del juego es claro")
	var etiqueta := Label.new()
	etiqueta.text = "prueba"
	etiqueta.add_theme_color_override("font_color", Color.BLACK)
	var gris := ColorRect.new()
	gris.color = Color("c0c0c0")
	gris.add_child(etiqueta)
	root.add_child(gris)
	_comprobar(
		ContrasteTexto.auditar(gris, _fondo_ventana).size() == 1,
		"la regla caza un negro sobre #c0c0c0",
	)
	gris.color = EstiloSiga.PAPEL
	_comprobar(
		ContrasteTexto.auditar(gris, _fondo_ventana).is_empty(), "y lo deja pasar sobre papel"
	)
	gris.free()


func _probar_creador() -> void:
	var creador: Node = load("res://escenas/creador_personaje.tscn").instantiate()
	root.add_child(creador)
	await _asentar()
	_auditar("creador de personaje", creador)
	creador.queue_free()
	await process_frame


func _probar_escena(ruta: String) -> void:
	var escena: Node = load(ruta).instantiate()
	root.add_child(escena)
	await _asentar()
	_auditar(ruta.get_file().get_basename(), escena)
	escena.queue_free()
	await process_frame


func _probar_menu_global() -> void:
	var menu := root.get_node("MenuGlobal")
	menu._abrir()
	await _asentar()
	_auditar("menú general", menu)
	for vista in ["_mostrar_opciones", "_mostrar_sellos", "_mostrar_historial"]:
		menu.call(vista)
		await _asentar()
		_auditar("menú general %s" % vista.trim_prefix("_mostrar_"), menu)
	menu._cerrar()
	paused = false


func _probar_escritorio() -> void:
	var escritorio := EscritorioSigaVisual.new()
	root.add_child(escritorio)
	await _asentar()
	_auditar("escritorio OS98", escritorio)
	for id in _programas:
		var clase: GDScript = _programas[id]
		escritorio.registrar_aplicacion(id, id.capitalize(), func(): return clase.new())
		escritorio.abrir_aplicacion(id)
		await _asentar()
		_auditar("OS98 %s" % id, escritorio)
		escritorio.cerrar(id)
		await process_frame
	escritorio.queue_free()
	await process_frame


func _auditar(pantalla: String, raiz: Node) -> void:
	var fallos := ContrasteTexto.auditar(raiz, _fondo_ventana)
	for fallo in fallos:
		push_error(
			(
				"%s · %s «%s»: %s (%s sobre %s)"
				% [
					pantalla,
					fallo["ruta"],
					fallo["texto"],
					fallo["motivo"],
					fallo["frente"],
					fallo["fondo"],
				]
			)
		)
	_comprobar(fallos.is_empty(), "%s: %d textos ilegibles" % [pantalla, fallos.size()])


func _asentar() -> void:
	for i in 3:
		await process_frame


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO: " + descripcion)
