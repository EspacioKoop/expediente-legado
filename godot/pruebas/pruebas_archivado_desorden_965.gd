extends SceneTree

const Bandeja := preload("res://guion/archivado_bandeja.gd")
const Desorden3D := preload("res://guion/archivado_desorden_3d.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	var caso := {
		"id": "caso-prueba",
		"anioSuceso": 1998,
		"estado": "ABIERTO",
		"confidencial": false,
		"registros": [{"folio": "F-1998-001"}],
	}
	var estado := Bandeja.nueva([caso], ["F-1998-001"])
	var correcto := Archivado.destino_de(caso)

	_comprobar(
		not Bandeja.colocar(estado, caso, "1980-ABIERTO-GENERAL"),
		"un destino incorrecto conserva la carpeta pendiente",
	)
	_comprobar(
		not Bandeja.colocar(estado, caso, "1970-CERRADO-GENERAL"),
		"un segundo error también queda registrado",
	)
	var desorden := Bandeja.desorden_por_destino(estado)
	_comprobar(desorden.get("1980-ABIERTO-GENERAL", 0) == 1, "el primer error genera desorden")
	_comprobar(desorden.get("1970-CERRADO-GENERAL", 0) == 1, "cada destino conserva su pila")

	var serializado := Bandeja.serializar(estado)
	var restaurado := Bandeja.restaurar(serializado, [caso], ["F-1998-001"])
	_comprobar(
		Bandeja.desorden_por_destino(restaurado) == desorden,
		"recargar reconstruye el mismo desorden desde decisiones guardadas",
	)

	_comprobar(Bandeja.colocar(estado, caso, correcto), "el destino correcto resuelve el caso")
	_comprobar(
		Bandeja.desorden_por_destino(estado).is_empty(),
		"resolver el caso limpia sus errores espaciales",
	)

	var archivador := Node3D.new()
	root.add_child(archivador)
	Desorden3D.aplicar(archivador, 5)
	var pila := archivador.get_node_or_null(Desorden3D.NOMBRE)
	_comprobar(pila != null, "el desorden crea una pila 3D")
	_comprobar(
		int(archivador.get_meta("archivado_desorden", -1)) == 5,
		"el archivador conserva la cantidad lógica completa",
	)
	_comprobar(
		pila != null and pila.get_child_count() == 3,
		"la pila visual se limita a tres carpetas",
	)
	_comprobar(
		archivador.find_children("*", "CollisionShape3D", true, false).is_empty(),
		"el desorden visual no crea colisiones ni bloqueos",
	)

	Desorden3D.aplicar(archivador, 0)
	_comprobar(
		archivador.get_node_or_null(Desorden3D.NOMBRE) == null,
		"ordenar retira la pila visible",
	)
	archivador.queue_free()

	print("issue_965_desorden: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(valor: bool, nombre: String) -> void:
	if valor:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO archivado #965: %s" % nombre)
