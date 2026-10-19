## Complementos de rodaje que existen en el juego pero no los monta Espacio3D.
## Las identidades genéricas conservan su geometría; la montaña abierta de
## #284 y el prototipo del Duat #441 requieren presentar sus modelos propios.
## Esta escena solo se incorpora en los créditos, sin alterar el sueño jugable.
extends Node3D

const LUZ_PLATO := preload("res://escenas/creditos_luz_onirica.tscn")

@export_enum("montana", "duat", "desierto") var identidad: String = "montana"


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
		"desierto":
			var espacio := SuenoDesierto.adaptar_espacio(Sueno.espacio("peine", 0))
			var presentacion := SuenoDesierto3D.montar(plato, espacio)
			if presentacion == null:
				push_error("Creditos795: no se pudo montar el desierto")
		"duat":
			# El prototipo incluye pirámides por encima de tres metros.
			# El volumen cerrado de la forma base taparía su arquitectura.
			for hijo in plato.get_children():
				if hijo is StaticBody3D:
					var malla := hijo.get_node_or_null("Malla") as MeshInstance3D
					if malla != null:
						malla.visible = false
			var prototipo := SuenoDuat.crear_prototipo_3d({}, true)
			prototipo.name = "PresentacionDuatCreditos795"
			_realzar_materiales_duat(prototipo)
			plato.add_child(prototipo)
		_:
			push_error("Creditos795: identidad desconocida: " + identidad)


## El prototipo del Duat utiliza la textura PBR oscura de la vertical jugable.
## El corredor de créditos exige ver la pirámide y la balanza a 1080p.
## Solo duplicamos los materiales DE ESTA INSTANCIA, sin alterar recursos
## compartidos, geometría ni la versión jugable del sueño.
func _realzar_materiales_duat(prototipo: Node3D) -> void:
	for nodo in prototipo.find_children("*", "MeshInstance3D", true, false):
		var pieza := nodo as MeshInstance3D
		var origen := pieza.material_override as StandardMaterial3D
		if origen == null:
			continue
		var material := origen.duplicate() as StandardMaterial3D
		material.emission_enabled = true
		# La primera captura reveló una pirámide quemada en blanco.
		# Piedra fría frente al bronce de la balanza; ambos visibles sin
		# convertir el Duat en un cartel de luz blanca.
		var tono := Color(0.58, 0.42, 0.27)
		if pieza.name.begins_with("Piramide"):
			tono = Color(0.40, 0.43, 0.55)
		material.emission = tono
		material.emission_energy_multiplier = 0.45
		pieza.material_override = material
