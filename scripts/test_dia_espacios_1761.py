from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DIA = (ROOT / "godot/guion/dia_app.gd").read_text(encoding="utf-8")
ESPACIOS = (ROOT / "godot/guion/dia_espacios_app.gd").read_text(encoding="utf-8")
SUBCLASES = {
    nombre: (ROOT / f"godot/guion/{nombre}.gd").read_text(encoding="utf-8")
    for nombre in (
        "dia_calle_app",
        "dia_sueno_app",
        "dia_clima_app",
        "dia_gato_app",
    )
}


def bloque_funcion(fuente: str, nombre: str) -> str:
    inicio = fuente.index(f"func {nombre}(")
    siguiente = fuente.find("\nfunc ", inicio + 5)
    return fuente[inicio:] if siguiente < 0 else fuente[inicio:siguiente]


class DiaEspacios1761Test(unittest.TestCase):
    def test_dia_app_delega_y_helper_permanece_acotado(self):
        self.assertLess(len(DIA.splitlines()), 850)
        self.assertLess(len(ESPACIOS.splitlines()), 120)
        self.assertIn(
            'const DIA_ESPACIOS_APP = preload("res://guion/dia_espacios_app.gd")',
            DIA,
        )
        self.assertIn("DIA_ESPACIOS_APP.resolver_espacio_base(fase, jornada)", DIA)
        self.assertIn("DIA_ESPACIOS_APP.construir_espacio(_mundo, espacio)", DIA)
        self.assertIn("EspaciosCatalogo.de_fase(fase).duplicate(true)", ESPACIOS)
        self.assertIn("return Espacio3D.construir(mundo, espacio)", ESPACIOS)

    def test_wrappers_heredables_siguen_en_dia_app_y_subclases(self):
        self.assertIn("func _espacio_de(fase: String) -> Dictionary:", DIA)
        self.assertIn("func _entrar_en(fase: String) -> void:", DIA)
        for nombre, fuente in SUBCLASES.items():
            with self.subTest(subclase=nombre):
                self.assertIn("super._espacio_de(fase)", fuente)
                self.assertIn("super._entrar_en(fase)", fuente)

    def test_sueno_sigue_fuera_del_helper_base(self):
        resolver = bloque_funcion(ESPACIOS, "resolver_espacio_base")
        espacio_dia = bloque_funcion(DIA, "_espacio_de")
        self.assertIn('if fase != "sueño":', resolver)
        self.assertIn("return {}", resolver)
        for autoridad in (
            "SeleccionNocturna.opciones_sueno",
            "Sueno.noche(",
            "SuenoContenido.repartir(",
            "Sueno.recordar(",
            "SuenoLiteratura.aplicar(",
        ):
            self.assertIn(autoridad, espacio_dia)
            self.assertNotIn(autoridad, ESPACIOS)

    def test_mundo_existe_antes_de_resolver_construir_y_presentar(self):
        entrar = bloque_funcion(DIA, "_entrar_en")
        orden = (
            'jornada["fase"] = fase',
            "_mundo = Node3D.new()",
            "add_child(_mundo)",
            "var espacio := _espacio_de(fase)",
            "_espacio_actual = espacio",
            "DIA_ESPACIOS_APP.construir_espacio(_mundo, espacio)",
            "EcosDespertarRuntime",
            '_guardar_o_avisar("")',
        )
        posiciones = [entrar.index(token) for token in orden]
        self.assertEqual(posiciones, sorted(posiciones))

    def test_helper_no_absorbe_guardado_jornada_ni_transicion(self):
        for prohibido in (
            "Jornada.",
            "Partida.new(",
            "_guardar_o_avisar",
            "_reintentar_guardado",
            'jornada["fase"] =',
            "_entrar_en(",
            "EcosDespertarRuntime",
            "queue_free(",
        ):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, ESPACIOS)

        salida = bloque_funcion(DIA, "_al_pisar_salida")
        self.assertIn("Jornada.fichar_salida(jornada)", salida)
        self.assertIn("Jornada.dormir(jornada)", salida)
        self.assertIn("_entrar_en(destino)", salida)
        self.assertIn('_guardar_o_avisar("")', salida)

    def test_plantilla_base_conserva_identidad_y_contenido(self):
        for contrato in (
            "Companeros.plantilla(jornada[\"plantilla\"])",
            '"id_companero": String(quien.get("id", ""))',
            '"frase": Companeros.frase_de(quien, jornada["dia"])',
            '"modelo": Companeros.cuerpo_de(quien)',
            '"retrato": quien.get("retrato", "")',
        ):
            self.assertIn(contrato, ESPACIOS)


if __name__ == "__main__":
    unittest.main()
