## Las ventanas de la calle cambian de luz con el tiempo (#1230).
##
## `CalleFachadasVivas` (#861) dio profundidad a las 61 ventanas altas, pero su
## estado de luz se fija al montarlas y no cambia jamás: pases cuando pases, la
## misma tele encendida en el mismo piso. Un barrio así está habitado en la foto
## y deshabitado en el recorrido.
##
## Esta capa es **aditiva**: no toca la anterior ni sus lotes. Pone un plano
## propio unos milímetros por delante del fondo estático de las ventanas
## elegidas, todos en un único MultiMesh, y anima ese plano. Si mañana se retira
## este módulo, la calle vuelve exactamente a lo que era.
##
## El reparto lo lleva `AnimadorAmbiental3D`: una ventana a tu espalda no gasta
## nada, y al volverte está en el estado que le tocaba, no en el que la dejaste.
class_name CalleVentanasVivas
extends Node

const NOMBRE_LOTE := "VentanasVivas"
const SHADER := "res://arte/ventana_viva.gdshader"

## Una de cada tres ventanas, hasta el tope. El resto sigue siendo fondo
## estático: si se mueven todas deja de leerse como vida y pasa a leerse como
## una guirnalda.
const PASO_SELECCION := 3
const MAX_VENTANAS := 18

## Cuánto tarda una ventana en replantearse su vida, y cuánto dura el cambio.
## Casi un minuto: lo justo para que al volver por la tarde algo haya cambiado
## sin que el barrio parezca un semáforo.
const CICLO := 46.0
const FUNDIDO := 1.6

## El salto hacia la calle desde el fondo estático al que tapa.
const SALIENTE := 0.006
const TAMANO := Vector3(0.010, 1.04, 0.80)

const LOD_FIN := 72.0

## Lo que puede estar pasando dentro. Repetir una entrada es darle peso: a las
## once de la noche hay más pisos a oscuras que pisos con visita.
const SECUENCIA := ["calida", "apagada", "fria_tv", "tenue", "calida", "apagada", "persiana"]

## Los mismos colores que declara `CalleFachadasVivas` para su fondo estático:
## el plano animado sustituye al de detrás y no puede cantar contra sus vecinos.
const COLORES := {
	"calida": Color(0.30, 0.20, 0.12),
	"apagada": Color(0.055, 0.06, 0.07),
	"fria_tv": Color(0.08, 0.11, 0.22),
	"tenue": Color(0.14, 0.10, 0.07),
	"persiana": Color(0.07, 0.065, 0.06),
}

## Qué estados tiemblan en el shader en vez de quedarse fijos.
const MODO_TELEVISION := "fria_tv"

const _PRIMO_VENTANA := 73_856_093
const _PRIMO_PASO := 19_349_663

var _lote: MultiMeshInstance3D = null
var _animador: AnimadorAmbiental3D = null
var _indices: Dictionary = {}
var _nombres: Array[String] = []
## Copia en CPU de lo último escrito en el lote. Sirve para dos cosas: no
## reescribir el buffer cuando el estado no ha cambiado —que es lo normal entre
## dos ticks seguidos— y poder comprobar desde una regresión qué se escribió,
## porque un MultiMesh no devuelve sus datos sin servidor de render detrás.
var _datos := PackedColorArray()
var _posiciones := PackedVector3Array()


## Monta el lote animado sobre una calle que ya tiene fachadas vivas y da de
## alta cada ventana elegida en el animador. Devuelve cuántas se animan.
func adoptar(calle: Node3D, animador: AnimadorAmbiental3D) -> int:
	_animador = animador
	if calle == null:
		return 0
	var vivas := calle.get_node_or_null("FachadasVivas") as Node3D
	var pisos := calle.get_node_or_null("PisosFachada") as Node3D
	if vivas == null or pisos == null:
		return 0
	if vivas.get_node_or_null(NOMBRE_LOTE) != null:
		return 0
	var interiores := vivas.get_node_or_null("Interiores") as Node3D
	if interiores == null:
		return 0

	var elegidas := _elegir(interiores, pisos)
	if elegidas.is_empty():
		return 0
	_crear_lote(vivas, elegidas)
	_registrar(vivas, elegidas)
	return _nombres.size()


## Lo llama el animador. El estado de una ventana es una función del tiempo
## acumulado, no un contador propio: por eso despertar y ponerse al día es
## gratis y no hay un estado que se pueda corromper.
func animar_pieza(id: String, tiempo: float, _transcurrido: float, lod: String) -> void:
	if _lote == null or not _indices.has(id):
		return
	var indice := int(_indices[id])
	var instante := estado_en(indice, tiempo, lod != AnimacionAmbiental.LOD_CERCA)
	if indice < _datos.size() and _datos[indice].is_equal_approx(instante):
		return
	_datos[indice] = instante
	_lote.multimesh.set_instance_custom_data(indice, instante)


## Color y modo de una ventana en un instante dado, como datos de instancia:
## RGB es la luz de la habitación y alfa dice si esa luz tiembla.
##
## [param sin_fundido] lo usan los LOD lejanos: a cuarenta metros el cambio no
## se ve fundir, solo se ve que ha cambiado.
func estado_en(indice: int, tiempo: float, sin_fundido := false) -> Color:
	var avance := tiempo / CICLO + AnimacionAmbiental.desfase(_nombre_de(indice), indice)
	var paso := int(floor(avance))
	var actual := estado_de_paso(indice, paso)
	var anterior := estado_de_paso(indice, paso - 1)
	var mezcla := 1.0
	if not sin_fundido:
		mezcla = clampf((avance - float(paso)) * CICLO / FUNDIDO, 0.0, 1.0)
	var color: Color = COLORES[anterior]
	color = color.lerp(COLORES[actual], mezcla)
	var dominante := actual if mezcla >= 0.5 else anterior
	color.a = 1.0 if dominante == MODO_TELEVISION else 0.0
	return color


## Nombre de la ventana que ocupa una posición del lote. Para las regresiones.
func nombre_de(indice: int) -> String:
	return _nombre_de(indice)


## Último dato de instancia escrito para esa ventana: su luz y si tiembla.
func dato_de(indice: int) -> Color:
	if indice < 0 or indice >= _datos.size():
		return Color(0, 0, 0, 0)
	return _datos[indice]


## Dónde quedó el plano animado de esa ventana, en coordenadas de la calle.
func posicion_de(indice: int) -> Vector3:
	if indice < 0 or indice >= _posiciones.size():
		return Vector3.ZERO
	return _posiciones[indice]


func ventanas_animadas() -> int:
	return _nombres.size()


func lote() -> MultiMeshInstance3D:
	return _lote


func _nombre_de(indice: int) -> String:
	if indice < 0 or indice >= _nombres.size():
		return ""
	return _nombres[indice]


## Qué le pasa a una ventana en un paso concreto del ciclo. Mezcla entera y
## determinista: la misma ventana cuenta la misma noche en cualquier máquina.
## Es pública para que una regresión pueda leer el ciclo sin montar la calle.
func estado_de_paso(indice: int, paso: int) -> String:
	var mezclado := ((indice + 1) * _PRIMO_VENTANA) ^ (paso * _PRIMO_PASO)
	return String(SECUENCIA[posmod(mezclado, SECUENCIA.size())])


func _elegir(interiores: Node3D, pisos: Node3D) -> Array[Dictionary]:
	var elegidas: Array[Dictionary] = []
	var vistas := 0
	for hijo in interiores.get_children():
		var grupo := hijo as Node3D
		if grupo == null or not grupo.has_meta("ventana"):
			continue
		vistas += 1
		if vistas % PASO_SELECCION != 0 or elegidas.size() >= MAX_VENTANAS:
			continue
		var nombre := String(grupo.get_meta("ventana"))
		var ventana := pisos.get_node_or_null(nombre) as Node3D
		if ventana == null:
			continue
		var hacia_calle := float(grupo.get_meta("hacia_calle", 1.0))
		var fondo_x := float(grupo.get_meta("fondo_x", ventana.position.x))
		var sitio := Vector3(
			fondo_x + hacia_calle * SALIENTE, ventana.position.y, ventana.position.z
		)
		elegidas.append({"nombre": nombre, "posicion": sitio})
	return elegidas


func _crear_lote(vivas: Node3D, elegidas: Array[Dictionary]) -> void:
	var malla := BoxMesh.new()
	malla.size = TAMANO

	var repetidos := MultiMesh.new()
	repetidos.transform_format = MultiMesh.TRANSFORM_3D
	repetidos.use_custom_data = true
	repetidos.mesh = malla
	repetidos.instance_count = elegidas.size()

	_nombres.clear()
	_indices.clear()
	_datos.resize(elegidas.size())
	_posiciones.resize(elegidas.size())
	for indice in elegidas.size():
		var elegida := elegidas[indice]
		var sitio := elegida["posicion"] as Vector3
		_nombres.append(String(elegida["nombre"]))
		_posiciones[indice] = sitio
		repetidos.set_instance_transform(indice, Transform3D(Basis.IDENTITY, sitio))
		var arranque := estado_en(indice, 0.0, true)
		_datos[indice] = arranque
		repetidos.set_instance_custom_data(indice, arranque)

	var material := ShaderMaterial.new()
	material.shader = load(SHADER)

	_lote = MultiMeshInstance3D.new()
	_lote.name = NOMBRE_LOTE
	_lote.multimesh = repetidos
	_lote.material_override = material
	_lote.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lote.visibility_range_end = LOD_FIN
	_lote.set_meta("ventanas_animadas", elegidas.size())
	vivas.add_child(_lote)


func _registrar(vivas: Node3D, elegidas: Array[Dictionary]) -> void:
	if _animador == null:
		return
	for indice in elegidas.size():
		var nombre := String(elegidas[indice]["nombre"])
		var local := elegidas[indice]["posicion"] as Vector3
		var mundo := vivas.to_global(local) if vivas.is_inside_tree() else local
		_indices[nombre] = indice
		_animador.registrar(nombre, self, mundo)
