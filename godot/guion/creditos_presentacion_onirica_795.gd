## Complementos de rodaje que existen en el juego pero no los monta Espacio3D.
## Las identidades genéricas conservan su geometría; la montaña abierta de
## #284 y el prototipo del Duat #441 requieren presentar sus modelos propios.
## Esta escena solo se incorpora en los créditos, sin alterar el sueño jugable.
extends Node3D

@export_enum("montana", "duat") var identidad: String = "montana"

const LUZ_PLATO := preload("res://escenas/creditos_luz_onirica.tscn")


func _ready() -> void:
	var plato := get_parent() as Node3D
	if plato == null:
		push_error("Creditos795: se requiere el plato 3D de Espacio3D")
		return

	# Se instancia dentro del mismo mundo 3D que la geometría real.
	add_child(LUZ_PLATO.instantiate())

	match identidad:
		"montana":
			var espacio := SuenoMontana.adaptar_espacio(Sueno.espacio("embudo", 0))
			var presentacion := SuenoMontana3D.montar(plato, espacio)
			if presentacion == null:
				push_error("Creditos795: no se pudo montar la cima del sueño")
		"duat":
			var prototipo := SuenoDuat.crear_prototipo_3d({}, true)
			prototipo.name = "PresentacionDuatCreditos795"
			plato.add_child(prototipo)
		_:
			push_error("Creditos795: identidad desconocida: " + identidad)
