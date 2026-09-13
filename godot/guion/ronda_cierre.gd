## Contrato puro de la ronda de cierre opcional (#156).
##
## No mueve al jugador ni anima objetos. Solo deriva una ruta determinista a
## partir del día y conserva un progreso idempotente preparado para persistirse
## después. No concede recompensas ni altera el progreso global.
class_name RondaCierre
extends RefCounted

const INCOMPLETA := "incompleta"
const CORRECTA := "correcta"
const IMPECABLE := "impecable"
const ABANDONADA := "abandonada"

const PUNTOS_BASE := [
	"recoger_a7",
	"apagar_lampara",
	"cerrar_puerta",
	"revisar_bandeja",
	"devolver_carpeta",
	"comprobar_tablon",
]
const PUNTO_CUNADO := "despedir_cunado"


static func nueva(dia: int, raiz: int = 0, cunado_presente: bool = true) -> Dictionary:
	var ruta := ruta_para(dia, raiz, cunado_presente)
	return {
		"dia": maxi(dia, 1),
		"ruta": ruta,
		"completados": [],
		"abandonada": false,
		"finalizada": false,
		"rango": INCOMPLETA,
	}


static func ruta_para(dia: int, raiz: int = 0, cunado_presente: bool = true) -> Array:
	var disponibles := PUNTOS_BASE.duplicate()
	if cunado_presente:
		disponibles.append(PUNTO_CUNADO)

	# 3–5 puntos. La aritmética es deliberadamente simple y estable: la misma
	# pareja semilla/día produce siempre la misma ruta sin depender de RNG global.
	var cantidad := 3 + posmod(dia + raiz, 3)
	cantidad = mini(cantidad, disponibles.size())
	var cursor := posmod(dia * 31 + raiz * 17, disponibles.size())
	var salto := 1 + posmod(dia * 7 + raiz * 5, maxi(disponibles.size() - 1, 1))
	var ruta: Array = []
	while ruta.size() < cantidad:
		var punto: String = disponibles[cursor]
		if not ruta.has(punto):
			ruta.append(punto)
		cursor = posmod(cursor + salto, disponibles.size())
		# Si el salto comparte divisor con el tamaño del catálogo, el avance
		# lineal evita quedar atrapados sin introducir azar no determinista.
		if ruta.size() < cantidad and ruta.has(disponibles[cursor]):
			cursor = posmod(cursor + 1, disponibles.size())
	return ruta


static func completar_punto(estado: Dictionary, punto: String) -> bool:
	if estado.get("abandonada", false) or estado.get("finalizada", false):
		return false
	var ruta: Array = estado.get("ruta", [])
	if not ruta.has(punto):
		return false
	var completados: Array = estado.get("completados", [])
	if completados.has(punto):
		return true
	completados.append(punto)
	estado["completados"] = completados
	return true


static func abandonar(estado: Dictionary) -> void:
	if estado.get("finalizada", false):
		return
	estado["abandonada"] = true
	estado["rango"] = ABANDONADA


static func finalizar(estado: Dictionary) -> String:
	if estado.get("abandonada", false):
		estado["rango"] = ABANDONADA
		return ABANDONADA
	var ruta: Array = estado.get("ruta", [])
	var completados: Array = estado.get("completados", [])
	var hechos := 0
	for punto in ruta:
		if completados.has(punto):
			hechos += 1
	var rango := INCOMPLETA
	if hechos == ruta.size() and not ruta.is_empty():
		rango = IMPECABLE
	elif hechos >= maxi(1, ruta.size() - 1):
		rango = CORRECTA
	estado["finalizada"] = true
	estado["rango"] = rango
	return rango


static func progreso(estado: Dictionary) -> Dictionary:
	var ruta: Array = estado.get("ruta", [])
	var completados: Array = estado.get("completados", [])
	var hechos := 0
	for punto in ruta:
		if completados.has(punto):
			hechos += 1
	return {
		"hechos": hechos,
		"total": ruta.size(),
		"completa": hechos == ruta.size() and not ruta.is_empty(),
		"rango": estado.get("rango", INCOMPLETA),
	}
