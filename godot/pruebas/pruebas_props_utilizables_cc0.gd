## Contrato standalone para los primeros props utilizables de #680.
extends SceneTree

const Props := preload("res://guion/props_utilizables_cc0.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	_comprobar(
		Props.ids() == ["linterna_kkryy", "palanca_kkryy"],
		"el primer corte queda limitado a linterna y palanca"
	)

	for item_id in Props.ids():
		var ficha := Props.definicion(item_id)
		_comprobar(not ficha.is_empty(), "%s tiene definición" % item_id)
		_comprobar(
			String(ficha.get("modelo", "")) in ["Crowbar", "Flashlight"],
			"%s referencia un modelo permitido" % item_id
		)
		_comprobar(
			not String(ficha.get("descripcion", "")).is_empty(),
			"%s tiene descripción para el inventario" % item_id
		)
		_comprobar(
			ficha.get("usos", []) is Array and not ficha.get("usos", []).is_empty(),
			"%s declara un uso semántico" % item_id
		)

	var inventario := Inventario.nuevo()
	var palanca := Props.crear_recogible("palanca_kkryy", inventario)
	_comprobar(palanca is Recogible3D, "la palanca reutiliza Recogible3D")
	_comprobar(palanca.objeto_id == "palanca_kkryy", "la palanca conserva ID estable")
	_comprobar(palanca.vendible == false and palanca.precio == 0, "no inventa economía")
	_comprobar(
		String(palanca.metadatos.get("modelo_street_furniture", "")) == "Crowbar",
		"la palanca conserva el modelo de procedencia"
	)
	_comprobar(
		Inventario.recoger(inventario, palanca.datos_objeto()),
		"el prop entra en carried mediante Inventario"
	)
	_comprobar(
		not Inventario.recoger(inventario, palanca.datos_objeto()),
		"el inventario evita duplicar el mismo prop"
	)
	_comprobar(
		Props.crear_recogible("no_existe", inventario) == null,
		"un ID desconocido no crea un recogible"
	)

	# Recogible3D hereda Area3D y reserva un RID aunque no llegue a entrar al árbol.
	# Liberarlo explícitamente evita que el runner interprete el teardown como
	# error de motor pese a que todas las aserciones hayan pasado.
	palanca.free()
	await process_frame

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO props utilizables #680: " + nombre)
