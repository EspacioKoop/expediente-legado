## Preferencias de controles y presentación de SIGA-98 (#113).
##
## Esta capa no conoce ninguna pantalla: mantiene acciones semánticas, convierte
## sus descriptores en eventos de Godot y guarda solo preferencias, nunca partida.
## `ui_accept`/`ui_cancel` son únicamente adaptadores para los `Control` nativos:
## su entrada real viene de `interactuar`/`cancelar`, también cuando se remapean.
class_name PreferenciasSiga
extends RefCounted

## v2 (#98): los códigos de mando de v1 estaban desplazados una posición (la
## cruceta «arriba» era la 12, que en Godot 4 es abajo) y el stick izquierdo no
## movía. Al leer una v1 se conservan las teclas y se reponen los botones.
const VERSION := 2
const RUTA := "user://preferencias-siga.json"
const ACCIONES := {
	"mover_adelante": {"teclado": 87, "mando": JOY_BUTTON_DPAD_UP},
	"mover_atras": {"teclado": 83, "mando": JOY_BUTTON_DPAD_DOWN},
	"mover_izquierda": {"teclado": 65, "mando": JOY_BUTTON_DPAD_LEFT},
	"mover_derecha": {"teclado": 68, "mando": JOY_BUTTON_DPAD_RIGHT},
	"saltar": {"teclado": KEY_SPACE, "mando": JOY_BUTTON_X},
	"correr": {"teclado": KEY_SHIFT, "mando": JOY_BUTTON_LEFT_STICK},
	"agacharse": {"teclado": KEY_CTRL, "mando": JOY_BUTTON_RIGHT_STICK},
	"interactuar": {"teclado": 69, "mando": JOY_BUTTON_A},
	"inventario": {"teclado": KEY_I, "mando": JOY_BUTTON_Y},
	"cancelar": {"teclado": KEY_ESCAPE, "mando": JOY_BUTTON_B},
}

## El stick izquierdo mueve siempre, además del botón remapeable de la cruceta.
## No entra en el remapeo: es la convención de cualquier mando.
const EJES_MOVIMIENTO := {
	"mover_adelante": [JOY_AXIS_LEFT_Y, -1.0],
	"mover_atras": [JOY_AXIS_LEFT_Y, 1.0],
	"mover_izquierda": [JOY_AXIS_LEFT_X, -1.0],
	"mover_derecha": [JOY_AXIS_LEFT_X, 1.0],
}
## La zona muerta por defecto de una acción es 0,5: con ella el stick solo
## respondía a partir de media inclinación.
const ZONA_MUERTA_MOVIMIENTO := 0.2

## Nombres por familia. Godot entrega los botones por POSICIÓN (A es siempre el
## de abajo), así que en Nintendo el de abajo se llama B.
const NOMBRES_MANDO := {
	"xbox":
	{
		JOY_BUTTON_A: "A",
		JOY_BUTTON_B: "B",
		JOY_BUTTON_X: "X",
		JOY_BUTTON_Y: "Y",
		JOY_BUTTON_BACK: "Vista",
		JOY_BUTTON_GUIDE: "Xbox",
		JOY_BUTTON_START: "Menú",
		JOY_BUTTON_LEFT_STICK: "LS",
		JOY_BUTTON_RIGHT_STICK: "RS",
		JOY_BUTTON_LEFT_SHOULDER: "LB",
		JOY_BUTTON_RIGHT_SHOULDER: "RB",
	},
	"playstation":
	{
		JOY_BUTTON_A: "Cruz",
		JOY_BUTTON_B: "Círculo",
		JOY_BUTTON_X: "Cuadrado",
		JOY_BUTTON_Y: "Triángulo",
		JOY_BUTTON_BACK: "Share",
		JOY_BUTTON_GUIDE: "PS",
		JOY_BUTTON_START: "Options",
		JOY_BUTTON_LEFT_STICK: "L3",
		JOY_BUTTON_RIGHT_STICK: "R3",
		JOY_BUTTON_LEFT_SHOULDER: "L1",
		JOY_BUTTON_RIGHT_SHOULDER: "R1",
	},
	"nintendo":
	{
		JOY_BUTTON_A: "B",
		JOY_BUTTON_B: "A",
		JOY_BUTTON_X: "Y",
		JOY_BUTTON_Y: "X",
		JOY_BUTTON_BACK: "−",
		JOY_BUTTON_GUIDE: "Home",
		JOY_BUTTON_START: "+",
		JOY_BUTTON_LEFT_STICK: "Stick L",
		JOY_BUTTON_RIGHT_STICK: "Stick R",
		JOY_BUTTON_LEFT_SHOULDER: "L",
		JOY_BUTTON_RIGHT_SHOULDER: "R",
	},
}
const NOMBRES_CRUCETA := {
	JOY_BUTTON_DPAD_UP: "Cruceta arriba",
	JOY_BUTTON_DPAD_DOWN: "Cruceta abajo",
	JOY_BUTTON_DPAD_LEFT: "Cruceta izquierda",
	JOY_BUTTON_DPAD_RIGHT: "Cruceta derecha",
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
		"volumen_efectos": 1.0,
		"volumen_ambiente": 1.0,
		"volumen_musica": 1.0,
		"sensibilidad_camara_raton": 1.0,
		"sensibilidad_camara_mando": 1.0,
		"invertir_camara_y": false,
		"posicion_asistente_gato": null,
		"filtro_pantalla": FiltroPantalla.NINGUNO,
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
		if EJES_MOVIMIENTO.has(accion):
			var eje := InputEventJoypadMotion.new()
			eje.axis = EJES_MOVIMIENTO[accion][0]
			eje.axis_value = EJES_MOVIMIENTO[accion][1]
			InputMap.action_add_event(accion, eje)
			InputMap.action_set_deadzone(accion, ZONA_MUERTA_MOVIMIENTO)
	_sincronizar_acciones_ui()
	_asegurar_raton_interaccion()


## El clic izquierdo es una vía fija del verbo semántico `interactuar`: no se
## guarda ni se remapea, así que también aparece en partidas con preferencias v1
## o v2 ya persistidas. Se añade DESPUÉS de copiar `interactuar` a `ui_accept`
## para que el clic normal de un Control no active además el botón con foco.
static func _asegurar_raton_interaccion() -> void:
	if not InputMap.has_action("interactuar"):
		InputMap.add_action("interactuar")
	var raton := InputEventMouseButton.new()
	raton.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("interactuar", raton)


## Familia del mando conectado, para nombrar sus botones como están impresos.
static func familia_mando(dispositivo: int = -1) -> String:
	if dispositivo < 0:
		var conectados := Input.get_connected_joypads()
		if conectados.is_empty():
			return "xbox"
		dispositivo = conectados[0]
	return familia_por_nombre(Input.get_joy_name(dispositivo))


static func familia_por_nombre(nombre: String) -> String:
	var bajo := nombre.to_lower()
	for pista in ["playstation", "dualshock", "dualsense", "ps3", "ps4", "ps5", "sony"]:
		if bajo.contains(pista):
			return "playstation"
	for pista in ["nintendo", "switch", "joy-con", "pro controller"]:
		if bajo.contains(pista):
			return "nintendo"
	return "xbox"


static func nombre_boton_mando(codigo: int, familia: String = "") -> String:
	if NOMBRES_CRUCETA.has(codigo):
		return String(NOMBRES_CRUCETA[codigo])
	var nombres: Dictionary = NOMBRES_MANDO.get(
		familia if not familia.is_empty() else familia_mando(), NOMBRES_MANDO["xbox"]
	)
	return String(nombres.get(codigo, "Botón %d" % codigo))


## Los controles de Godot escuchan `ui_accept` y varias pantallas antiguas aún
## escuchan `ui_cancel`. Si esas acciones conservaran el mapa de fábrica, cambiar
## Interactuar/Cancelar en Opciones solo afectaría al mundo 3D: un botón seguiría
## usando A/Espacio y un modal seguiría cerrándose con B/Escape. Las reconstruimos
## desde las acciones semánticas cada vez que se aplica un remapeo.
static func _sincronizar_acciones_ui() -> void:
	_copiar_accion_ui("interactuar", "ui_accept")
	# Enter queda como confirmación de teclado convencional, pero el botón de
	# mando procede exclusivamente de `interactuar`, así que sí se remapea.
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	InputMap.action_add_event("ui_accept", enter)
	_copiar_accion_ui("cancelar", "ui_cancel")


static func _copiar_accion_ui(origen: StringName, destino: StringName) -> void:
	if not InputMap.has_action(destino):
		InputMap.add_action(destino)
	InputMap.action_erase_events(destino)
	for evento in InputMap.action_get_events(origen):
		var copia := evento.duplicate() as InputEvent
		if copia != null:
			InputMap.action_add_event(destino, copia)


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
	if not datos is Dictionary or int(datos.get("version", 0)) not in [1, VERSION]:
		return nuevas()
	var resultado := nuevas()
	var botones_v1 := int(datos.get("version", 0)) == 1
	for accion in resultado["acciones"]:
		if datos.get("acciones", {}).has(accion):
			var guardada: Dictionary = datos["acciones"][accion].duplicate()
			if botones_v1:
				guardada["mando"] = ACCIONES[accion]["mando"]
			resultado["acciones"][accion] = guardada
	resultado["reduccion_movimiento"] = bool(datos.get("reduccion_movimiento", false))
	resultado["escala_ui"] = clampf(
		float(datos.get("escala_ui", 1.0)), ESCALA_UI_MIN, ESCALA_UI_MAX
	)
	resultado["volumen"] = clampf(float(datos.get("volumen", 1.0)), 0.0, 1.0)
	resultado["volumen_efectos"] = clampf(float(datos.get("volumen_efectos", 1.0)), 0.0, 1.0)
	resultado["volumen_ambiente"] = clampf(float(datos.get("volumen_ambiente", 1.0)), 0.0, 1.0)
	resultado["volumen_musica"] = clampf(float(datos.get("volumen_musica", 1.0)), 0.0, 1.0)
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
	resultado["filtro_pantalla"] = FiltroPantalla.valido(datos.get("filtro_pantalla"))
	var posicion: Variant = datos.get("posicion_asistente_gato", null)
	if posicion is Dictionary and posicion.has("x") and posicion.has("y"):
		resultado["posicion_asistente_gato"] = {
			"x": float(posicion["x"]), "y": float(posicion["y"])
		}
	return resultado
