extends SceneTree

const Falsificacion := preload("res://guion/falsificacion_documental.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	var registro := {
		"id": "factura-prueba",
		"folio": "F-1998-001",
		"fecha": "1998-04-03",
		"contenido": "Documento con sello de recibido y firma del responsable.",
	}
	var original := registro.duplicate(true)

	var sello := Falsificacion.crear_copia(registro, "sello", 4)
	_comprobar(bool(sello.get("temporal", false)), "la copia se marca como temporal")
	_comprobar(sello.get("calidad") == "alta", "apoyo y atención producen calidad alta")
	_comprobar(sello.get("riesgo") == "bajo", "la calidad alta reduce el riesgo descrito")
	_comprobar(
		Falsificacion.resolver_revision(sello) == "aceptada",
		"una copia alta pasa el control interno",
	)

	var fecha := Falsificacion.crear_copia(registro, "fecha", 2)
	_comprobar(fecha.get("calidad") == "media", "la calidad intermedia es determinista")
	_comprobar(
		Falsificacion.resolver_revision(fecha) == "cotejo",
		"una copia media exige cotejo",
	)

	var sin_apoyo := {
		"id": "nota-prueba",
		"contenido": "Texto mecanografiado sin rasgos materiales adicionales.",
	}
	var firma := Falsificacion.crear_copia(sin_apoyo, "firma", 0)
	_comprobar(firma.get("calidad") == "baja", "sin apoyo ni atención la copia es frágil")
	_comprobar(firma.get("riesgo") == "alto", "la copia frágil declara riesgo alto")
	_comprobar(
		Falsificacion.resolver_revision(firma) == "retenida",
		"una copia baja queda retenida",
	)

	_comprobar(
		Falsificacion.crear_copia(registro, "sello", 4) == sello,
		"la misma entrada produce el mismo resultado",
	)
	_comprobar(
		Falsificacion.crear_copia(registro, "inventado", 12).is_empty(),
		"una intervención desconocida se rechaza",
	)
	_comprobar(registro == original, "crear una copia no muta el documento original")
	_comprobar(
		Falsificacion.resolver_revision({}).is_empty(),
		"una copia inválida no inventa consecuencia",
	)

	print("issue_951_falsificacion: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(valor: bool, nombre: String) -> void:
	if valor:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO falsificación #951: %s" % nombre)
