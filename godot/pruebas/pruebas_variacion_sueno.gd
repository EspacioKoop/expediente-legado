extends SceneTree

var fallos := 0
var pasadas := 0


func _initialize() -> void:
	var fuente := ["F-A", "F-B"]
	var copia := fuente.duplicate(true)
	var vacia := EntradaSuenoCinematica.planos_de([])
	var una := EntradaSuenoCinematica.planos_de(["F-A"])
	var dos := EntradaSuenoCinematica.planos_de(fuente)
	comprobar(fuente == copia)
	comprobar(dos == EntradaSuenoCinematica.planos_de(fuente))
	comprobar(dos == EntradaSuenoCinematica.planos_de(["F-A", "F-B", "F-A"]))
	comprobar(vacia[1].figura.size() == vacia[0].figura.size())
	comprobar(vacia[1].rotulo.is_empty())
	comprobar(vacia[1].figura != vacia[0].figura)
	comprobar(una[1].figura.size() == 7)
	comprobar(dos[1].figura.size() == 10)
	comprobar(dos[1].rotulo == "F-A")
	comprobar(EntradaSuenoCinematica.planos_de(["A", "B", "C", "D"])[1].figura.size() == 13)
	comprobar(EntradaSuenoCinematica.planos_de([null, "", 42]) == vacia)
	comprobar(Cinematica.validar(dos).is_empty())
	comprobar(dos.all(func(p): return p.desde == p.hasta))
	comprobar(dos[0].figura == vacia[0].figura)
	comprobar(dos[2].figura == vacia[2].figura)
	var repetida := EntradaSuenoCinematica.planos_de(fuente, 5)
	comprobar(Cinematica.duracion(repetida) < Cinematica.duracion(dos))
	comprobar(repetida[1].figura == dos[1].figura)
	comprobar(repetida[2].segundos >= Cinematica.SUELO_REMATE)
	dos[1].figura[0].color = Color.RED
	comprobar(EntradaSuenoCinematica.planos_de(fuente)[1].figura[0].color != Color.RED)
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos else 0)


func comprobar(condicion: bool) -> void:
	if condicion:
		pasadas += 1
	else:
		fallos += 1
		push_error("Fallo en comprobación %d" % (pasadas + fallos))
