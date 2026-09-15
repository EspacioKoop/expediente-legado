## Preferencias de controles y presentación de SIGA-98 (#113).
##
## Esta capa no conoce ninguna pantalla: mantiene acciones semánticas, convierte
## sus descriptores en eventos de Godot y guarda solo preferencias, nunca partida.
class_name PreferenciasSiga
extends RefCounted

const VERSION := 1
const RUTA := "user://preferencias-siga.json"
const ACCIONES := {
	"mover_adelante": {"teclado": 87, "mando": 12},
	"mover_atras": {"teclado": 83, "mando": 13},
	"mover_izquierda": {"teclado": 65, "mando": 14},
	"mover_derecha": {"teclado": 68, "mando": 15},
	"saltar": {"teclado": KEY_SPACE, "mando": 2},
	"correr": {"teclado": KEY_SHIFT, "mando": 9},
	"agacharse": {"teclado": KEY_CTRL, "mando": 7},
	"interactuar": {"teclado": 69, "mando": 0},
	"cancelar": {"teclado": KEY_ESCAPE, "mando": 1},
}

const SENSIBILIDAD_CAMARA_MIN := 0.25
const SENSIBILIDAD_CAMARA_MAX := 3.0

## Límites del escalado de la interfaz del escritorio OS-98 (#534).
const ESCALA_UI_MIN := 0.8
const ESCALA_UI_MAX := 1.5


static func nuevas() -> Dictionary:
	return {
		"version": VERSION,
		"acciones": ACCIONES.duplicate(true),
		"reduccion_movimiento": false,
		"escala_ui": 1.0,
		"volumen": 1.0,
		"sensibilidad_camara_raton": 1.0,
		"sensibilidad_camara_mando": 1.0,
		"invertir_camara_y": false,
		"posicion_asistente_gato": null,
	}


## Devuelve el nombre de la acción que ya usa el evento, si existe.
static func conflicto(
	preferencias: Dictionary, tipo: String, codigo: int, salvo: String = ""
) -> String:
	for accion in preferencias.get("acciones", {}):
		if accion == salvo:
			continue
		var evento: Dictionary = preferencias["acciones"][accion]
		if evento.get(tipo, -1) == codigo:
			return accion
	return ""


## Cambia una sola asignación y rechaza colisiones para no dejar controles ambiguos.
static func remapear(
	preferencias: Dictionary, accion: String, tipo: String, codigo: int
) -> Dictionary:
	if not preferencias.get("acciones", {}).has(accion) or tipo not in ["teclado", "mando"]:
		return {"ok": false, "motivo": "accion-invalida"}
	var ocupada := conflicto(preferencias, tipo, codigo, accion)
	if not ocupada.is_empty():
		return {"ok": false, "motivo": "conflicto", "accion": ocupada}
	preferencias["acciones"][accion][tipo] = codigo
	return {"ok": true, "motivo": "aplicada"}


## Aplica las preferencias al mapa de entrada sin que las pantallas conozcan el formato.
static func aplicar(preferencias: Dictionary) -> void:
	for accion in preferencias.get("acciones", {}):
		if not InputMap.has_action(accion):
			InputMap.add_action(accion)
		InputMap.action_erase_events(accion)
		var descripcion: Dictionary = preferencias["acciones"][accion]
		var tecla := InputEventKey.new()
		tecla.physical_keycode = int(descripcion.get("teclado", 0))
		InputMap.action_add_event(accion, tecla)
		var boton := InputEventJoypadButton.new()
		boton.button_index = int(descripcion.get("mando", 0))
		InputMap.action_add_event(accion, boton)


static func guardar(preferencias: Dictionary, ruta: String = RUTA) -> bool:
	var temporal := ruta + ".nuevo"
	var fichero := FileAccess.open(temporal, FileAccess.WRITE)
	if fichero == null:
		return false
	fichero.store_string(JSON.stringify(preferencias, "\t"))
	fichero.close()
	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporal), ProjectSettings.globalize_path(ruta)
	)
	if error != OK:
		if FileAccess.file_exists(temporal):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temporal))
		return false
	return true


static func cargar(ruta: String = RUTA) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		return nuevas()
	var datos = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if not datos is Dictionary or int(datos.get("version", 0)) != VERSION:
		return nuevas()
	var resultado := nuevas()
	for accion in resultado["acciones"]:
		if datos.get("acciones", {}).has(accion):
			resultado["acciones"][accion] = datos["acciones"][accion].duplicate()
	resultado["reduccion_movimiento"] = bool(datos.get("reduccion_movimiento", false))
	resultado["escala_ui"] = clampf(
		float(datos.get("escala_ui", 1.0)), ESCALA_UI_MIN, ESCALA_UI_MAX
	)
	resultado["volumen"] = clampf(float(datos.get("volumen", 1.0)), 0.0, 1.0)
	resultado["sensibilidad_camara_raton"] = clampf(
		float(datos.get("sensibilidad_camara_raton", 1.0)),
		SENSIBILIDAD_CAMARA_MIN,
		SENSIBILIDAD_CAMARA_MAX
	)
	resultado["sensibilidad_camara_mando"] = clampf(
		float(datos.get("sensibilidad_camara_mando", 1.0)),
		SENSIBILIDAD_CAMARA_MIN,
		SENSIBILIDAD_CAMARA_MAX
	)
	resultado["invertir_camara_y"] = bool(datos.get("invertir_camara_y", false))
	var posicion: Variant = datos.get("posicion_asistente_gato", null)
	if posicion is Dictionary and posicion.has("x") and posicion.has("y"):
		resultado["posicion_asistente_gato"] = {
			"x": float(posicion["x"]), "y": float(posicion["y"])
		}
	return resultado
