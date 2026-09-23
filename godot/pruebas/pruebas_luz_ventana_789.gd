## La ventana del archivo, medida sobre el árbol real (#789).
##
## La jornada empieza a las nueve de la mañana y el cristal era un azul de noche
## fijo: el reloj de la pared decía una hora y la ventana otra, y por ella no
## entraba luz. Aquí se exige la cadena entera —el sitio monta el cristal y su
## foco, el foco nace apagado, y quien sabe la hora lo enciende de día y lo
## apaga de noche— y también lo contrario: las ventanas de la calle, que son
## fachada vista desde fuera, no ganan luces.
extends SceneTree

const Horario := preload("res://guion/dia_reloj_horario_app.gd")
const DiaCalle := preload("res://guion/dia_calle_app.gd")

## Lo mínimo del día que lee el controlador. Montar `dia.tscn` entero para esto
## sería probar veinte controladores a la vez y no saber cuál falla.
const DIA_MINIMO := """
extends Node
var _mundo: Node3D
var jornada := {}
var _espacio_actual := {}
var _ambiente: Environment
var _sol: DirectionalLight3D
"""

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _probar() -> void:
	var oficina := Node3D.new()
	root.add_child(oficina)
	Espacio3D.construir(oficina, EspaciosCatalogo.OFICINA.duplicate(true))
	# El trayecto REAL, no la constante del catálogo: es `dia_calle_app` quien
	# le añade las ventanas de las fachadas, y son justo esas las que no deben
	# ganar un foco.
	var dia_calle = DiaCalle.new()
	var trayecto: Dictionary = dia_calle.call("_espacio_de", "trayecto")
	dia_calle.free()
	var calle := Node3D.new()
	root.add_child(calle)
	Espacio3D.construir(calle, trayecto)
	await process_frame

	var focos := _focos(oficina)
	_comprobar(focos.size() == EspaciosCatalogo.OFICINA["ventanas"].size(), "un foco por ventana")
	_comprobar(_cristales(oficina).size() == focos.size(), "cada cristal se encuentra por nombre")
	_comprobar(not trayecto.get("ventanas", []).is_empty(), "el trayecto declara ventanas")
	_comprobar(_focos(calle).is_empty(), "las ventanas de fachada no ganan un foco")
	_comprobar(_cristales(calle).is_empty(), "ni el nombre que lee el controlador")
	for foco in focos:
		# El foco nace apagado: el módulo que construye no sabe qué hora es.
		_comprobar(not foco.visible and foco.light_energy == 0.0, "el foco nace apagado")
		_comprobar(foco.shadow_enabled, "la luz de ventana proyecta sombra")
		_comprobar(_mira_al_suelo_de_dentro(foco), "el foco cae dentro de la sala, no fuera")

	var dia := Node.new()
	var guion := GDScript.new()
	guion.source_code = DIA_MINIMO
	guion.reload()
	dia.set_script(guion)
	dia._mundo = oficina
	dia._espacio_actual = EspaciosCatalogo.OFICINA
	dia._ambiente = Environment.new()
	dia._sol = DirectionalLight3D.new()
	dia.jornada = {"fase": "archivo", "hora_minutos": Jornada.MINUTOS_INICIO_JORNADA}
	root.add_child(dia)
	var controlador: Node = Horario.new()
	dia.add_child(controlador)
	await process_frame
	await process_frame

	var manana := Horario.perfil_luz(Jornada.MINUTOS_INICIO_JORNADA)
	_comprobar(float(manana["ventana_energia"]) > 0.0, "a la hora de entrar entra luz")
	# Sin fundido al entrar: la ventana ya está como corresponde en el primer
	# fotograma, no amaneciendo cada vez que se cruza la puerta.
	for foco in focos:
		_comprobar(foco.visible, "de mañana el foco está encendido")
		_comprobar(
			is_equal_approx(foco.light_energy, float(manana["ventana_energia"])),
			"de mañana alumbra con la energía del perfil"
		)
	for material in _cristales(oficina):
		var cristal: Color = material.get_shader_parameter("emision")
		_comprobar(
			cristal.is_equal_approx(manana["cristal"]),
			"de mañana el cristal es de día, no azul noche"
		)
		_comprobar(cristal.get_luminance() > 0.5, "el cristal de día es claro")

	dia.jornada["hora_minutos"] = 20 * 60
	await process_frame
	# La transición es suave a propósito; aquí se pide que converja.
	controlador._transicionar_luz(dia, 10.0)
	var noche := Horario.perfil_luz(20 * 60)
	_comprobar(float(noche["ventana_energia"]) == 0.0, "de noche no se inventa sol")
	for foco in focos:
		_comprobar(not foco.visible, "de noche el foco se apaga y no paga su sombra")
	for material in _cristales(oficina):
		var cristal: Color = material.get_shader_parameter("emision")
		_comprobar(
			cristal.is_equal_approx(EspaciosCatalogo.OFICINA["ventanas"][0]["color"]),
			"de noche el cristal vuelve al azul que declara el catálogo"
		)

	dia.queue_free()
	oficina.queue_free()
	calle.queue_free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _focos(sitio: Node) -> Array:
	return sitio.find_children(Espacio3D.NOMBRE_LUZ_VENTANA + "*", "SpotLight3D", true, false)


func _cristales(sitio: Node) -> Array:
	var materiales := []
	for cristal in sitio.find_children(Espacio3D.NOMBRE_CRISTAL_VENTANA + "*", "", true, false):
		for hijo in cristal.get_children():
			if hijo is MeshInstance3D:
				materiales.append(hijo.material_override)
	return materiales


## Donde el eje del foco corta el suelo tiene que estar dentro del rectángulo
## de la sala: un foco mirando al muro alumbraría la pared desde dentro.
func _mira_al_suelo_de_dentro(foco: SpotLight3D) -> bool:
	var origen := foco.global_position
	var eje := -foco.global_basis.z
	if eje.y >= 0.0:
		return false
	var punto := origen + eje * (origen.y / -eje.y)
	var medidas: Vector2 = EspaciosCatalogo.OFICINA["suelo"]
	return absf(punto.x) < medidas.x / 2.0 and absf(punto.z) < medidas.y / 2.0 - 1.0


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO luz de ventana #789: " + nombre)
