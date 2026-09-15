extends SceneTree

var fallos := 0
var pasadas := 0


func _initialize() -> void:
	var fuente := ["F-A", "F-B"]
	var copia := fuente.duplicate(true)
	var sala := {
		"entrada": Vector3(2, 0, 6),
		"figuras": [{"pos": Vector3(2, 0, 0)}],
		"carteles": [{"pos": Vector3(-3, 1.4, 4)}, {"pos": Vector3(8, 1.4, -9)}],
		"salidas": [{"pos": Vector3(0, 1.1, -12)}],
	}
	var vacia := EntradaSuenoCinematica.planos_de([])
	var dos := EntradaSuenoCinematica.planos_de(fuente, 0, sala)
	comprobar(fuente == copia)
	comprobar(dos == EntradaSuenoCinematica.planos_de(fuente, 0, sala))
	comprobar(dos == EntradaSuenoCinematica.planos_de(["F-A", "F-B", "F-A"], 0, sala))
	comprobar(vacia[1].rotulo.is_empty())
	comprobar(dos[1].rotulo == "F-A")
	comprobar(EntradaSuenoCinematica.planos_de([null, "", 42]) == vacia)
	comprobar(Cinematica.validar(dos).is_empty())
	comprobar(dos.all(func(p): return p.tipo == "3d"))
	# Los encuadres salen de la sala montada: foco en la primera figura,
	# detalle en el cartel más cercano y remate a la altura de los ojos.
	comprobar(EntradaSuenoCinematica.foco_de(sala) == Vector3(2, 0, 0))
	comprobar(EntradaSuenoCinematica.detalle_de(sala) == Vector3(-3, 0, 4))
	comprobar(dos[2].camara == Vector3(2, EntradaSuenoCinematica.OJOS, 6))
	comprobar(dos[0].mira.is_equal_approx(Vector3(2, 0.6, 0)))
	# Sala sin figuras: se mira hacia el resplandor de la salida.
	var sin_figuras := sala.duplicate(true)
	sin_figuras["figuras"] = []
	comprobar(EntradaSuenoCinematica.foco_de(sin_figuras) == Vector3(0, 0, -12))
	var repetida := EntradaSuenoCinematica.planos_de(fuente, 5, sala)
	comprobar(Cinematica.duracion(repetida) < Cinematica.duracion(dos))
	comprobar(repetida[2].segundos >= Cinematica.SUELO_REMATE)
	dos[1].rotulo = "ROTO"
	comprobar(EntradaSuenoCinematica.planos_de(fuente, 0, sala)[1].rotulo == "F-A")
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos else 0)


func comprobar(condicion: bool) -> void:
	if condicion:
		pasadas += 1
	else:
		fallos += 1
		push_error("Fallo en comprobación %d" % (pasadas + fallos))
