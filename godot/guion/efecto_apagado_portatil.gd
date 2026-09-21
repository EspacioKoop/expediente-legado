## Residuo visual/sonoro de apagado para la Portátil Color 98 (#1055).
##
## Vive fuera de EmuladorPortatilApp: recibe únicamente una textura ya producida
## y un sonido físico opcional. No conoce Siga98GB, SRAM, ROMs ni campaña.
class_name EfectoApagadoPortatil
extends CanvasLayer

const DURACION_AFTERGLOW := 0.18

var _vista: TextureRect
var _tiempo_restante := 0.0


func iniciar(
	textura: Texture2D, material_lcd: Material, rect: Rect2, sonido: AudioStream, volumen_db: float
) -> void:
	layer = 101
	process_mode = Node.PROCESS_MODE_ALWAYS
	_tiempo_restante = DURACION_AFTERGLOW

	if textura != null and rect.size.x > 0.0 and rect.size.y > 0.0:
		_vista = TextureRect.new()
		_vista.name = "AfterglowLCDPortatil"
		_vista.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_vista.position = rect.position
		_vista.size = rect.size
		_vista.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_vista.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_vista.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_vista.texture = textura
		_vista.material = material_lcd
		add_child(_vista)

	if sonido != null:
		var audio := AudioStreamPlayer.new()
		audio.name = "ClickApagadoPortatil"
		audio.process_mode = Node.PROCESS_MODE_ALWAYS
		audio.stream = sonido
		audio.volume_db = volumen_db
		add_child(audio)
		audio.play()

	set_process(true)


func _process(delta: float) -> void:
	_tiempo_restante = maxf(0.0, _tiempo_restante - maxf(delta, 0.0))
	var proporcion := _tiempo_restante / DURACION_AFTERGLOW
	if _vista != null:
		var brillo := lerpf(0.46, 1.0, proporcion)
		_vista.modulate = Color(brillo, brillo, brillo, proporcion)
	if _tiempo_restante <= 0.0:
		queue_free()
