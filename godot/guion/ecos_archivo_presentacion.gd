## Adaptador de presentación para Ecos del archivo (#161).
##
## Este módulo convierte la lógica pura de EcosArchivo en un contrato consumible
## por una futura sala/UI sin conocer teclado, mando ni nodos concretos. La escena
## solo traduce acciones semánticas a mover/seleccionar/deshacer/abandonar y pinta
## la vista devuelta aquí. Así la navegación por foco y la salida segura se pueden
## probar antes de tocar escenas compartidas del sueño.
class_name EcosArchivoPresentacion
extends RefCounted

const Ecos := preload("res://guion/ecos_archivo.gd")
const Puzzle := preload("res://guion/puzzle_onirico.gd")
const _RUTA_SCRIPT := "res://guion/ecos_archivo_presentacion.gd"

const EVENTO_NINGUNO := "ninguno"
const EVENTO_SELECCIONADO := "seleccionado"
const EVENTO_DESHECHO := "deshecho"
const EVENTO_DUPLICADO := "duplicado"
const EVENTO_LISTO := "listo"
const EVENTO_INCOMPLETO := "incompleto"
const EVENTO_INCORRECTO := "incorrecto"
const EVENTO_COMPLETADO := "completado"
const EVENTO_DISPERSADO := "dispersado"
const EVENTO_ABANDONADO := "abandonado"
const EVENTO_CERRADO := "cerrado"

const MANIFESTACION_REPETICION := "repeticion"
const MANIFESTACION_PALABRA_AUSENTE := "palabra_ausente"
const MANIFESTACION_ROTULO_DESHECHO := "rotulo_deshecho"
const MANIFESTACION_ECO_LEJANO := "eco_lejano"

var ecos
var tipo_documento := ""
var foco := 0
var seleccion: Array = []
var ultimo_evento := EVENTO_NINGUNO
var cerrada := false


static func crear(ecos_instancia, tipo_documental: String = ""):
	if ecos_instancia == null or ecos_instancia.nucleo == null:
		return null
	var presentacion = _nueva_instancia()
	if presentacion == null:
		return null
	presentacion.ecos = ecos_instancia
	presentacion.tipo_documento = tipo_documental.strip_edges().to_upper()
	presentacion.seleccion = ecos_instancia.seleccion
	presentacion.cerrada = not ecos_instancia.nucleo.pendiente()
	return presentacion


## La escena concreta decide qué entrada física significa izquierda/derecha.
## Aquí solo existe dirección semántica, igual que en EcosArchivo.mover_foco().
func mover(direccion: int) -> int:
	if ecos == null:
		return foco
	foco = ecos.mover_foco(foco, direccion)
	return foco


## Selecciona el eco que ocupa el foco visual actual. El jugador construye la
## secuencia por ids canónicos, nunca comparando texto ni creando información.
func seleccionar() -> String:
	if _terminal():
		return EVENTO_CERRADO
	var presentados: Array = ecos.ecos_presentados()
	if foco < 0 or foco >= presentados.size():
		return EVENTO_CERRADO
	var eco: Dictionary = presentados[foco]
	var id := int(eco.get("id", -1))
	if seleccion.has(id):
		if not seleccion.is_empty() and seleccion.back() == id:
			seleccion.pop_back()
			ultimo_evento = EVENTO_DESHECHO
		else:
			ultimo_evento = EVENTO_DUPLICADO
		return ultimo_evento
	seleccion.append(id)
	ultimo_evento = (
		EVENTO_LISTO if seleccion.size() == Ecos.CANTIDAD_FRAGMENTOS else EVENTO_SELECCIONADO
	)
	return ultimo_evento


## Evaluar la secuencia es un gesto separado de construirla. Hasta confirmar,
## el jugador puede deshacer sin consumir la única respuesta del puzzle.
func confirmar() -> String:
	if _terminal():
		return EVENTO_CERRADO
	if seleccion.size() != Ecos.CANTIDAD_FRAGMENTOS:
		ultimo_evento = EVENTO_INCOMPLETO
		return ultimo_evento

	var resultado: String = str(ecos.probar(seleccion))
	ultimo_evento = resultado
	if resultado == EVENTO_COMPLETADO or resultado == EVENTO_DISPERSADO:
		cerrada = true
	return ultimo_evento


## Permite corregir una elección sin gastar intento. Es una operación semántica
## separada para que una UI pueda mapearla a cancelar/volver según preferencias.
func deshacer() -> bool:
	if _terminal() or seleccion.is_empty():
		return false
	seleccion.pop_back()
	ultimo_evento = EVENTO_DESHECHO
	return true


## Abandonar nunca bloquea la salida del sueño. No se modela aquí una tecla ni
## una puerta: la sala recibe true y recupera el control del jugador.
func abandonar() -> bool:
	if ecos == null:
		return false
	var estaba_pendiente: bool = bool(ecos.nucleo.pendiente())
	var seguro: bool = bool(ecos.salir())
	if not seguro:
		return false
	cerrada = true
	if estaba_pendiente:
		ultimo_evento = EVENTO_ABANDONADO
	return true


## View-model determinista para una capa Control o para elementos 3D con foco.
## `texto` procede únicamente de EcosArchivo, que ya valida leido_hoy.
func vista(reduccion_movimiento: bool) -> Dictionary:
	if ecos == null:
		return {}
	var elementos := []
	var presentados: Array = ecos.ecos_presentados()
	for indice in range(presentados.size()):
		var eco: Dictionary = presentados[indice]
		var id := int(eco.get("id", -1))
		var texto := str(eco.get("texto", ""))
		var elemento := {
			"slot": indice,
			"id": id,
			"texto": texto,
			"texto_visible": _deformar_texto(texto, id),
			"foco": indice == foco,
			"seleccionado": seleccion.has(id),
			"posicion_seleccion": seleccion.find(id),
		}
		elementos.append(elemento)
	return {
		"regla":
		"Recompón los tres ecos. Corrige el orden; confirmar hace definitiva la respuesta.",
		"elementos": elementos,
		"foco": foco,
		"seleccion": seleccion.duplicate(),
		"intentos": ecos.intentos,
		"max_intentos": Ecos.MAX_INTENTOS,
		"estado": _estado_visual(),
		"ultimo_evento": ultimo_evento,
		"confirmacion_disponible": seleccion.size() == Ecos.CANTIDAD_FRAGMENTOS and not _terminal(),
		"salida_disponible": true,
		"manifestacion": manifestacion_para_tipo(tipo_documento),
		"movimiento": ecos.politica_presentacion(reduccion_movimiento),
	}


## El tipo del documento ya está en el expediente leído. Aquí solo decide cómo
## se deforma visualmente el recuerdo: nunca cambia ids, solución ni recompensa.
static func manifestacion_para_tipo(tipo_documental: String) -> String:
	var normalizado := tipo_documental.strip_edges().to_upper()
	match normalizado:
		"FACTURA", "FAX", "TELEGRAMA", "RECIBO":
			return MANIFESTACION_REPETICION
		"EMPLEADO", "FICHA", "EXPEDIENTE":
			return MANIFESTACION_PALABRA_AUSENTE
		"ACTA", "RESOLUCION", "DICTAMEN":
			return MANIFESTACION_ROTULO_DESHECHO
		"MEMORANDO", "OFICIO", "CIRCULAR", "CARTA":
			return MANIFESTACION_ECO_LEJANO
		_:
			return MANIFESTACION_ECO_LEJANO


## La variante «palabra ausente» oculta una sola palabra del fragmento central.
## El texto canónico permanece en `texto`; la capa 3D consume `texto_visible`.
func _deformar_texto(texto: String, id: int) -> String:
	if manifestacion_para_tipo(tipo_documento) != MANIFESTACION_PALABRA_AUSENTE or id != 1:
		return texto
	var palabras := texto.split(" ", false)
	if palabras.size() < 2:
		return texto
	palabras[int(palabras.size() / 2)] = "····"
	return " ".join(palabras)


func _estado_visual() -> String:
	if ecos == null or ecos.nucleo == null:
		return EVENTO_CERRADO
	match ecos.nucleo.state:
		Puzzle.ESTADO_COMPLETADO:
			return EVENTO_COMPLETADO
		Puzzle.ESTADO_FALLADO:
			return EVENTO_DISPERSADO
		Puzzle.ESTADO_ABANDONADO:
			return EVENTO_ABANDONADO
		_:
			return "activo"


func _terminal() -> bool:
	return ecos == null or ecos.nucleo == null or cerrada or not ecos.nucleo.pendiente()


static func _nueva_instancia():
	var script := load(_RUTA_SCRIPT)
	if script == null:
		return null
	return script.new()
