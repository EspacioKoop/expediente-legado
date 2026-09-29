import os
from pathlib import Path
import subprocess

from scripts.godot_pruebas import importar_proyecto
import unittest


ROOT = Path(__file__).resolve().parents[1]
METRICAS = ROOT / "godot" / "guion" / "catalogo_vida_metricas.gd"
JORNADA = ROOT / "godot" / "guion" / "jornada.gd"
VISOR = ROOT / "godot" / "guion" / "visor_combinaciones_app.gd"
ACUSACION = ROOT / "godot" / "guion" / "acusacion.gd"
PARTIDA = ROOT / "godot" / "guion" / "partida.gd"
PRUEBA = "pruebas/pruebas_catalogo_vida_91.gd"


def fuente(path: Path) -> str:
    return path.read_text(encoding="utf-8")


class CatalogoVida91Test(unittest.TestCase):
    def test_metricas_no_activan_seleccion_de_catalogo(self) -> None:
        codigo = fuente(METRICAS)
        assert "class_name CatalogoVidaMetricas" in codigo
        assert '"casos_disponibles"' in codigo
        assert '"casos_abiertos"' in codigo
        assert '"casos_resueltos"' in codigo
        for prohibido in (
            "RandomNumberGenerator",
            "randf(",
            "randi(",
            "HTTPRequest",
            "HTTPClient",
            "ocultar",
            "seleccionar_casos",
        ):
            assert prohibido not in codigo

    def test_runtime_registra_solo_en_fronteras_reales(self) -> None:
        visor = fuente(VISOR)
        acusacion = fuente(ACUSACION)
        assert "CatalogoVidaMetricas.sincronizar_disponibles(jornada, contenido.casos)" in visor
        assert "CatalogoVidaMetricas.registrar_abierto(" in visor
        assert "CatalogoVidaMetricas.registrar_resuelto(jornada, caso_id)" in acusacion
        assert 'veredictos[caso_id] = sospechoso["id"]' in acusacion
        assert acusacion.index('veredictos[caso_id] = sospechoso["id"]') < acusacion.index(
            "CatalogoVidaMetricas.registrar_resuelto(jornada, caso_id)"
        )

    def test_reasignacion_archiva_una_sola_vida_y_reinicia_actual(self) -> None:
        jornada = fuente(JORNADA)
        assert "CatalogoVidaMetricas.snapshot(jornada)" in jornada
        assert "nueva_vida[CatalogoVidaMetricas.CLAVE_ANTERIOR] = metricas_anteriores" in jornada
        assert "CatalogoVidaMetricas.CLAVE_ACTUAL: CatalogoVidaMetricas.nueva(vuelta)" in jornada
        assert '"leidos_total": []' in jornada

    def test_guardado_valida_forma_sin_subir_version_global(self) -> None:
        partida = fuente(PARTIDA)
        assert "CatalogoVidaMetricas.validar(" in partida
        assert 'for clave in ["leido_hoy", "leidos_total", "mapa", "sueno_escenas", "mapa_anoche"]' in partida
        assert "const VERSION := 1" in partida

    def test_regresion_ejecutable_en_godot(self) -> None:
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        assert resultado.returncode == 0, resultado.stdout
        assert "0 fallos" in resultado.stdout
        assert "Parse Error:" not in resultado.stdout
        assert "SCRIPT ERROR:" not in resultado.stdout


if __name__ == "__main__":
    unittest.main()
