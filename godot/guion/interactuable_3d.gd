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
}

@export var verbo := Verbo.USAR
@export var nombre_objeto := ""
@export var habilitado := true


func texto_accion() -> String:
	var accion := _nombre_verbo(verbo)
	if nombre_objeto.strip_edges().is_empty():
		return accion
	return "%s %s" % [accion, nombre_objeto]


func interactuar(actor: Node) -> bool:
	if not habilitado:
		return false
	activado.emit(actor)
	return true


func _nombre_verbo(valor: int) -> String:
	return String(NOMBRES_VERBO.get(valor, "Usar"))
