## Monta avatares realistas dentro de los platós aislados de CinematicaApp.
##
## El decorado declara una lista "personas"; cada entrada reutiliza el pipeline
## normal de Modelos.persona, por lo que conserva texturas, normal maps, shader
## del sitio, rasgos históricos Rocketbox y animaciones existentes.
class_name CinematicaPersonas3D
extends RefCounted


static func montar(raiz: Node3D, decorado: Dictionary) -> void:
	for ficha in decorado.get("personas", []):
		if not ficha is Dictionary:
			continue
		_montar_persona(raiz, ficha)


static func _montar_persona(raiz: Node3D, ficha: Dictionary) -> void:
	var modelo := String(ficha.get("modelo", ""))
	if modelo.is_empty():
		return
	var ancla := Node3D.new()
	ancla.name = String(ficha.get("nombre", "PersonaCinematica"))
	ancla.position = ficha.get("pos", Vector3.ZERO)
	ancla.rotation.y = deg_to_rad(float(ficha.get("rumbo", 180.0)))
	var escala := float(ficha.get("escala", 1.0))
	ancla.scale = Vector3.ONE * escala
	raiz.add_child(ancla)

	var cuerpo := Node3D.new()
	cuerpo.name = "Cuerpo"
	ancla.add_child(cuerpo)
	if not Modelos.persona(
		cuerpo,
		modelo,
		Color.WHITE,
		String(ficha.get("retrato", ""))
	):
		return
	var pieza := cuerpo.get_child(0) as Node3D
	if pieza == null:
		return
	var gesto := String(ficha.get("gesto", "idle"))
	var desfase := float(ficha.get("desfase", 0.0))
	if not gesto.is_empty():
		AnimacionesUAL.reproducir(pieza, gesto, desfase)
