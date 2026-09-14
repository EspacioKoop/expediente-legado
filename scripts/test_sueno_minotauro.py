from collections import deque
from pathlib import Path
import re
import unittest


RAIZ = Path(__file__).resolve().parents[1]
MINOTAURO = RAIZ / "godot" / "guion" / "sueno_minotauro.gd"


class SuenoMinotauroTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = MINOTAURO.read_text(encoding="utf-8")
        cls.codigo = "\n".join(
            linea for linea in cls.texto.splitlines() if not linea.lstrip().startswith("#")
        )
        cls.constantes = dict(
            re.findall(r'^const\s+(\w+)\s*:=\s*"([^"]+)"', cls.texto, re.MULTILINE)
        )
        cls.grafo = cls._extraer_grafo()

    @classmethod
    def _extraer_grafo(cls):
        inicio = cls.texto.index("static var _vecinos := {")
        fin = cls.texto.index("\n}\n", inicio)
        bloque = cls.texto[inicio:fin]
        grafo = {}
        for nombre, vecinos in re.findall(r"^\s*(\w+): \[([^\]]*)\],$", bloque, re.MULTILINE):
            nodo = cls.constantes.get(nombre, nombre)
            grafo[nodo] = [
                cls.constantes.get(v.strip(), v.strip())
                for v in vecinos.split(",")
                if v.strip()
            ]
        return grafo

    @staticmethod
    def _hay_ruta(grafo, desde, hasta, bloqueado=""):
        if desde == bloqueado or hasta == bloqueado:
            return False
        pendientes = deque([desde])
        vistos = {desde}
        while pendientes:
            actual = pendientes.popleft()
            if actual == hasta:
                return True
            for vecino in grafo.get(actual, []):
                if vecino == bloqueado or vecino in vistos:
                    continue
                vistos.add(vecino)
                pendientes.append(vecino)
        return False

    def test_semilla_es_deliberada_y_tiene_helper_explicito(self):
        self.assertEqual(self.constantes["SEMILLA"], "semilla_onirica_minotauro")
        self.assertIn("static func habilitada(semillas: Dictionary)", self.texto)
        self.assertIn("static func registrar_semilla(semillas: Dictionary)", self.texto)
        self.assertIn("semillas[SEMILLA] = true", self.texto)

    def test_grafo_real_es_bidireccional_y_llega_a_salida(self):
        entrada = self.constantes["ENTRADA"]
        salida = self.constantes["SALIDA"]
        self.assertGreaterEqual(len(self.grafo), 8)
        self.assertTrue(self._hay_ruta(self.grafo, entrada, salida))
        for origen, vecinos in self.grafo.items():
            for destino in vecinos:
                self.assertIn(origen, self.grafo[destino], f"arista no reciproca {origen}->{destino}")

    def test_todos_los_bloqueos_que_el_minotauro_considera_conservan_ruta(self):
        entrada = self.constantes["ENTRADA"]
        salida = self.constantes["SALIDA"]
        candidatos = [
            self.constantes["ARCHIVO_RETORNO"],
            self.constantes["CRUCE_SUR"],
            self.constantes["ARCHIVO_ESTE"],
            self.constantes["CRUCE_NORTE"],
        ]
        for bloqueado in candidatos:
            self.assertTrue(
                self._hay_ruta(self.grafo, entrada, salida, bloqueado),
                f"el bloqueo de {bloqueado} produciria softlock desde entrada",
            )

    def test_runtime_verifica_ruta_antes_y_despues_de_bloquear(self):
        self.assertIn("if hay_ruta(nodo_actual, SALIDA, id):", self.texto)
        self.assertIn('"ruta_recuperable": hay_ruta(nodo_actual, SALIDA, bloqueo)', self.texto)
        self.assertIn('estado["bloqueo"] = bloqueo', self.texto)
        self.assertIn("static func liberar_bloqueo", self.texto)

    def test_marcas_se_anclan_a_topologia_real_y_pueden_reaparecer_desplazadas(self):
        self.assertIn("const MAX_MARCAS := 4", self.texto)
        self.assertIn("var real := nodo_real(nodo_aparente_id, fase)", self.texto)
        self.assertIn('"aparente_inicial": nodo_aparente_id', self.texto)
        self.assertIn("var aparece := nodo_aparente", self.texto)
        self.assertIn('"desplazada"', self.texto)

    def test_repliegue_es_biyectivo_y_determinista(self):
        self.assertIn("static func nodo_real", self.texto)
        self.assertIn("static func nodo_aparente", self.texto)
        self.assertGreaterEqual(self.texto.count("_intercambiar("), 5)
        for azar_global in ("randi()", "randf()", "randomize()"):
            self.assertNotIn(azar_global, self.codigo)

    def test_reduccion_movimiento_no_cambia_la_regla_espacial(self):
        self.assertIn("static func presentacion_transformacion", self.texto)
        self.assertIn('return "fundido_discreto" if reduccion_movimiento', self.texto)
        self.assertIn('"repliegue_continuo"', self.texto)

    def test_presencia_escala_sin_modelar_dano_ni_recompensas(self):
        self.assertIn('const PRESENCIAS := ["lejano", "respiracion", "cruce", "cerca"]', self.texto)
        self.assertIn("static func responder_minotauro", self.texto)
        for termino in (
            "pistas_descubiertas",
            "dinero",
            "veredicto",
            "recibir_dano",
            "hacer_dano",
            "Jornada.",
            "Partida.",
        ):
            self.assertNotIn(termino, self.codigo)

    def test_corte_sigue_standalone_sin_tocar_escenas_o_assets(self):
        for termino in ("load(", "preload(", "change_scene", "Espacio3D", "SuenoFormas"):
            self.assertNotIn(termino, self.codigo)


if __name__ == "__main__":
    unittest.main()
