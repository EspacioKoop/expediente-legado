## Contrato mínimo para objetos interactivos del mundo 3D (#283).
##
## Cada objeto declara un verbo y un texto contextual. La regla concreta vive
## fuera de este componente: al activarse emite una señal y deja a la escena o
## sistema dueño decidir qué cambia.
class_name Interactuable3D
extends Area3D

signal activado(actor: Node)

enum Verbo {
	EXAMINAR,
	USAR,
	ABRIR,
	CERRAR,
	COGER,
	LEER,
	DAR,
	ENCENDER,
	GOLPEAR,
	ACARICIAR,
	LLAMAR,
}

const NOMBRES_VERBO := {
	Verbo.EXAMINAR: "Examinar",
	Verbo.USAR: "Usar",
	Verbo.ABRIR: "Abrir",
	Verbo.CERRAR: "Cerrar",
	Verbo.COGER: "Coger",
	Verbo.LEER: "Leer",
	Verbo.DAR: "Dar",
	Verbo.ENCENDER: "Encender",
	Verbo.GOLPEAR: "Golpear",
	Verbo.ACARICIAR: "Acariciar",
	Verbo.LLAMAR: "Llamar",
}

## Solo los gestos físicos suenan por defecto. `EXAMINAR` es mirar, `USAR` cubre
## desde una consola hasta una compuerta onírica y `GOLPEAR` ya lo sonoriza su
## dueño: darles un ruido genérico sería mentir sobre lo que pasa.
const SONIDO_POR_VERBO := {
	Verbo.ABRIR: "abrir",
	Verbo.CERRAR: "cerrar",
	Verbo.COGER: "coger",
	Verbo.DAR: "coger",
	Verbo.LEER: "documento",
	Verbo.ENCENDER: "marcar",
	Verbo.ACARICIAR: "coger",
}
## Valor de [member sonido] que calla el objeto aunque su verbo suene.
const SIN_SONIDO := "-"

@export var verbo := Verbo.USAR
@export var nombre_objeto := ""
@export var habilitado := true
## Nombre del catálogo de `Sonido`. Vacío usa el del verbo.
@export var sonido := ""


func texto_accion() -> String:
	var accion := _nombre_verbo(verbo)
	if nombre_objeto.strip_edges().is_empty():
		return accion
	return "%s %s" % [accion, nombre_objeto]


func interactuar(actor: Node) -> bool:
	if not habilitado:
		return false
	# El sonido pertenece al gesto que el jugador acaba de pedir, no al estado
	# resultante. Varios interactuables cambian verbo dentro de `activado`
	# (ABRIR -> CERRAR y viceversa); resolverlo antes evita invertir ambos ruidos.
	var sonido_actual := nombre_sonido()
	Sonido.sonar_en(self, sonido_actual)
	activado.emit(actor)
	return true


func nombre_sonido() -> String:
	if sonido == SIN_SONIDO:
		return ""
	if not sonido.is_empty():
		return sonido
	return String(SONIDO_POR_VERBO.get(verbo, ""))


func _nombre_verbo(valor: int) -> String:
	return String(NOMBRES_VERBO.get(valor, "Usar"))
