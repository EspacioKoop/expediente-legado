## Enrutado central de audio (#119).
##
## `Master` sigue siendo el volumen global. Todo reproductor que no declare un
## bus propio entra por `Efectos`, salvo los dos nodos canónicos ya separados
## por responsabilidad: ambiente continuo y música puntual.
##
## El mismo autoload monta el submixer de Opciones de forma diferida, cuando
## `MenuGlobal` ya ha construido su panel. Reutiliza el `Dictionary` de
## `PreferenciasSiga` que posee el menú: no existe un segundo fichero ni una
## copia de preferencias que pueda pisar cambios posteriores.
extends Node

const BUS_MASTER := &"Master"
const BUS_EFECTOS := &"Efectos"
const BUS_AMBIENTE := &"Ambiente"
const BUS_MUSICA := &"Musica"
const NODO_AMBIENTE := &"AmbienteContinuo"
const NODO_MUSICA := &"MusicaPuntual"
const RUTA_TEXTOS := "res://datos/mezcla_audio_textos.json"
const CONTROLES_MEZCLA := [
	{"clave": "volumen_efectos", "bus": BUS_EFECTOS, "texto": "efectos"},
	{"clave": "volumen_ambiente", "bus": BUS_AMBIENTE, "texto": "ambiente"},
	{"clave": "volumen_musica", "bus": BUS_MUSICA, "texto": "musica"},
]

var _preferencias: Dictionary = {}
var _textos: Dictionary = {}
var _mixer_montado := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_preferencias = PreferenciasSiga.cargar()
	_textos = _cargar_textos()
	aplicar_volumenes(_preferencias)
	get_tree().node_added.connect(_al_anadir_nodo)
	_enrutar_subarbol(get_tree().root)
	call_deferred("_montar_mixer_opciones")


func aplicar_volumenes(preferencias: Dictionary) -> void:
	_aplicar_bus(BUS_MASTER, float(preferencias.get("volumen", 1.0)))
	for control in CONTROLES_MEZCLA:
		_aplicar_bus(
			StringName(control["bus"]), float(preferencias.get(String(control["clave"]), 1.0))
		)


func _aplicar_bus(bus: StringName, valor: float) -> void:
	var indice := AudioServer.get_bus_index(bus)
	if indice < 0:
		return
	var nivel := clampf(valor, 0.0, 1.0)
	AudioServer.set_bus_volume_db(indice, linear_to_db(maxf(nivel, 0.0001)))
	AudioServer.set_bus_mute(indice, nivel <= 0.0)


func _cargar_textos() -> Dictionary:
	if not FileAccess.file_exists(RUTA_TEXTOS):
		return {}
	var datos = JSON.parse_string(FileAccess.get_file_as_string(RUTA_TEXTOS))
	return datos if datos is Dictionary else {}


func _texto(clave: String) -> String:
	return String(_textos.get(clave, clave))


func _montar_mixer_opciones() -> void:
	if _mixer_montado:
		return
	var menu := get_node_or_null("/root/MenuGlobal")
	if menu == null:
		return
	var panel := menu.get("_panel_opciones") as PanelContainer
	var volumen_master := menu.get("_volumen") as HSlider
	var preferencias_menu = menu.get("_preferencias")
	if panel == null or volumen_master == null or not preferencias_menu is Dictionary:
		return
	var caja := volumen_master.get_parent() as VBoxContainer
	if caja == null:
		return

	# Compartimos el mismo objeto que guarda MenuGlobal. Así mover cámara,
	# remapear o cambiar el Master después no reescribe los tres subniveles.
	_preferencias = preferencias_menu
	aplicar_volumenes(_preferencias)

	var bloque := VBoxContainer.new()
	bloque.name = "MixerAudio"
	bloque.add_theme_constant_override("separation", 8)
	caja.add_child(bloque)
	caja.move_child(bloque, volumen_master.get_index() + 1)

	var titulo := Label.new()
	titulo.text = _texto("seccion")
	bloque.add_child(titulo)
	for control in CONTROLES_MEZCLA:
		_agregar_control_mezcla(bloque, control)
	_mixer_montado = true


func _agregar_control_mezcla(caja: VBoxContainer, control: Dictionary) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	caja.add_child(fila)

	var etiqueta := Label.new()
	etiqueta.text = _texto(String(control["texto"]))
	etiqueta.custom_minimum_size.x = 210
	fila.add_child(etiqueta)

	var slider := HSlider.new()
	slider.name = "Volumen%s" % String(control["bus"])
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = float(_preferencias.get(String(control["clave"]), 1.0))
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(
		_al_cambiar_subvolumen.bind(String(control["clave"]), StringName(control["bus"]))
	)
	fila.add_child(slider)


func _al_cambiar_subvolumen(valor: float, clave: String, bus: StringName) -> void:
	_preferencias[clave] = clampf(valor, 0.0, 1.0)
	_aplicar_bus(bus, valor)
	PreferenciasSiga.guardar(_preferencias)


func _al_anadir_nodo(nodo: Node) -> void:
	_enrutar(nodo)


func _enrutar_subarbol(nodo: Node) -> void:
	_enrutar(nodo)
	for hijo in nodo.get_children():
		_enrutar_subarbol(hijo)


func _enrutar(nodo: Node) -> void:
	if not _es_reproductor(nodo):
		return
	if StringName(nodo.get("bus")) != BUS_MASTER:
		return

	var destino := BUS_EFECTOS
	if nodo.name == NODO_AMBIENTE:
		destino = BUS_AMBIENTE
	elif nodo.name == NODO_MUSICA:
		destino = BUS_MUSICA
	nodo.set("bus", destino)


func _es_reproductor(nodo: Node) -> bool:
	return nodo is AudioStreamPlayer or nodo is AudioStreamPlayer2D or nodo is AudioStreamPlayer3D
