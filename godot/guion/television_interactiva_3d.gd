## Capa de interacción para el televisor real ya declarado en la casa (#283).
##
## No crea otro televisor: CasaUtileria coloca este Area3D en el bulto
## `televisionVintage` del catálogo y conserva ese modelo como representación.
## El encendido es feedback local. Desde #442, una atención deliberada y
## completada al microdocumental ficticio de #441 puede registrar la semilla
## Duat del día; encender la TV o usar el mando como ruido de fondo no basta.
class_name TelevisionInteractiva3D
extends Interactuable3D

var _encendida := false
var _brillo: OmniLight3D
var _paso_documental := 0
var _documental_completado := false


func configurar(tam: Vector3) -> void:
	verbo = Verbo.ENCENDER
	nombre_objeto = "televisor"

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam + Vector3(0.12, 0.12, 0.12)
	colision.shape = forma
	add_child(colision)

	_brillo = OmniLight3D.new()
	_brillo.name = "BrilloTelevisor"
	_brillo.position = Vector3(0.0, tam.y * 0.08, -tam.z * 0.42)
	_brillo.omni_range = 2.6
	_brillo.light_energy = 0.75
	_brillo.light_color = Color(0.58, 0.70, 0.82)
	_brillo.visible = false
	add_child(_brillo)

	activado.connect(_interactuar_directo)
	_montar_mando_domestico()


func esta_encendida() -> bool:
	return _encendida


func texto_accion() -> String:
	if not _encendida:
		return super.texto_accion()
	if _documental_completado:
		return "Apagar televisor"
	if _paso_documental == 0:
		return "Buscar canal"
	return "Seguir viendo documental"


## Punto público mínimo para accesorios domésticos como el mando IR.
## El mando conserva una única fuente de verdad para el estado visual, pero no
## avanza contenido: dejar la TV encendida de fondo no activa semillas.
func alternar_desde_mando() -> void:
	_alternar()


## La interacción directa exige tres pasos observables: encender, elegir el
## fragmento y terminarlo. Solo el último consulta la jornada real y registra la
## semilla; salir o apagar antes reinicia el progreso incompleto.
func _interactuar_directo(_actor: Node) -> void:
	if not _encendida:
		_alternar()
		return
	if _documental_completado:
		_alternar()
		return
	if _paso_documental == 0:
		_paso_documental = 1
		return

	var jornada_actual := _jornada_en_escena()
	if jornada_actual.is_empty():
		return
	_documental_completado = SuenoDuat.registrar_documental(jornada_actual, true)


func _alternar() -> void:
	_encendida = not _encendida
	_brillo.visible = _encendida
	if not _encendida and not _documental_completado:
		_paso_documental = 0


## `TelevisionInteractiva3D` vive bajo `_mundo`, que se recrea al entrar en casa.
## Buscar la propiedad `jornada` en ancestros evita meter Partida/Jornada en la
## utilería y mantiene el montaje de CasaUtileria ajeno a persistencia.
func _jornada_en_escena() -> Dictionary:
	var nodo: Node = self
	while nodo != null:
		for propiedad in nodo.get_property_list():
			if String(propiedad.get("name", "")) != "jornada":
				continue
			var valor: Variant = nodo.get("jornada")
			if typeof(valor) == TYPE_DICTIONARY:
				return valor
			return {}
		nodo = nodo.get_parent()
	return {}


func _montar_mando_domestico() -> void:
	var contenedor := get_parent()
	if contenedor == null:
		return
	var mando := MandoTelevision98.new()
	mando.name = "MandoTelevision98"
	# Queda sobre la mesita del rincón de ocio, junto a la portátil pero sin
	# solaparla. La posición parte del televisor para viajar con el conjunto.
	mando.position = position + Vector3(1.25, 0.23, -1.18)
	mando.rotation_degrees = Vector3(0.0, 14.0, 0.0)
	contenedor.add_child(mando)
	mando.configurar(self)
