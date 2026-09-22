from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ACUSACION = (ROOT / "godot/guion/acusacion.gd").read_text(encoding="utf-8")
PARTIDA = (ROOT / "godot/guion/partida.gd").read_text(encoding="utf-8")
DIA = (ROOT / "godot/guion/dia_app.gd").read_text(encoding="utf-8")
VISOR = (ROOT / "godot/guion/visor_sello_app.gd").read_text(encoding="utf-8")
UI = (ROOT / "godot/guion/ultimo_recurso_app.gd").read_text(encoding="utf-8")
PROMETEO = (ROOT / "godot/guion/prometeo.gd").read_text(encoding="utf-8")


def bloque(fuente: str, inicio: str, fin: str) -> str:
    i = fuente.index(inicio)
    j = fuente.index(fin, i)
    return fuente[i:j]


def test_cero_es_estado_persistente_y_no_reset() -> None:
    perder = bloque(
        ACUSACION,
        "static func perder_vida(",
        "## La frontera pendiente",
    )
    assert 'estado[CLAVE_DESPIDO_PENDIENTE] = true' in perder
    assert '"despido_pendiente": true' in perder
    assert '"vida": 0' in perder
    assert "reiniciar_vuelta" not in perder
    assert '"la-muerte"' not in perder

    assert '"despido_pendiente": false' in PARTIDA
    assert 'guardado.has("despido_pendiente")' in PARTIDA
    assert "for clave in fusionado:" in PARTIDA


def test_canje_es_unico_emisor_de_templanza_en_esta_frontera() -> None:
    canje = bloque(
        ACUSACION,
        "static func canjear_carta_por_vida(",
        "## Aceptar el cese",
    )
    assert 'elegida["gastada"] = true' in canje
    assert 'estado["vida"] = 1' in canje
    assert 'desbloquear_carta_en_estado(estado, "la-templanza")' in canje
    assert "reiniciar_vuelta" not in canje
    assert '"la-muerte"' not in canje

    # La sincronización del Mundo sigue excluyendo Templanza, pero no la crea.
    mundo = bloque(
        PROMETEO,
        "static func sincronizar_tarot_mundo(",
        "## Una acusación es precipitada",
    )
    assert '["el-mundo", "la-templanza"]' in mundo
    assert 'desbloquear_carta_en_estado(estado, "la-templanza")' not in mundo


def test_cese_es_la_unica_salida_que_reinicia_y_concede_muerte() -> None:
    cese = bloque(
        ACUSACION,
        "static func aceptar_cese(",
        "## Cierra el careo",
    )
    assert 'desbloquear_carta_en_estado(estado, "la-muerte")' in cese
    assert "EvaluacionDesempeno.sellar" in cese
    assert "Prometeo.reiniciar_vuelta" in cese
    assert "Jornada.reiniciar_vuelta" in cese
    assert cese.index('"la-muerte"') < cese.index("Prometeo.reiniciar_vuelta")


def test_ui_solo_solicita_y_delega_reglas_al_dominio() -> None:
    assert "signal canje_solicitado" in UI
    assert "signal cese_solicitado" in UI
    assert "Acusacion.cartas_canjeables(_estado)" in UI
    assert 'call_deferred("grab_focus")' in UI
    assert "canjear_carta_por_vida" not in UI
    assert "aceptar_cese" not in UI


def test_recarga_y_visor_recuperan_la_misma_decision() -> None:
    ready = bloque(DIA, "func _ready()", "## Recupera o presenta")
    assert "Acusacion.despido_pendiente(partida.estado)" in ready
    assert "_abrir_ultimo_recurso_pendiente()" in ready

    sello = bloque(VISOR, "func _al_terminar_sello(", "func _abrir_careo_firmado(")
    remate = bloque(VISOR, "func _al_terminar_remate(", "## La misma superficie")
    assert 'resultado.get("despido_pendiente", false)' in sello
    assert 'duelo.get("despido_pendiente", false)' in remate
    assert "_abrir_ultimo_recurso" in sello
    assert "_abrir_ultimo_recurso" in remate
