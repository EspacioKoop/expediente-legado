## El filtro de pantalla de época como CompositorEffect (#1270).
##
## Corre sobre el color del render 3D, después de lo transparente y ANTES del
## lienzo 2D: el visor, el HUD y los menús no pasan nunca por aquí, que es la
## frontera que puso #115. No sabe qué preajuste es: recibe intensidades.
##
## Sin RenderingDevice —renderizador de compatibilidad, `--headless`— no hace
## nada, y eso es un comportamiento, no un fallo: el juego se ve sin filtro.
class_name EfectoPantalla98
extends CompositorEffect

const SHADER := "res://arte/pantalla_98.glsl"
## Un grupo de trabajo por fila (ver `pantalla_98.glsl`). La fila entera cabe
## en memoria compartida hasta este ancho; por encima el pase no se lanza y la
## imagen sale sin filtro, que es mejor que una fila a medias.
const ANCHO_MAXIMO := 4096

var lineas := 0.0
var sangrado := 0.0
var franjas := 0.0
var vineta := 0.0
var grano := 0.0
var temblor := 0.0
var desfase_color := 0.0
## Cuántas líneas de vídeo caben en la altura. 240 es un televisor de 1998.
var lineas_pantalla := 240.0
## Con reducción de movimiento el tiempo no corre: ni temblor ni grano vivo.
var congelado := false

var _rd: RenderingDevice
var _shader := RID()
var _tuberia := RID()


func _init() -> void:
	effect_callback_type = CompositorEffect.EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	_rd = RenderingServer.get_rendering_device()


func _notification(que: int) -> void:
	# Al borrarse ya no se pueden llamar métodos propios: se libera aquí mismo.
	# La tubería depende del shader, así que va antes.
	if que != NOTIFICATION_PREDELETE or _rd == null:
		return
	if _tuberia.is_valid():
		_rd.free_rid(_tuberia)
	if _shader.is_valid():
		_rd.free_rid(_shader)


## Aplica un preajuste: un diccionario con las mismas claves que las variables.
func configurar(ajuste: Dictionary, reducir_movimiento: bool) -> void:
	lineas = float(ajuste.get("lineas", 0.0))
	sangrado = float(ajuste.get("sangrado", 0.0))
	franjas = float(ajuste.get("franjas", 0.0))
	vineta = float(ajuste.get("vineta", 0.0))
	grano = float(ajuste.get("grano", 0.0))
	temblor = float(ajuste.get("temblor", 0.0))
	desfase_color = float(ajuste.get("desfase_color", 0.0))
	lineas_pantalla = float(ajuste.get("lineas_pantalla", 240.0))
	congelado = reducir_movimiento


## Los push constants en el orden de `pantalla_98.glsl`. 12 floats = 48 bytes.
func parametros(tamano: Vector2i) -> PackedFloat32Array:
	var tiempo := 0.0 if congelado else float(Time.get_ticks_msec()) / 1000.0
	return PackedFloat32Array(
		[
			float(tamano.x),
			float(tamano.y),
			tiempo,
			lineas,
			sangrado,
			franjas,
			vineta,
			grano,
			temblor,
			desfase_color,
			lineas_pantalla,
			0.0,
		]
	)


func _render_callback(tipo: int, datos: RenderData) -> void:
	if _rd == null or tipo != EFFECT_CALLBACK_TYPE_POST_TRANSPARENT:
		return
	if not _preparar():
		return
	var buferes: RenderSceneBuffersRD = datos.get_render_scene_buffers()
	if buferes == null:
		return
	var tamano := buferes.get_internal_size()
	if tamano.x == 0 or tamano.y == 0 or tamano.x > ANCHO_MAXIMO:
		return
	var empuje := parametros(tamano).to_byte_array()
	for vista in buferes.get_view_count():
		var imagen := RDUniform.new()
		imagen.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		imagen.binding = 0
		imagen.add_id(buferes.get_color_layer(vista))
		var conjunto := _rd.uniform_set_create([imagen], _shader, 0)
		var lista := _rd.compute_list_begin()
		_rd.compute_list_bind_compute_pipeline(lista, _tuberia)
		_rd.compute_list_bind_uniform_set(lista, conjunto, 0)
		_rd.compute_list_set_push_constant(lista, empuje, empuje.size())
		_rd.compute_list_dispatch(lista, 1, tamano.y, 1)
		_rd.compute_list_end()
		_rd.free_rid(conjunto)


func _preparar() -> bool:
	if not _shader.is_valid():
		var fichero: RDShaderFile = load(SHADER)
		if fichero == null:
			return false
		_shader = _rd.shader_create_from_spirv(fichero.get_spirv())
		if not _shader.is_valid():
			return false
		_tuberia = _rd.compute_pipeline_create(_shader)
	return _tuberia.is_valid()
