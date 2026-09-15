## Contrato común de aplicaciones alojadas por el escritorio corporativo (#535).
##
## Esta clase no contiene lógica de campaña ni conoce escenas concretas. Empaqueta
## identidad, fábrica, capacidades de ventana y estado local opcional, y traduce
## el ciclo de vida público de una aplicación a la API estable de EscritorioSiga.
## Así Explorador/Navegador/Correo pueden añadirse sin modificar el gestor.
class_name EscritorioSigaApp
extends RefCounted

var id: String
var titulo: String
var creador: Callable
var identidad_visual: String

var tamano_minimo := Vector2(300, 220)
var tamano_preferido := Vector2(760, 540)
var redimensionable := false
var multiples_instancias := false
var persistir_estado := false

var _estado_local: Dictionary = {}


func _init(
	id_app: String, titulo_app: String, creador_app: Callable, identidad_visual_app: String = ""
) -> void:
	id = id_app
	titulo = titulo_app
	creador = creador_app
	identidad_visual = identidad_visual_app


func es_valida() -> bool:
	return not id.is_empty() and not titulo.is_empty() and creador.is_valid()


## Registra la aplicación en el shell sin exponerle su escena ni su dominio.
func registrar_en(escritorio: EscritorioSiga) -> bool:
	if escritorio == null or not es_valida():
		return false
	escritorio.registrar_aplicacion(id, titulo, creador)
	_aplicar_identidad_visual(escritorio)
	return true


## Adopta contenido ya creado, necesario para migrar SIGA sin duplicar el visor.
func adoptar_en(escritorio: EscritorioSiga, contenido: Control) -> bool:
	if escritorio == null or contenido == null or not es_valida():
		return false
	escritorio.adoptar_aplicacion(id, titulo, contenido, creador)
	_aplicar_identidad_visual(escritorio)
	return true


## Operaciones de ciclo de vida comunes. Las aplicaciones no necesitan conocer
## nodos internos del shell ni manipular directamente su árbol de ventanas.
func abrir(escritorio: EscritorioSiga) -> void:
	if escritorio != null:
		escritorio.abrir_aplicacion(id)


func cerrar(escritorio: EscritorioSiga) -> void:
	if escritorio != null:
		escritorio.cerrar(id)


func activar(escritorio: EscritorioSiga) -> void:
	if escritorio != null:
		escritorio.enfocar(id)


func suspender(escritorio: EscritorioSiga) -> void:
	if escritorio != null:
		escritorio.minimizar(id)


func restaurar(escritorio: EscritorioSiga) -> void:
	if escritorio != null:
		escritorio.restaurar(id)


## Estado estrictamente local de aplicación. La campaña sigue perteneciendo a
## Dia/EstadoJuego; por defecto ni siquiera se declara persistible.
func establecer_estado_local(clave: String, valor: Variant) -> void:
	if clave.is_empty():
		return
	_estado_local[clave] = valor


func obtener_estado_local(clave: String, predeterminado: Variant = null) -> Variant:
	return _estado_local.get(clave, predeterminado)


func exportar_estado() -> Dictionary:
	if not persistir_estado:
		return {}
	return _estado_local.duplicate(true)


func importar_estado(estado: Dictionary) -> void:
	if not persistir_estado:
		return
	_estado_local = estado.duplicate(true)


func describir_capacidades() -> Dictionary:
	return {
		"id": id,
		"titulo": titulo,
		"identidad_visual": identidad_visual,
		"tamano_minimo": tamano_minimo,
		"tamano_preferido": tamano_preferido,
		"redimensionable": redimensionable,
		"multiples_instancias": multiples_instancias,
		"persistir_estado": persistir_estado,
	}


func _aplicar_identidad_visual(escritorio: EscritorioSiga) -> void:
	if identidad_visual.is_empty():
		return
	if escritorio.has_method("registrar_identidad_visual"):
		escritorio.call("registrar_identidad_visual", id, identidad_visual)
