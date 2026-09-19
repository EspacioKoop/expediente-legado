extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)

	var lectura := PopolWujTrayecto3D.montar(mundo)
	_comprobar(lectura != null, "monta punto de lectura exterior")
	_comprobar(
		mundo.get_node_or_null(PopolWujTrayecto3D.NOMBRE_RAIZ) != null,
		"crea raíz estable en trayecto",
	)
	if lectura == null:
		mundo.queue_free()
		_terminar()
		return

	_comprobar(lectura.verbo == Interactuable3D.Verbo.LEER, "usa verbo LEER")
	_comprobar(
		String(lectura.get_meta("publicacion_id", "")) == "libro_popol_wuj_98",
		"expone el cuaderno correcto",
	)
	_comprobar(
		String(lectura.get_meta("fuente_semilla", "")) == "libro:popol_wuj_98",
		"conserva fuente cultural estable",
	)
	_comprobar(
		bool(lectura.get_meta("punto_lectura_trayecto", false)),
		"declara que es lectura del trayecto",
	)
	_comprobar(
		lectura.get_node_or_null("VolumenLectura") is CollisionShape3D,
		"tiene volumen de interacción propio",
	)
	_comprobar(
		String(lectura.get_meta("acabado_publicacion", "")) == "editorial_98",
		"reutiliza acabado físico común",
	)
	_comprobar(
		String(lectura.get_meta("cabecera_publicacion", "")) == "CUADERNO CULTURAL",
		"la portada física es identificable",
	)
	_comprobar(
		mundo.find_child("RotuloQuioscoCultural", true, false) is Label3D,
		"el punto de lectura tiene rótulo diegético",
	)

	var segunda := PopolWujTrayecto3D.montar(mundo)
	_comprobar(segunda == lectura, "montaje es idempotente")
	_comprobar(
		(
			Publicaciones98.por_id(PopolWujTrayecto3D.ITEM_ID).get("semilla_onirica", "")
			== "popol_wuj"
		),
		"la regla sigue declarada en Publicaciones98",
	)

	PopolWujTrayecto3D.limpiar(mundo)
	_comprobar(
		mundo.get_node_or_null(PopolWujTrayecto3D.NOMBRE_RAIZ) == null,
		"limpieza retira el punto al salir del trayecto",
	)
	mundo.queue_free()
	_terminar()


func _terminar() -> void:
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO PopolWujTrayecto: " + nombre)
