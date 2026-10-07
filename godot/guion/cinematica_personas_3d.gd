## Monta actores 3D reales dentro de los platós aislados de CinematicaApp.\n##\n## `personas` reutiliza el pipeline Rocketbox; `modelos` instancia assets 3D\n## completos para criaturas, props o escenografía cuando existan. Así las\n## cinemáticas no necesitan volver a representar nada con primitivas.
class_name CinematicaPersonas3D
extends RefCounted


static func montar(raiz: Node3D, decorado: Dictionary) -> void:\n\tfor ficha in decorado.get("personas", []):\n\t\tif ficha is Dictionary:\n\t\t\t_montar_persona(raiz, ficha)\n\tfor ficha in decorado.get("modelos", []):\n\t\tif ficha is Dictionary:\n\t\t\t_montar_modelo(raiz, ficha)\n\n\nstatic func _montar_modelo(raiz: Node3D, ficha: Dictionary) -> void:\n\tvar nombre := String(ficha.get("modelo", ""))\n\tif nombre.is_empty():\n\t\treturn\n\tvar escena := Modelos.cargar(nombre)\n\tif escena == null:\n\t\treturn\n\tvar nodo := escena.instantiate() as Node3D\n\tif nodo == null:\n\t\treturn\n\tnodo.name = String(ficha.get("nombre", nombre.get_file()))\n\tnodo.position = ficha.get("pos", Vector3.ZERO)\n\tnodo.rotation_degrees = ficha.get("rotacion", Vector3.ZERO)\n\tnodo.scale = Vector3.ONE * float(ficha.get("escala", 1.0))\n\traiz.add_child(nodo)\n

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
