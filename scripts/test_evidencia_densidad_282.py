"""Contrato de evidencia reproducible para el gate visual de #282."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class EvidenciaDensidad282Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.captura = (ROOT / "godot/pruebas/capturar_densidad_282.gd").read_text(
            encoding="utf-8"
        )
        cls.workflow = (
            ROOT / ".github/workflows/evidencia-densidad-282.yml"
        ).read_text(encoding="utf-8")
        cls.docs = (
            ROOT / "docs/evidencias/densidad-282/README.md"
        ).read_text(encoding="utf-8")

    def test_captura_las_cuatro_fases_reales_sin_hud(self):
        self.assertIn('load("res://escenas/dia.tscn").instantiate()', self.captura)
        for caso, fase in (
            ("oficina", "archivo"),
            ("calle", "trayecto"),
            ("casa", "casa"),
            ("sueno", "sueño"),
        ):
            self.assertIn(f'"id": "{caso}"', self.captura)
            self.assertIn(f'"fase": "{fase}"', self.captura)
        self.assertIn('"hud": false', self.captura)
        self.assertIn("dia._hud_prioridades.visible = false", self.captura)
        self.assertIn('dia.find_children("*", "CanvasLayer"', self.captura)

    def test_usa_camara_jugable_y_encuadres_fijos(self):
        self.assertIn('dia._caminante.get_node("Camara")', self.captura)
        self.assertIn("camara.fov = FOV", self.captura)
        self.assertIn("dia._caminante.situar(entrada, mirada)", self.captura)
        self.assertIn("root.size = TAMANO", self.captura)
        self.assertIn('"mirada": 180.0', self.captura)
        self.assertIn(
            'camara.rotation.x = deg_to_rad(float(caso["inclinacion"]))',
            self.captura,
        )

    def test_manifiesto_mide_densidad_sin_convertirla_en_veredicto(self):
        self.assertIn("Densidad.auditar(dia._espacio_actual)", self.captura)
        for campo in (
            '"bultos_modelados"',
            '"bultos_proxy"',
            '"ratio_bultos_modelados"',
            '"mallas_total"',
            '"mallas_caja"',
            '"mallas_planas"',
            '"mallas_array"',
            '"lotes_multimesh"',
            '"interactuables"',
        ):
            self.assertIn(campo, self.captura)
        self.assertIn('"criterio": "evidencia_para_revision_humana"', self.captura)
        self.assertIn("NO deciden", self.captura)

    def test_workflow_publica_png_y_manifiesto(self):
        self.assertIn("xvfb-run -a godot4", self.workflow)
        self.assertIn("for captura in oficina calle casa sueno; do", self.workflow)
        self.assertIn('test -s "evidencia-densidad-282/## Evidencia reproducible del gate de densidad 3D de #282.
##
## Renderiza las cuatro fases del recorrido real desde `dia.tscn`, con HUD
## oculto y cámara del jugador. Además registra señales objetivas de composición:
## bultos declarativos modelados/proxy, tipos de malla e interactuables presentes.
##
## Las métricas NO deciden si el espacio "se ve terminado": una BoxMesh puede ser
## correcta para un objeto prismático y una ArrayMesh puede seguir siendo pobre.
## Sirven para revisar siempre el mismo estado junto a las capturas.
extends SceneTree

const Densidad := preload("res://guion/densidad_3d.gd")

const TAMANO := Vector2i(1280, 720)
const FOV := 70.0
const FRAMES_ESTABILIZACION := 2

const CASOS := [
	{"id": "oficina", "fase": "archivo", "mirada": 0.0, "inclinacion": -8.0},
	{"id": "calle", "fase": "trayecto", "mirada": 180.0, "inclinacion": -6.0},
	{"id": "casa", "fase": "casa", "mirada": 0.0, "inclinacion": -10.0},
	{
		"id": "sueno",
		"fase": "sueño",
		"escena": "crucero",
		"mirada": 0.0,
		"inclinacion": -8.0,
	},
]


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-densidad-282")
	)
	if not salida.is_absolute_path():
		salida = ProjectSettings.globalize_path("res://").path_join(salida)
	var error_dir := DirAccess.make_dir_recursive_absolute(salida)
	if error_dir != OK:
		printerr("No se pudo crear %s (error %d)" % [salida, error_dir])
		quit(1)
		return

	root.size = TAMANO
	var dia = load("res://escenas/dia.tscn").instantiate()
	root.add_child(dia)
	await process_frame

	if dia._entrada != null:
		dia._entrada.saltar()
		await process_frame
	dia.set_process(false)

	var manifiesto := {
		"issue": 282,
		"escena": "res://escenas/dia.tscn",
		"tamano": [TAMANO.x, TAMANO.y],
		"fov": FOV,
		"hud": false,
		"criterio": "evidencia_para_revision_humana",
		"casos": [],
	}

	for caso in CASOS:
		if String(caso["fase"]) == "sueño":
			dia.jornada["sueno_escenas"] = [String(caso["escena"])]
		dia._entrar_en(String(caso["fase"]))
		_estabilizar_camara(dia, caso)

		for i in FRAMES_ESTABILIZACION:
			await process_frame
		_ocultar_hud(dia)
		await RenderingServer.frame_post_draw

		var archivo := "%s.png" % String(caso["id"])
		var destino := salida.path_join(archivo)
		if not _guardar_captura(destino):
			quit(1)
			return

		var auditoria := Densidad.auditar(dia._espacio_actual)
		var diagnostico := _diagnostico_runtime(dia)
		manifiesto["casos"].append(
			{
				"id": String(caso["id"]),
				"fase": String(caso["fase"]),
				"captura": archivo,
				"mirada": float(caso["mirada"]),
				"inclinacion": float(caso["inclinacion"]),
				"bultos_total": int(auditoria["total"]),
				"bultos_modelados": int(auditoria["modelados"]),
				"bultos_proxy": int(auditoria["proxies"]),
				"ratio_bultos_modelados": float(auditoria["ratio_modelado"]),
				"mallas_total": diagnostico["mallas_total"],
				"mallas_caja": diagnostico["mallas_caja"],
				"mallas_planas": diagnostico["mallas_planas"],
				"mallas_array": diagnostico["mallas_array"],
				"mallas_primitivas_otras": diagnostico["mallas_primitivas_otras"],
				"lotes_multimesh": diagnostico["lotes_multimesh"],
				"interactuables": diagnostico["interactuables"],
				"interactuables_habilitados": diagnostico["interactuables_habilitados"],
				"sha256": FileAccess.get_sha256(destino),
			}
		)

	var ruta_manifiesto := salida.path_join("manifest.json")
	var archivo_manifiesto := FileAccess.open(ruta_manifiesto, FileAccess.WRITE)
	if archivo_manifiesto == null:
		printerr("No se pudo crear %s" % ruta_manifiesto)
		quit(1)
		return
	archivo_manifiesto.store_string(JSON.stringify(manifiesto, "\t") + "\n")
	archivo_manifiesto.close()
	print("evidencia #282 -> %s" % salida)
	quit(0)


func _estabilizar_camara(dia, caso: Dictionary) -> void:
	var entrada: Vector3 = dia._espacio_actual["entrada"]
	var mirada := float(caso["mirada"])
	dia._caminante.situar(entrada, mirada)
	dia._caminante.set_physics_process(false)
	var camara := dia._caminante.get_node("Camara") as Camera3D
	camara.fov = FOV
	camara.rotation.x = deg_to_rad(float(caso["inclinacion"]))


func _ocultar_hud(dia) -> void:
	if dia._hud_prioridades != null:
		dia._hud_prioridades.visible = false
	for capa in dia.find_children("*", "CanvasLayer", true, false):
		if capa is CanvasLayer:
			capa.visible = false


func _guardar_captura(destino: String) -> bool:
	var imagen := root.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		printerr("Viewport vacío para %s" % destino)
		return false
	var error_png := imagen.save_png(destino)
	if error_png != OK:
		printerr("No se pudo guardar %s (error %d)" % [destino, error_png])
		return false
	print("captura -> %s" % destino)
	return true


func _diagnostico_runtime(dia) -> Dictionary:
	var total := 0
	var cajas := 0
	var planas := 0
	var arrays := 0
	var primitivas_otras := 0
	var multimesh := 0
	var interactuables := 0
	var interactuables_habilitados := 0

	for nodo in dia._mundo.find_children("*", "MeshInstance3D", true, false):
		var instancia := nodo as MeshInstance3D
		if instancia == null or instancia.mesh == null:
			continue
		total += 1
		if instancia.mesh is BoxMesh:
			cajas += 1
		elif instancia.mesh is PlaneMesh or instancia.mesh is QuadMesh:
			planas += 1
		elif instancia.mesh is ArrayMesh:
			arrays += 1
		else:
			primitivas_otras += 1

	for nodo in dia._mundo.find_children("*", "MultiMeshInstance3D", true, false):
		if nodo is MultiMeshInstance3D:
			multimesh += 1

	for nodo in dia._mundo.find_children("*", "Area3D", true, false):
		if nodo is Interactuable3D:
			interactuables += 1
			if nodo.habilitado:
				interactuables_habilitados += 1

	return {
		"mallas_total": total,
		"mallas_caja": cajas,
		"mallas_planas": planas,
		"mallas_array": arrays,
		"mallas_primitivas_otras": primitivas_otras,
		"lotes_multimesh": multimesh,
		"interactuables": interactuables,
		"interactuables_habilitados": interactuables_habilitados,
	}
.png"', self.workflow)
        self.assertIn("manifest.json", self.workflow)
        self.assertIn("actions/upload-artifact@v4", self.workflow)
        self.assertIn("len(set(hashes)) != 4", self.workflow)
        self.assertIn('caso["mallas_total"] <= 0', self.workflow)

    def test_documentacion_exige_revision_humana(self):
        self.assertIn("sin HUD", self.docs)
        self.assertIn("revisión humana", self.docs.lower())
        self.assertIn("no sustituye", self.docs.lower())
        self.assertIn("boxmesh", self.docs.lower())
        self.assertIn("manifest.json", self.docs)


if __name__ == "__main__":
    unittest.main()
