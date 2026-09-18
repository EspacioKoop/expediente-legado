from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
GUION = ROOT / "godot" / "guion"

FAMILIAS = {
    "castillo": {
        "logica": GUION / "sueno_castillo.gd",
        "presentacion": GUION / "sueno_castillo_3d.gd",
        "audio": GUION / "sueno_castillo_audio.gd",
        "marcadores": (
            "retorno_patio",
            "codice_desplazado",
            "CampanasSinFuente",
            'evento == "codice_castillo"',
        ),
    },
    "montana": {
        "logica": GUION / "sueno_montana.gd",
        "presentacion": GUION / "sueno_montana_3d.gd",
        "audio": GUION / "sueno_montana_audio.gd",
        "marcadores": (
            "cabana_perspectiva",
            "huellas_anticipadas",
            "CrujidosTrasPuerta",
            "DocumentoCongelado",
        ),
    },
    "desierto": {
        "logica": GUION / "sueno_desierto.gd",
        "presentacion": GUION / "sueno_desierto_3d.gd",
        "audio": GUION / "sueno_desierto_audio.gd",
        "marcadores": (
            "horizonte_recede",
            "silencio_local",
            "SombraSinObjeto",
            "TonoSinLinea",
        ),
    },
    "escuela": {
        "logica": GUION / "sueno_escuela.gd",
        "presentacion": GUION / "sueno_escuela_3d.gd",
        "audio": GUION / "sueno_escuela_audio.gd",
        "marcadores": (
            "aulas_reordenadas",
            "pupitres_pared_vacia",
            "RelojTresAgujas",
            "TimbreFueraDeHorario",
        ),
    },
}

DIA_SUENO = GUION / "dia_sueno_app.gd"
SUENO_FORMAS = GUION / "sueno_formas.gd"


class SuenoIdentidades284Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dia = DIA_SUENO.read_text(encoding="utf-8")
        cls.formas = SUENO_FORMAS.read_text(encoding="utf-8")
        cls.familias = {}
        for nombre, contrato in FAMILIAS.items():
            cls.familias[nombre] = {
                "logica": contrato["logica"].read_text(encoding="utf-8"),
                "presentacion": contrato["presentacion"].read_text(encoding="utf-8"),
                "audio": contrato["audio"].read_text(encoding="utf-8"),
                "marcadores": contrato["marcadores"],
            }

    def test_las_cuatro_identidades_son_distintas_y_estan_montadas(self):
        ids = {}
        for nombre, fuentes in self.familias.items():
            match = re.search(r'const ID := "([^"]+)"', fuentes["logica"])
            self.assertIsNotNone(match, nombre)
            ids[nombre] = match.group(1)
        self.assertEqual(len(ids), 4)
        self.assertEqual(len(set(ids.values())), 4)

        for clase in ("Castillo", "Montana", "Desierto", "Escuela"):
            self.assertIn(
                f"Sueno{clase}3D.montar(_mundo, _espacio_actual)",
                self.dia,
            )

    def test_cada_familia_conserva_una_firma_de_extraneza_propia(self):
        firmas = {}
        for nombre, fuentes in self.familias.items():
            conjunto = set(fuentes["marcadores"])
            self.assertGreaterEqual(len(conjunto), 4, nombre)
            combinado = "\n".join(
                (fuentes["logica"], fuentes["presentacion"], fuentes["audio"], self.dia)
            )
            for marcador in conjunto:
                self.assertIn(marcador, combinado, f"{nombre}: falta {marcador}")
            firmas[nombre] = conjunto

        nombres = tuple(firmas)
        for i, nombre_a in enumerate(nombres):
            for nombre_b in nombres[i + 1 :]:
                self.assertFalse(
                    firmas[nombre_a] & firmas[nombre_b],
                    f"{nombre_a} y {nombre_b} comparten firma específica",
                )

    def test_todas_tienen_sonido_procedural_sin_binarios_externos(self):
        for nombre, fuentes in self.familias.items():
            audio = fuentes["audio"]
            self.assertIn("AudioStreamWAV.new()", audio, nombre)
            self.assertNotIn("res://assets/audio", audio, nombre)
            self.assertNotIn("load(", audio, nombre)

    def test_presentaciones_no_crean_una_segunda_fisica(self):
        for nombre, fuentes in self.familias.items():
            presentacion = fuentes["presentacion"]
            for termino in ("StaticBody3D.new", "CollisionShape3D.new"):
                self.assertNotIn(termino, presentacion, f"{nombre}: {termino}")
            self.assertIn('espacio.get("identidad_onirica", "")', presentacion, nombre)

    def test_adaptadores_no_mutan_estado_persistente(self):
        for nombre, fuentes in self.familias.items():
            logica = fuentes["logica"]
            codigo = logica.split("class_name ", 1)[1]
            for termino in ("Jornada.", "Partida.", "dinero", "veredicto"):
                self.assertNotIn(termino, codigo, f"{nombre}: {termino}")

    def test_formas_base_no_colisionan_entre_verticales(self):
        formas = {}
        for nombre in ("montana", "desierto", "escuela"):
            match = re.search(r'const FORMA := "([^"]+)"', self.familias[nombre]["logica"])
            self.assertIsNotNone(match, nombre)
            formas[nombre] = match.group(1)
        self.assertEqual(len(set(formas.values())), len(formas))
        self.assertIn('"identidad_onirica": SuenoCastillo.ID', self.formas)

    def test_horror_se_aplica_despues_de_resolver_identidad(self):
        bloque = self.dia.split("func _espacio_de(fase: String) -> Dictionary:", 1)[1]
        self.assertLess(
            bloque.index("SuenoEscuela.adaptar_espacio"),
            bloque.index("HorrorTexturas.aplicar"),
        )
        self.assertLess(
            bloque.index("SuenoMontana.adaptar_espacio"),
            bloque.index("HorrorTexturas.aplicar"),
        )
        self.assertLess(
            bloque.index("SuenoDesierto.adaptar_espacio"),
            bloque.index("HorrorTexturas.aplicar"),
        )


if __name__ == "__main__":
    unittest.main()
