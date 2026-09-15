## Aplicación sintética para probar el contrato `EscritorioSigaApp` de extremo
## a extremo (#535), sin lógica de dominio real ni pantalla propia.
##
## No es un producto: vive en `pruebas/` y solo sirve para demostrar que el
## shell puede alojar una aplicación que se limita a implementar el contrato
## (tamaños declarados, redimensionado, varias instancias y persistencia),
## algo que SIGA-98 o el Explorador no pueden probar por sí solos porque
## arrastran su propio dominio.
class_name AppSinteticaPrueba
extends RefCounted

const TAMANO_MINIMO := Vector2(260, 180)
const TAMANO_PREFERIDO := Vector2(420, 300)

var app: EscritorioSigaApp


func _init(id: String = "app-sintetica") -> void:
	app = EscritorioSigaApp.new(id, "App sintética", Callable(self, "_crear_contenido"))
	app.tamano_minimo = TAMANO_MINIMO
	app.tamano_preferido = TAMANO_PREFERIDO
	app.redimensionable = true
	app.multiples_instancias = true
	app.persistir_estado = true
	if app.obtener_estado_local("contador", null) == null:
		app.establecer_estado_local("contador", 0)


## Cuerpo trivial: una etiqueta con un contador local, para comprobar a ojo
## (y desde una prueba) que exportar/importar estado hace un viaje de ida y
## vuelta real y no solo declarativo.
func _crear_contenido() -> Control:
	var etiqueta := Label.new()
	etiqueta.name = "ContadorSintetico"
	etiqueta.text = "contador: %d" % int(app.obtener_estado_local("contador", 0))
	return etiqueta


## Simula que la aplicación cambia su propio estado local mientras está
## abierta, como haría cualquier app real antes de que el shell la persista.
func incrementar_contador() -> void:
	var actual := int(app.obtener_estado_local("contador", 0))
	app.establecer_estado_local("contador", actual + 1)
