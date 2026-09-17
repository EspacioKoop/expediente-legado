## Capa de #224 sobre el día: activa el cielo CC0 adaptado de Godot Skies.
##
## El ciclo, el sueño y la geometría siguen en las capas anteriores. Aquí solo
## cambia la fuente del fondo del Environment para que exteriores y huecos al
## cielo puedan compartir un recurso visual único y barato.
extends "res://guion/dia_sueno_app.gd"

const CIELO_SIGA := preload("res://arte/cielo_siga.tres")


func _montar_entorno() -> void:
	super._montar_entorno()

	var cielo := Sky.new()
	cielo.process_mode = Sky.PROCESS_MODE_QUALITY
	cielo.radiance_size = Sky.RADIANCE_SIZE_64
	cielo.sky_material = CIELO_SIGA.duplicate()

	_ambiente.background_mode = Environment.BG_SKY
	_ambiente.sky = cielo


## Cada cambio de espacio parte del mismo preset. Así un cielo onírico no se
## filtra a la calle/casa y el controller climático puede volver a modular el
## material normal del trayecto después de esta restauración.
func _entrar_en(fase: String) -> void:
	super._entrar_en(fase)
	_restaurar_cielo_siga()
	if fase != "sueño":
		return
	_aplicar_cielo_sueno()


func _restaurar_cielo_siga() -> void:
	if _ambiente == null or _ambiente.sky == null:
		return
	_ambiente.sky.sky_material = CIELO_SIGA.duplicate()


func _aplicar_cielo_sueno() -> void:
	var material := _material_cielo_siga()
	if material == null:
		return

	var seleccion := (
		SemillasOniricas
		. seleccionar_para_noche(
			jornada,
			_raiz(),
			MitologiasNoche.MAX_FAMILIAS_NOCHE,
		)
	)
	var familias: Array = seleccion.get("familias", [])
	var opciones: Dictionary = _opciones_sueno()
	var cantidad := clampi(
		int(opciones.get("cantidad", Sueno.ESCENAS_POR_NOCHE)),
		1,
		SuenoFormas.ids().size(),
	)
	var pendientes: Array = jornada.get("sueno_escenas", [])
	var familia := (
		SuenoCielos
		. familia_para_escena(
			familias,
			cantidad,
			pendientes.size(),
		)
	)
	var perfil := SuenoCielos.componer(familia, _modificadores_cielo_sueno())
	SuenoCielos.aplicar(material, perfil)


## Punto de extensión común para #935/#923/Tarot. La capa de cielo NO infiere
## religión, convicción o ideología desde objetos consumidos: cada sistema debe
## resolver primero sus propias experiencias/tags y entregar modificadores
## explícitos al compositor.
func _modificadores_cielo_sueno() -> Array:
	return []


func _material_cielo_siga() -> ShaderMaterial:
	if _ambiente == null or _ambiente.sky == null:
		return null
	return _ambiente.sky.sky_material as ShaderMaterial
