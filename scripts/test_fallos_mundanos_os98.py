from pathlib import Path

from scripts.godot_pruebas import ejecutar_script

ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "guion" / "fallos_mundanos_os98.gd"
PRUEBA_GODOT = "pruebas/pruebas_fallos_mundanos_os98.gd"


def fuente(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_declara_fallos_reproducibles_con_causa_resolucion_y_salida_segura() -> None:
    modelo = fuente(MODELO)
    for fallo_id in (
        "acceso_directo_roto",
        "formato_no_reconocido",
        "shareware_expirado",
        "residente_simulado",
        "medio_solo_lectura",
        "medio_retirado",
        "cache_desactualizada",
    ):
        assert f'"id": "{fallo_id}"' in modelo
    for campo in (
        '"causa"',
        '"resolucion"',
        '"salida_segura"',
        '"regla_normal"',
        '"fixture_anomalo"',
    ):
        assert modelo.count(campo) >= 7


def test_reutiliza_superficies_existentes_de_663_664_y_667() -> None:
    modelo = fuente(MODELO)
    assert modelo.count('"superficie": "software"') >= 2
    assert modelo.count('"superficie": "medios"') >= 2
    assert '"superficie": "web98"' in modelo
    for referencia in ("#663", "#664", "#667"):
        assert referencia in modelo


def test_fixture_anomalo_es_explicito_y_no_usa_azar() -> None:
    modelo = fuente(MODELO)
    assert 'contexto.get("fixture_anomalo", "")' in modelo
    assert "ESTADO_FIXTURE_ANOMALO" in modelo
    assert '"viola_regla": viola_regla' in modelo
    for prohibido in ("rand", "RandomNumberGenerator", "randi", "randf"):
        assert prohibido not in modelo


def test_seguridad_no_toca_host_red_procesos_ni_partida() -> None:
    modelo = fuente(MODELO)
    for prohibido in (
        "FileAccess",
        "DirAccess",
        "OS.execute",
        "OS.create_process",
        "HTTPRequest",
        "HTTPClient",
        "StreamPeerTCP",
        "PacketPeerUDP",
        "Partida",
        "guardar(",
    ):
        assert prohibido not in modelo


def test_contrato_ejecutable_en_godot() -> None:
    resultado = ejecutar_script(PRUEBA_GODOT)
    assert resultado.returncode == 0, resultado.stdout
    assert "0 fallos" in resultado.stdout
    assert "Parse Error:" not in resultado.stdout
    assert "SCRIPT ERROR:" not in resultado.stdout
