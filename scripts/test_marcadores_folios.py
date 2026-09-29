import re
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CAPA = ROOT / "godot" / "guion" / "visor_anotaciones_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "visor.tscn"


def escena_script(escena: str) -> str:
    return re.search(r'type="Script" path="res://guion/([a-z_0-9]+\.gd)" id="1"', escena).group(1)


def heredan_de(guion: str, ancestro: str) -> bool:
    for _ in range(20):
        if guion == ancestro:
            return True
        texto = (ROOT / "godot" / "guion" / guion).read_text(encoding="utf-8")
        padre = re.search(r'^extends "res://guion/([a-z_0-9]+\.gd)"', texto, re.M)
        if padre is None:
            return False
        guion = padre.group(1)
    return False


def fuente() -> str:
    return CAPA.read_text(encoding="utf-8")


class MarcadoresFoliosTest(unittest.TestCase):
    def test_la_escena_activa_la_capa_sobre_combinaciones(self) -> None:
        texto = fuente()
        escena = ESCENA.read_text(encoding="utf-8")
        # La escena monta la capa superior; anotaciones entra por herencia transitiva
        # (visor.tscn → pronósticos → anexos → metadatos → anotaciones).
        assert heredan_de(escena_script(escena), "visor_anotaciones_app.gd")
        assert 'extends "res://guion/visor_combinaciones_app.gd"' in texto

    def test_solo_se_puede_marcar_un_folio_leido(self) -> None:
        texto = fuente()
        assert "not _esta_leido(registro_id)" in texto
        assert '_marcar.disabled = registro_id.is_empty() or not _esta_leido(registro_id)' in texto

    def test_marcar_y_desmarcar_es_idempotente(self) -> None:
        texto = fuente()
        assert "if marcadores.has(registro_id):" in texto
        assert "marcadores.erase(registro_id)" in texto
        assert "marcadores.append(registro_id)" in texto
        assert "_guardar_marcadores_del_caso(marcadores)" in texto

    def test_los_marcadores_se_aislan_por_caso_y_no_descubren_pistas(self) -> None:
        texto = fuente()
        assert 'const CLAVE_MARCADORES := "marcadores_folios"' in texto
        assert 'todos.get(String(caso["id"]), []).duplicate()' in texto
        assert 'var caso_id := String(caso["id"])' in texto
        assert "descubiertas.append" not in texto
        assert "_buscar_relacion" not in texto

    def test_el_estado_se_guarda_con_la_partida_existente(self) -> None:
        texto = fuente()
        assert "jornada[CLAVE_MARCADORES] = todos" in texto
        assert "_guardar_o_avisar()" in texto


if __name__ == "__main__":
    unittest.main()
