import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOGO = ROOT / "godot" / "datos" / "correo_corporativo.json"
MODELO = ROOT / "godot" / "guion" / "correo_siga_modelo.gd"
CLIENTE = ROOT / "godot" / "guion" / "correo_siga.gd"
ADAPTADOR = ROOT / "godot" / "guion" / "dia_escritorio_siga_app.gd"
COMPANEROS = ROOT / "godot" / "guion" / "companeros.gd"


def cargar_mensajes() -> list[dict]:
    return json.loads(CATALOGO.read_text(encoding="utf-8"))["mensajes"]


def entregados(
    mensajes: list[dict], dia: int, acciones: int, presentes: set[str]
) -> list[str]:
    ids: list[str] = []
    for mensaje in mensajes:
        dia_entrega = int(mensaje["dia_entrega"])
        if dia < dia_entrega:
            continue
        if dia == dia_entrega and acciones > int(mensaje["acciones_max"]):
            continue
        companero = mensaje.get("companero_id")
        if companero and companero not in presentes:
            continue
        ids.append(mensaje["id"])
    return ids


def test_catalogo_es_declarativo_y_tiene_ids_estables() -> None:
    mensajes = cargar_mensajes()
    assert len(mensajes) >= 12
    ids = [mensaje["id"] for mensaje in mensajes]
    assert len(ids) == len(set(ids))
    for mensaje in mensajes:
        assert mensaje["remitente"]
        assert mensaje["asunto"]
        assert mensaje["cuerpo"]
        assert re.fullmatch(r"\d\d:\d\d", mensaje["hora"])
        assert isinstance(mensaje["dia_entrega"], int)
        assert isinstance(mensaje["acciones_max"], int)
        assert mensaje["importancia_narrativa"] is False


def test_los_companeros_del_correo_existen_en_la_plantilla_real() -> None:
    fuente = COMPANEROS.read_text(encoding="utf-8")
    ids_reales = set(re.findall(r'"id": "([a-z0-9_]+)"', fuente))
    ids_correo = {
        mensaje["companero_id"]
        for mensaje in cargar_mensajes()
        if mensaje.get("companero_id")
    }
    assert ids_correo <= ids_reales
    assert "cunado" in ids_correo
    assert len(ids_correo) >= 8


def test_el_correo_aparece_segun_avanza_la_jornada() -> None:
    mensajes = cargar_mensajes()
    presentes = {"cunado", "becario", "telefono"}

    al_entrar = entregados(mensajes, dia=1, acciones=3, presentes=presentes)
    tras_una_accion = entregados(mensajes, dia=1, acciones=2, presentes=presentes)
    tarde = entregados(mensajes, dia=1, acciones=1, presentes=presentes)
    agotada = entregados(mensajes, dia=1, acciones=0, presentes=presentes)

    assert al_entrar == ["sistema-buzon-alta"]
    assert "cunado-asuntos-mayusculas" in tras_una_accion
    assert "telefono-centralita" in tras_una_accion
    assert "becario-listado" not in tras_una_accion
    assert "becario-listado" in tarde
    assert "spam-modem-56k" in tarde
    assert "sistema-cierre-dia1" not in tarde
    assert "sistema-cierre-dia1" in agotada


def test_un_mensaje_entregado_no_desaparece_al_dia_siguiente() -> None:
    mensajes = cargar_mensajes()
    presentes = {"cunado", "becario", "telefono"}
    dia_dos = entregados(mensajes, dia=2, acciones=3, presentes=presentes)
    assert "sistema-cierre-dia1" in dia_dos
    assert "rrhh-formacion" in dia_dos


def test_no_entran_correos_de_companeros_que_no_estan_en_esta_vuelta() -> None:
    mensajes = cargar_mensajes()
    presentes = {"cunado", "becario", "telefono"}
    dia_tres = entregados(mensajes, dia=3, acciones=0, presentes=presentes)
    assert "emperador-orden-carpetas" not in dia_tres
    assert "riegos-consulta" not in dia_tres
    assert "fielato-sueno" not in dia_tres


def test_modelo_no_depende_del_reloj_real() -> None:
    fuente = MODELO.read_text(encoding="utf-8")
    assert "Jornada.ACCIONES_POR_DIA" in fuente
    assert '"acciones"' in fuente
    assert '"dia"' in fuente
    assert "Time.get_" not in fuente
    assert "OS.get_" not in fuente
    assert "_corresponde_a_plantilla" in fuente


def test_cliente_marca_no_leidos_sin_depender_solo_del_color() -> None:
    fuente = CLIENTE.read_text(encoding="utf-8")
    assert '"[NUEVO] "' in fuente
    assert "item_selected.connect" in fuente
    assert "signal mensaje_leido" in fuente
    assert "selection_enabled = true" in fuente


def test_adaptador_registra_correo_y_persiste_solo_leidos() -> None:
    fuente = ADAPTADOR.read_text(encoding="utf-8")
    assert 'EscritorioSigaApp.new(\n\t\t"correo", "Correo interno"' in fuente
    assert '_correo_app.persistir_estado = true' in fuente
    assert '_correo_app.establecer_estado_local("leidos", leidos)' in fuente
    assert "Companeros.plantilla" in fuente
    assert "correo.configurar_contexto(dia.jornada, presentes)" in fuente
