## Cola local y materialidad mínima para la impresora térmica ficticia de #1054.
##
## Este módulo no sabe de campaña ni de emulación. Recibe imágenes explícitas,
## las convierte a una trama monocroma reproducible y mantiene una única tira
## física disponible. Un backend de protocolo futuro solo necesita alimentar
## aceptar_framebuffer_rgba() o encolar_imagen().
class_name ImpresoraTermicaPortatil
extends RefCounted

signal estado_cambiado(estado: int)
signal impresion_iniciada
signal progreso_cambiado(progreso: float)
signal papel_listo(imagen: Image)
signal papel_recogido

enum Estado {
	APAGADA,
	LISTA,
	IMPRIMIENDO,
	PAPEL_DISPONIBLE,
}

const ANCHO_PAPEL := 160
const ALTO_MAXIMO := 360
const ALTO_PRUEBA := 112
const PIXELES_POR_SEGUNDO := 9200.0
const TRAMA_4X4 := [
	0.0,
	0.5,
	0.125,
	0.625,
	0.75,
	0.25,
	0.875,
	0.375,
	0.1875,
	0.6875,
	0.0625,
	0.5625,
	0.9375,
	0.4375,
	0.8125,
	0.3125,
]

var _estado := Estado.APAGADA
var _cola: Array[Image] = []
var _trabajo_actual: Image = null
var _papel: Image = null
var _progreso := 0.0
var _duracion_trabajo := 0.0


func estado() -> int:
	return _estado


func esta_encendida() -> bool:
	return _estado != Estado.APAGADA


func cantidad_en_cola() -> int:
	return _cola.size()


func progreso() -> float:
	return _progreso


func encender() -> void:
	if _estado != Estado.APAGADA:
		return
	if _papel != null:
		_cambiar_estado(Estado.PAPEL_DISPONIBLE)
		return
	_cambiar_estado(Estado.LISTA)
	_intentar_iniciar()


func apagar() -> void:
	if _estado == Estado.APAGADA:
		return
	if _trabajo_actual != null:
		_cola.push_front(_trabajo_actual)
	_trabajo_actual = null
	_progreso = 0.0
	_duracion_trabajo = 0.0
	progreso_cambiado.emit(_progreso)
	_cambiar_estado(Estado.APAGADA)


func encolar_imagen(imagen: Image) -> bool:
	if imagen == null or imagen.is_empty():
		return false
	var tira := _termalizar(imagen)
	if tira == null or tira.is_empty():
		return false
	_cola.append(tira)
	_intentar_iniciar()
	return true


## Contrato estable para un adaptador futuro: Godot entrega RGBA explícito y la
## cola sigue siendo dueña de estado, papel y temporización.
func aceptar_framebuffer_rgba(datos: PackedByteArray, ancho: int, alto: int) -> bool:
	if ancho <= 0 or alto <= 0 or datos.size() != ancho * alto * 4:
		return false
	var imagen := Image.create_from_data(ancho, alto, false, Image.FORMAT_RGBA8, datos)
	return encolar_imagen(imagen)


func avanzar(delta: float) -> void:
	if _estado != Estado.IMPRIMIENDO or _trabajo_actual == null:
		return
	if delta <= 0.0:
		return
	_progreso = clampf(_progreso + delta / _duracion_trabajo, 0.0, 1.0)
	progreso_cambiado.emit(_progreso)
	if _progreso < 1.0:
		return

	_papel = _trabajo_actual
	_trabajo_actual = null
	_progreso = 1.0
	_cambiar_estado(Estado.PAPEL_DISPONIBLE)
	papel_listo.emit(_papel.duplicate())


func papel_actual() -> Image:
	if _papel == null:
		return null
	return _papel.duplicate()


func recoger_papel() -> Image:
	if _papel == null:
		return null
	var recogido := _papel.duplicate()
	_papel = null
	_progreso = 0.0
	papel_recogido.emit()
	if _estado != Estado.APAGADA:
		_cambiar_estado(Estado.LISTA)
		_intentar_iniciar()
	return recogido


static func crear_patron_prueba() -> Image:
	var imagen := Image.create(ANCHO_PAPEL, ALTO_PRUEBA, false, Image.FORMAT_RGBA8)
	var papel := Color(0.96, 0.94, 0.86, 1.0)
	var tinta := Color(0.12, 0.10, 0.09, 1.0)
	imagen.fill(papel)
	for y in range(ALTO_PRUEBA):
		for x in range(ANCHO_PAPEL):
			var borde := x < 4 or x >= ANCHO_PAPEL - 4 or y < 4 or y >= ALTO_PRUEBA - 4
			var diagonal := (x + y * 2) % 29 < 3
			var reticula := int(x / 12) + int(y / 12)
			if borde or (diagonal and reticula % 2 == 0):
				imagen.set_pixel(x, y, tinta)
	return imagen


func _intentar_iniciar() -> void:
	if _estado != Estado.LISTA or _cola.is_empty():
		return
	_trabajo_actual = _cola.pop_front()
	_progreso = 0.0
	var pixeles := float(_trabajo_actual.get_width() * _trabajo_actual.get_height())
	_duracion_trabajo = maxf(0.45, pixeles / PIXELES_POR_SEGUNDO)
	_cambiar_estado(Estado.IMPRIMIENDO)
	impresion_iniciada.emit()
	progreso_cambiado.emit(_progreso)


func _cambiar_estado(nuevo: int) -> void:
	if _estado == nuevo:
		return
	_estado = nuevo
	estado_cambiado.emit(_estado)


static func _termalizar(origen: Image) -> Image:
	var copia: Image = origen.duplicate()
	if copia.get_format() != Image.FORMAT_RGBA8:
		copia.convert(Image.FORMAT_RGBA8)

	if copia.get_width() != ANCHO_PAPEL:
		var proporcion := float(ANCHO_PAPEL) / float(maxi(1, copia.get_width()))
		var alto := clampi(int(round(copia.get_height() * proporcion)), 1, ALTO_MAXIMO)
		copia.resize(ANCHO_PAPEL, alto, Image.INTERPOLATE_NEAREST)
	elif copia.get_height() > ALTO_MAXIMO:
		copia.resize(ANCHO_PAPEL, ALTO_MAXIMO, Image.INTERPOLATE_NEAREST)

	var salida := (
		Image
		. create(
			copia.get_width(),
			copia.get_height(),
			false,
			Image.FORMAT_RGBA8,
		)
	)
	var papel := Color(0.96, 0.94, 0.86, 1.0)
	var tinta := Color(0.13, 0.11, 0.10, 1.0)
	for y in range(copia.get_height()):
		for x in range(copia.get_width()):
			var color := copia.get_pixel(x, y)
			var luminancia := color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
			var indice_trama := (y % 4) * 4 + (x % 4)
			var umbral := 0.30 + float(TRAMA_4X4[indice_trama]) * 0.40
			salida.set_pixel(x, y, tinta if luminancia < umbral else papel)
	return salida
