## Orden de los espacios jugables del RPG ficticio Crónicas (#2589).
##
## Es un contrato local de navegación, NO un guardado ni una fuente de verdad
## para SIGA, sueños, semilla, combate o el clímax. El anfitrión debe llamar a
## registrar_salida() únicamente tras recibir la señal de salida de la sala.
## Las escenas aún no integradas se señalan como contenido pendiente: nunca se
## saltan ni se dan por jugadas al abrir una ventana de OS98.
class_name CronicasCapituloRutas
extends RefCounted

const CAPITULO := "el_hijo_del_nigromante"
const ESTADO_JUGABLE := "jugable"
const ESTADO_PENDIENTE := "pendiente_contenido"
const ESTADO_TERMINADO := "terminado"
const ESTADO_INVALIDO := "invalido"

const ETAPAS := [
	{"id": "bastion", "escena": "res://escenas/cronicas/bastion_nombres_ausentes.tscn", "acto": 1},
	{"id": "patio_juramentos", "escena": "res://escenas/cronicas/patio_juramentos.tscn", "acto": 1},
	{
		"id": "scriptorium_versiones",
		"escena": "res://escenas/cronicas/scriptorium_versiones.tscn",
		"acto": 1
	},
	{"id": "torre_tiempo", "escena": "res://escenas/cronicas/torre_tiempo.tscn", "acto": 2},
	{
		"id": "galeria_identidades",
		"escena": "res://escenas/cronicas/galeria_identidades.tscn",
		"acto": 2
	},
	{"id": "puente_ausencia", "escena": "res://escenas/cronicas/puente_ausencia.tscn", "acto": 2},
	{"id": "estuario_maestro", "escena": "res://escenas/cronicas/estuario_maestro.tscn", "acto": 3},
	{"id": "umbral_heredera", "escena": "res://escenas/cronicas/umbral_heredera.tscn", "acto": 3},
	{"id": "archivo_cronista", "escena": "res://escenas/cronicas/archivo_cronista.tscn", "acto": 3},
	{"id": "camara_guardian", "escena": "res://escenas/cronicas/camara_guardian.tscn", "acto": 3},
]


static func catalogo() -> Array:
	return ETAPAS.duplicate(true)


## Solo memoria local de sesión; el host canónico es dueño de cualquier
## procedencia de partida. Copiar este diccionario NO acredita haber jugado.
static func nueva_sesion() -> Dictionary:
	return {"capitulo": CAPITULO, "completadas": []}


static func _sesion_valida(sesion: Dictionary) -> bool:
	if String(sesion.get("capitulo", "")) != CAPITULO:
		return false
	var completadas: Variant = sesion.get("completadas", null)
	if not completadas is Array:
		return false
	var lista: Array = completadas
	if lista.size() > ETAPAS.size():
		return false
	for indice in range(lista.size()):
		if typeof(lista[indice]) != TYPE_STRING:
			return false
		if String(lista[indice]) != String(ETAPAS[indice]["id"]):
			return false
	return true


## Devuelve un contrato que el futuro anfitrión puede consumir sin adivinar
## el progreso. Una escena todavía inexistente bloquea SOLO este episodio.
static func etapa_actual(sesion: Dictionary) -> Dictionary:
	if not _sesion_valida(sesion):
		return {"estado": ESTADO_INVALIDO}
	var indice := (sesion["completadas"] as Array).size()
	if indice == ETAPAS.size():
		return {"estado": ESTADO_TERMINADO, "capitulo": CAPITULO}
	var etapa: Dictionary = ETAPAS[indice].duplicate(true)
	etapa["indice"] = indice
	etapa["estado"] = (
		ESTADO_JUGABLE
		if ResourceLoader.exists(String(etapa["escena"]), "PackedScene")
		else ESTADO_PENDIENTE
	)
	return etapa


## Requiere tanto la etapa esperada y existente como una señal de salida REAL
## suministrada por su propia escena. No confundir con abrir o visitar OS98.
## Una segunda notificación queda ignorada; no reescribe la sesión original.
static func registrar_salida(
	sesion: Dictionary, etapa_id: String, salida_confirmada: bool
) -> Dictionary:
	var copia := sesion.duplicate(true)
	var actual := etapa_actual(sesion)
	var respuesta := {
		"registrado": false,
		"sesion": copia,
		"siguiente": actual,
	}
	if not salida_confirmada or String(actual.get("estado", "")) != ESTADO_JUGABLE:
		return respuesta
	if etapa_id != String(actual.get("id", "")):
		return respuesta
	(copia["completadas"] as Array).append(etapa_id)
	respuesta["registrado"] = true
	respuesta["siguiente"] = etapa_actual(copia)
	return respuesta
