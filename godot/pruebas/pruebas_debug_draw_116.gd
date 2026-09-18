## Smoke del Debug Draw 3D de #116 sobre datos reales de Planta.
extends RefCounted


class DiaFalso:
	extends Node

	var _mundo := Node3D.new()
	var _espacio_actual: Dictionary = {}


static func todo(comprobar: Callable) -> void:
	var dia := DiaFalso.new()
	dia._espacio_actual = {
		"planta": [Rect2i(0, 0, 2, 2)],
		"contorno":
		PackedVector2Array(
			[
				Vector2(-2, -2),
				Vector2(2, -2),
				Vector2(2, 2),
				Vector2(-2, 2),
			]
		),
		"entrada": Vector3(-1, 0, -1),
		"salidas":
		[
			{
				"pos": Vector3(1, 1.1, 1),
				"tam": Vector3(1.8, 2.2, 1.8),
				"destino": "archivo",
			}
		],
		"figuras":
		[
			{"pos": Vector3(-1, 0, 1), "rotulo": "A"},
			{"pos": Vector3(1, 0, -1), "rotulo": "B", "giro": PI / 2.0},
		],
	}

	dia.add_child(dia._mundo)

	var script := load("res://debug/dibujo_3d.gd") as Script
	comprobar.call("el dibujo QA carga desde debug", script != null, true)
	if script == null:
		dia.free()
		return

	var dibujo := script.new() as Node3D
	comprobar.call("el dibujo QA es un nodo 3D", dibujo != null, true)
	if dibujo == null:
		dia.free()
		return

	dia.add_child(dibujo)
	dibujo.call("configurar", dia)
	var resumen: Dictionary = dibujo.call("resumen")
	comprobar.call("dibuja las cuatro celdas", int(resumen["celdas"]), 4)
	comprobar.call("dibuja los cuatro tramos de muro", int(resumen["muros"]), 4)
	comprobar.call("dibuja las cuatro aristas físicas", int(resumen["contorno_fisico"]), 4)
	comprobar.call("marca la salida", int(resumen["salidas"]), 1)
	comprobar.call("marca las dos figuras", int(resumen["figuras"]), 2)

	var trazos := dibujo.get_node_or_null("Trazos") as MeshInstance3D
	comprobar.call("materializa los trazos en una malla", trazos != null, true)
	comprobar.call(
		"el dibujo no añade colisiones",
		dibujo.find_children("*", "CollisionObject3D", true, false).size(),
		0
	)
	dia.free()
