extends Node

var _fallos: Array[String] = []


func _ready() -> void:
	var config := {
		"intensidad": 1.0,
		"semilla": "issue-806-smoke",
	}
	var original := "ARCHIVO 13 / ACCESO RESTRINGIDO"
	var a := TextoCorruptoNarrativo.resolver_texto(original, 0.72, "estable")
	var b := TextoCorruptoNarrativo.resolver_texto(original, 0.72, "estable")
	_comprobar(a == b, "misma semilla produce mismo resultado")
	_comprobar(a != original, "la corrupción altera texto no crítico")

	var reducido := TextoCorruptoNarrativo.resolver_texto(original, 1.0, "estable", true)
	_comprobar(reducido == original, "reducción de movimiento conserva texto legible")
	var critico := TextoCorruptoNarrativo.resolver_texto(original, 1.0, "estable", false, true)
	_comprobar(critico == original, "información crítica conserva alternativa legible")

	var documento := RichTextLabel.new()
	var presentacion_doc := TextoCorruptoNarrativo.aplicar(documento, original, 0.8, config)
	_comprobar(documento.text != original, "RichTextLabel recibe el efecto")
	_comprobar(presentacion_doc["texto_legible"] == original, "documento conserva copia legible")

	var rotulo := Label3D.new()
	TextoCorruptoNarrativo.aplicar(rotulo, "ARCHIVO CENTRAL", 0.8, config)
	_comprobar(rotulo.text != "ARCHIVO CENTRAL", "Label3D recibe el efecto")

	var ida := TextoCorruptoNarrativo.progreso_para_tiempo(0.25, 1.0)
	var vuelta := TextoCorruptoNarrativo.progreso_para_tiempo(0.25, 1.0, true)
	_comprobar(is_equal_approx(ida, 0.25), "progresión animada normal")
	_comprobar(is_equal_approx(vuelta, 0.75), "progresión animada reversible")

	documento.free()
	rotulo.free()
	if _fallos.is_empty():
		print("OK issue #806")
		get_tree().quit(0)
	else:
		for fallo in _fallos:
			push_error(fallo)
		get_tree().quit(1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		_fallos.append(mensaje)
