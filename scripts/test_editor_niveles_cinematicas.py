#!/usr/bin/env python3
"""Pruebas para editor_niveles_cinematicas: roundtrip, versionado, errores, rutas, schemas."""

import json
import os
import sys
import tempfile
import subprocess
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
GODOT = os.environ.get("GODOT_BIN", "godot4")


def godot_headless(script_path: str, args=None, timeout=60, env=None):
    """Ejecuta un script GDScript en modo headless y retorna stdout."""
    cmd = [GODOT, "--headless", "--language", "es", "--path", str(RAIZ / "godot"), "--script", script_path]
    if args:
        cmd.extend(args)
    e = os.environ.copy()
    if env:
        e.update(env)
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, env=e, check=False)
    return result.returncode, result.stdout, result.stderr


def probar_gdscript_syntax():
    code, out, err = godot_headless("debug/editor_niveles_cinematicas.gd", ["--check-only"])
    if code != 0:
        raise AssertionError("Syntax check failed:\n{}\n{}".format(out, err))
    print("OK: GDScript syntax OK")


def probar_validar_nivel_valido():
    script = r'''
extends SceneTree

func _init():
    var editor = load("res://debug/editor_niveles_cinematicas.gd").new()
    var nivel = {
        "tipo": "nivel",
        "id": "test-nivel-01",
        "version": "1",
        "fase": "archivo",
        "colocaciones": [
            {"tipo": "bulto", "id": "mesa-1", "recurso": "desk", "transform": {"posicion": [0,0,0], "rotacion": [0,0,0], "escala": [1,1,1]}},
            {"tipo": "modelo", "id": "caja-catalogada", "recurso": "cardboardBoxClosed", "origen": "catalogo", "transform": {"posicion": [0,0,0], "rotacion": [0,0,0], "escala": [1,1,1]}},
            {"tipo": "salida", "id": "puerta-1", "recurso": "", "transform": {"posicion": [5,0,0], "rotacion": [0,0,0], "escala": [1,1,1]}, "extra": {"destino": "trayecto", "rotulo": "SALIDA"}}
        ]
    }
    var errores = editor.validar_nivel(nivel)
    if errores.size() > 0:
        print("ERROR: " + ", ".join(errores))
        quit(1)
    print("OK: nivel valido")
    quit(0)
'''
    with tempfile.NamedTemporaryFile(mode='w', suffix='.gd', delete=False) as f:
        f.write(script)
        script_path = f.name
    try:
        code, out, err = godot_headless(script_path)
        if code != 0:
            raise AssertionError("Validación nivel válido falló:\n{}\n{}".format(out, err))
        assert "OK: nivel valido" in out
        print("OK: validar_nivel acepta nivel válido")
    finally:
        os.unlink(script_path)


def probar_validar_nivel_invalido():
    script = r'''
extends SceneTree

func _init():
    var editor = load("res://debug/editor_niveles_cinematicas.gd").new()

    # Falta id
    var nivel1 = {"tipo": "nivel", "version": "1", "fase": "archivo", "colocaciones": []}
    var e1 = editor.validar_nivel(nivel1)
    if e1.size() == 0 or not "Falta id" in e1[0]:
        print("ERROR: Debe fallar por falta de id")
        quit(1)

    # Fase desconocida
    var nivel2 = {"tipo": "nivel", "id": "test", "version": "1", "fase": "inexistente", "colocaciones": []}
    var e2 = editor.validar_nivel(nivel2)
    if e2.size() == 0 or not "Fase desconocida" in e2[0]:
        print("ERROR: Debe fallar por fase desconocida")
        quit(1)

    # Colocación sin tipo
    var nivel3 = {"tipo": "nivel", "id": "test", "version": "1", "fase": "archivo", "colocaciones": [{"id": "x", "recurso": "desk"}]}
    var e3 = editor.validar_nivel(nivel3)
    if e3.size() == 0 or not "falta tipo" in e3[0]:
        print("ERROR: Debe fallar por colocación sin tipo")
        quit(1)

    # Tipo recurso desconocido
    var nivel4 = {"tipo": "nivel", "id": "test", "version": "1", "fase": "archivo", "colocaciones": [{"tipo": "inventado", "id": "x", "recurso": "desk"}]}
    var e4 = editor.validar_nivel(nivel4)
    if e4.size() == 0 or not "tipo de recurso desconocido" in e4[0]:
        print("ERROR: Debe fallar por tipo recurso desconocido")
        quit(1)

    # ID con caracteres inválidos
    var nivel5 = {"tipo": "nivel", "id": "test/../malo", "version": "1", "fase": "archivo", "colocaciones": []}
    var e5 = editor.validar_nivel(nivel5)
    if e5.size() == 0 or not "caracteres no válidos" in e5[0]:
        print("ERROR: Debe fallar por ID con ruta")
        quit(1)

    # Un modelo inexistente debe seguir rechazándose
    var nivel6 = {"tipo": "nivel", "id": "test", "version": "1", "fase": "archivo", "colocaciones": [{"tipo": "modelo", "id": "fantasma", "recurso": "__modelo_inexistente__", "origen": "catalogo"}]}
    var e6 = editor.validar_nivel(nivel6)
    var modelo_rechazado = false
    for error in e6:
        if "falta el recurso de modelo" in error:
            modelo_rechazado = true
    if not modelo_rechazado:
        print("ERROR: Debe fallar por modelo inexistente")
        quit(1)

    print("OK: validaciones de nivel inválido pasan")
    quit(0)
'''
    with tempfile.NamedTemporaryFile(mode='w', suffix='.gd', delete=False) as f:
        f.write(script)
        script_path = f.name
    try:
        code, out, err = godot_headless(script_path)
        if code != 0:
            raise AssertionError("Validación nivel inválido falló:\n{}\n{}".format(out, err))
        assert "OK: validaciones de nivel inválido pasan" in out
        print("OK: validar_nivel rechaza niveles inválidos")
    finally:
        os.unlink(script_path)


def probar_validar_cinematica_valida():
    script = r'''
extends SceneTree

func _init():
    var editor = load("res://debug/editor_niveles_cinematicas.gd").new()
    var cine = {
        "tipo": "cinematica",
        "id": "test-cine-01",
        "version": "1",
        "planos": [
            {"tipo": "3d", "segundos": 2.5, "rotulo": "PLANO_1", "voz": "VOZ_1", "camara": [0, 2, 5], "mira": [0, 1, 0]},
            {"tipo": "2d", "segundos": 1.0, "rotulo": "SELLO", "figura": [{"rect": {"x": -1, "y": -1, "width": 2, "height": 2}, "color": [1,1,1,1]}], "desde": [0,0], "hasta": [10,0]}
        ]
    }
    cine["planos"][0]["decorado"] = load("res://debug/editor_niveles_cinematicas_contrato.gd").escenario_catalogado_json("archivo")
    var errores = editor.validar_cinematica(cine)
    if errores.size() > 0:
        print("ERROR: " + ", ".join(errores))
        quit(1)
    print("OK: cinematica valida")
    quit(0)
'''
    with tempfile.NamedTemporaryFile(mode='w', suffix='.gd', delete=False) as f:
        f.write(script)
        script_path = f.name
    try:
        code, out, err = godot_headless(script_path)
        if code != 0:
            raise AssertionError("Validación cinemática válida falló:\n{}\n{}".format(out, err))
        assert "OK: cinematica valida" in out
        print("OK: validar_cinematica acepta cinemática válida")
    finally:
        os.unlink(script_path)


def probar_validar_cinematica_invalida():
    script = r'''
extends SceneTree

func _init():
    var editor = load("res://debug/editor_niveles_cinematicas.gd").new()

    # Sin planos
    var c1 = {"tipo": "cinematica", "id": "test", "version": "1", "planos": []}
    var e1 = editor.validar_cinematica(c1)
    if e1.size() == 0 or not "al menos un plano" in e1[0]:
        print("ERROR: Debe fallar sin planos")
        quit(1)

    # Plano sin duración
    var c2 = {"tipo": "cinematica", "id": "test", "version": "1", "planos": [{"tipo": "3d", "segundos": 0, "camara": [0,0,0], "mira": [0,0,0]}]}
    var e2 = editor.validar_cinematica(c2)
    if e2.size() == 0 or not "duración debe ser > 0" in e2[0]:
        print("ERROR: Debe fallar por duración <= 0")
        quit(1)

    # Plano 3D sin cámara
    var c3 = {"tipo": "cinematica", "id": "test", "version": "1", "planos": [{"tipo": "3d", "segundos": 1, "mira": [0,0,0]}]}
    var e3 = editor.validar_cinematica(c3)
    if e3.size() == 0 or not "sin camara" in e3[0]:
        print("ERROR: Debe fallar por falta cámara")
        quit(1)

    # Plano 2D sin figura
    var c4 = {"tipo": "cinematica", "id": "test", "version": "1", "planos": [{"tipo": "2d", "segundos": 1}]}
    var e4 = editor.validar_cinematica(c4)
    if e4.size() == 0 or not "2d sin figura" in e4[0]:
        print("ERROR: Debe fallar por falta figura")
        quit(1)

    # Un decorado no puede guardar referencias a modelos que no existen
    var c5 = {"tipo": "cinematica", "id": "test", "version": "1", "planos": [{"tipo": "3d", "segundos": 1, "camara": [0,0,0], "mira": [0,0,0], "decorado": {"bultos": [{"modelo": "__modelo_inexistente__"}]}}]}
    var e5 = editor.validar_cinematica(c5)
    var referencia_rechazada = false
    for error in e5:
        if "falta el recurso de modelo" in error:
            referencia_rechazada = true
    if not referencia_rechazada:
        print("ERROR: Debe rechazar un modelo inexistente en el decorado")
        quit(1)
        return

    print("OK: validaciones de cinematica inválida pasan")
    quit(0)
'''
    with tempfile.NamedTemporaryFile(mode='w', suffix='.gd', delete=False) as f:
        f.write(script)
        script_path = f.name
    try:
        code, out, err = godot_headless(script_path)
        if code != 0:
            raise AssertionError("Validación cinemática inválida falló:\n{}\n{}".format(out, err))
        assert "OK: validaciones de cinematica inválida pasan" in out
        print("OK: validar_cinematica rechaza cinemáticas inválidas")
    finally:
        os.unlink(script_path)


def probar_roundtrip_nivel():
    with tempfile.TemporaryDirectory() as tmpdir:
        script_content = '''extends SceneTree

func _init():
    OS.set_environment("XDG_DATA_HOME", "DATA_DIR/datos")
    OS.set_environment("XDG_CONFIG_HOME", "DATA_DIR/config")
    OS.set_environment("XDG_CACHE_HOME", "DATA_DIR/cache")

    var editor = load("res://debug/editor_niveles_cinematicas.gd").new()
    var nivel = {
        "tipo": "nivel",
        "id": "roundtrip-nivel",
        "version": "1",
        "fase": "casa",
        "colocaciones": [
            {"tipo": "bulto", "id": "cama", "recurso": "bed", "transform": {"posicion": [-2, 0, -2], "rotacion": [0,0,0], "escala": [1,1,1]}, "extra": {"color": [0.4, 0.3, 0.3]}},
            {"tipo": "salida", "id": "dormir", "recurso": "", "transform": {"posicion": [-2, 0, -2], "rotacion": [0,0,0], "escala": [1,1,1]}, "extra": {"destino": "sueño", "rotulo": "DORMIR", "tam": [1.6, 1.2, 2.4]}}
        ]
    }

    # Guardar via paquete_nivel
    var paquete = editor.paquete_nivel(nivel)
    var ruta = "DATA_DIR/datos/editor_niveles_cinematicas/roundtrip-nivel.json"
    DirAccess.make_dir_recursive_absolute("DATA_DIR/datos/editor_niveles_cinematicas")
    var f = FileAccess.open(ruta, FileAccess.WRITE)
    f.store_string(JSON.stringify(paquete, "  "))
    f.close()

    # Cargar via datos_desde_paquete
    var f2 = FileAccess.open(ruta, FileAccess.READ)
    var text = f2.get_as_text()
    f2.close()
    var paquete2 = JSON.parse_string(text)
    var cargado = editor.datos_desde_paquete(paquete2)

    if cargado.is_empty():
        print("ERROR: datos_desde_paquete devolvió vacío")
        quit(1)
    if cargado.id != "roundtrip-nivel":
        print("ERROR: id no coincide: " + cargado.id)
        quit(1)
    if cargado.fase != "casa":
        print("ERROR: fase no coincide: " + cargado.fase)
        quit(1)
    if cargado.colocaciones.size() != 2:
        print("ERROR: colocaciones count: " + str(cargado.colocaciones.size()))
        quit(1)
    if cargado.colocaciones[0].id != "cama":
        print("ERROR: primera colocación id: " + cargado.colocaciones[0].id)
        quit(1)
    if cargado.colocaciones[1].extra.destino != "sueño":
        print("ERROR: extra no conservado")
        quit(1)

    print("OK: roundtrip nivel")
    quit(0)
'''
        script_content = script_content.replace("DATA_DIR", tmpdir)
        with tempfile.NamedTemporaryFile(mode='w', suffix='.gd', delete=False) as f:
            f.write(script_content)
            script_path = f.name
        try:
            code, out, err = godot_headless(script_path, timeout=60)
            if code != 0:
                raise AssertionError("Roundtrip nivel falló:\n{}\n{}".format(out, err))
            assert "OK: roundtrip nivel" in out
            print("OK: Roundtrip nivel (guardar/cargar) funciona")
        finally:
            os.unlink(script_path)


def probar_roundtrip_cinematica():
    with tempfile.TemporaryDirectory() as tmpdir:
        script_content = '''extends SceneTree

func _init():
    OS.set_environment("XDG_DATA_HOME", "DATA_DIR/datos")
    OS.set_environment("XDG_CONFIG_HOME", "DATA_DIR/config")
    OS.set_environment("XDG_CACHE_HOME", "DATA_DIR/cache")

    var editor = load("res://debug/editor_niveles_cinematicas.gd").new()
    var cine = {
        "tipo": "cinematica",
        "id": "roundtrip-cine",
        "version": "1",
        "planos": [
            {"tipo": "3d", "segundos": 3.0, "rotulo": "INTRO", "voz": "NARRADOR", "camara": [0, 2, 10], "mira": [0, 1, 0], "camara_desde": [0, 2, 15], "mira_desde": [0, 1, 0], "fov": 45, "foco": 5.0},
            {"tipo": "2d", "segundos": 2.0, "rotulo": "SELLO", "figura": [{"rect": {"x": -2, "y": -1, "width": 4, "height": 2}, "color": [1, 0.8, 0.2, 1]}], "desde": [0, 0], "hasta": [50, 0], "sonido": "sello_stamp", "sonido_tono": 1.2},
            {"tipo": "3d", "segundos": 1.5, "rotulo": "FIN", "camara": [0, 1.5, 3], "mira": [0, 1, 0], "fundido_desde": 0.0, "fundido_hasta": 1.0}
        ]
    }

    var paquete = editor.paquete_cinematica(cine)
    var ruta = "DATA_DIR/datos/editor_niveles_cinematicas/roundtrip-cine.json"
    DirAccess.make_dir_recursive_absolute("DATA_DIR/datos/editor_niveles_cinematicas")
    var f = FileAccess.open(ruta, FileAccess.WRITE)
    f.store_string(JSON.stringify(paquete, "  "))
    f.close()

    var f2 = FileAccess.open(ruta, FileAccess.READ)
    var text = f2.get_as_text()
    f2.close()
    var paquete2 = JSON.parse_string(text)
    var cargado = editor.datos_desde_paquete(paquete2)

    if cargado.is_empty():
        print("ERROR: datos_desde_paquete devolvió vacío")
        quit(1)
    if cargado.id != "roundtrip-cine":
        print("ERROR: id no coincide: " + cargado.id)
        quit(1)
    if cargado.planos.size() != 3:
        print("ERROR: planos count: " + str(cargado.planos.size()))
        quit(1)
    if cargado.planos[0].tipo != "3d" or cargado.planos[0].fov != 45:
        print("ERROR: plano 0 no conservado")
        quit(1)
    if cargado.planos[1].tipo != "2d" or cargado.planos[1].sonido != "sello_stamp":
        print("ERROR: plano 1 no conservado")
        quit(1)
    if cargado.planos[2].fundido_hasta != 1.0:
        print("ERROR: fundido no conservado")
        quit(1)

    print("OK: roundtrip cinematica")
    quit(0)
'''
        script_content = script_content.replace("DATA_DIR", tmpdir)
        with tempfile.NamedTemporaryFile(mode='w', suffix='.gd', delete=False) as f:
            f.write(script_content)
            script_path = f.name
        try:
            code, out, err = godot_headless(script_path, timeout=60)
            if code != 0:
                raise AssertionError("Roundtrip cinemática falló:\n{}\n{}".format(out, err))
            assert "OK: roundtrip cinematica" in out
            print("OK: Roundtrip cinemática (guardar/cargar) funciona")
        finally:
            os.unlink(script_path)


def probar_formato_versionado():
    with tempfile.TemporaryDirectory() as tmpdir:
        script_content = '''extends SceneTree

func _init():
    OS.set_environment("XDG_DATA_HOME", "DATA_DIR/datos")
    OS.set_environment("XDG_CONFIG_HOME", "DATA_DIR/config")
    OS.set_environment("XDG_CACHE_HOME", "DATA_DIR/cache")

    var editor = load("res://debug/editor_niveles_cinematicas.gd").new()

    # Nivel
    var nivel = {"tipo": "nivel", "id": "fmt-nivel", "version": "1", "fase": "archivo", "colocaciones": []}
    var pn = editor.paquete_nivel(nivel)
    if pn.formato != "siga98-nivel-v1":
        print("ERROR: formato nivel incorrecto: " + pn.formato)
        quit(1)
    if not pn.documento.id == "fmt-nivel":
        print("ERROR: documento no en paquete")
        quit(1)

    # Cinemática
    var cine = {"tipo": "cinematica", "id": "fmt-cine", "version": "1", "planos": [{"tipo": "3d", "segundos": 1, "camara": [0,0,0], "mira": [0,0,1]}]}
    var pc = editor.paquete_cinematica(cine)
    if pc.formato != "siga98-cinematica-v1":
        print("ERROR: formato cinematica incorrecto: " + pc.formato)
        quit(1)

    # JSON legible (indentado)
    var json_str = JSON.stringify(pn, "  ")
    var parsed = JSON.parse_string(json_str)
    if not parsed.formato == "siga98-nivel-v1":
        print("ERROR: JSON no redondo")
        quit(1)

    print("OK: formato versionado y legible")
    quit(0)
'''
        script_content = script_content.replace("DATA_DIR", tmpdir)
        with tempfile.NamedTemporaryFile(mode='w', suffix='.gd', delete=False) as f:
            f.write(script_content)
            script_path = f.name
        try:
            code, out, err = godot_headless(script_path, timeout=60)
            if code != 0:
                raise AssertionError("Formato versionado falló:\n{}\n{}".format(out, err))
            assert "OK: formato versionado y legible" in out
            print("OK: Formato versionado (siga98-nivel-v1, siga98-cinematica-v1) y JSON legible")
        finally:
            os.unlink(script_path)


def probar_carga_invalida_no_sobrescribe():
    script = r'''
extends SceneTree

func _init():
    var editor = load("res://debug/editor_niveles_cinematicas.gd").new()

    # JSON con formato desconocido
    var paquete_malo = {"formato": "otro-formato", "documento": {"id": "test"}}
    var r1 = editor.datos_desde_paquete(paquete_malo)
    if not r1.is_empty():
        print("ERROR: Debe devolver vacío para formato desconocido")
        quit(1)

    # JSON sin documento
    var paquete_malo2 = {"formato": "siga98-nivel-v1"}
    var r2 = editor.datos_desde_paquete(paquete_malo2)
    if not r2.is_empty():
        print("ERROR: Debe devolver vacío sin documento")
        quit(1)

    # JSON no es dict
    var paquete_malo3 = "no es dict"
    var r3 = editor.datos_desde_paquete(paquete_malo3)
    if not r3.is_empty():
        print("ERROR: Debe devolver vacío para no-dict")
        quit(1)

    print("OK: carga inválida no corrompe")
    quit(0)
'''
    with tempfile.NamedTemporaryFile(mode='w', suffix='.gd', delete=False) as f:
        f.write(script)
        script_path = f.name
    try:
        code, out, err = godot_headless(script_path)
        if code != 0:
            raise AssertionError("Carga inválida falló:\n{}\n{}".format(out, err))
        assert "OK: carga inválida no corrompe" in out
        print("OK: Carga inválida no sobrescribe ni corrompe")
    finally:
        os.unlink(script_path)


def probar_rutas_seguras():
    script = r'''
extends SceneTree

func _init():
    var editor = load("res://debug/editor_niveles_cinematicas.gd").new()

    var malos = []
    malos.append("../escape")
    malos.append("subdir/archivo")
    malos.append("con:dos")
    malos.append("con*asterisco")
    malos.append("con?pregunta")
    malos.append("con\"comilla")
    malos.append("con<menor")
    malos.append("con>mayor")
    malos.append("con|pipe")

    for malo in malos:
        var nivel = {"tipo": "nivel", "id": malo, "version": "1", "fase": "archivo", "colocaciones": []}
        var errores = editor.validar_nivel(nivel)
        if errores.size() == 0 or not "caracteres no válidos" in errores[0]:
            print("ERROR: ID malo aceptado: " + malo)
            quit(1)

    # ID válido
    var nivel_ok = {"tipo": "nivel", "id": "valido-123_abc", "version": "1", "fase": "archivo", "colocaciones": []}
    var errores_ok = editor.validar_nivel(nivel_ok)
    if errores_ok.size() > 0:
        print("ERROR: ID válido rechazado: " + ", ".join(errores_ok))
        quit(1)

    print("OK: rutas seguras validadas")
    quit(0)
'''
    with tempfile.NamedTemporaryFile(mode='w', suffix='.gd', delete=False) as f:
        f.write(script)
        script_path = f.name
    try:
        code, out, err = godot_headless(script_path)
        if code != 0:
            raise AssertionError("Rutas seguras falló:\n{}\n{}".format(out, err))
        assert "OK: rutas seguras validadas" in out
        print("OK: IDs con rutas/escape son rechazados; IDs válidos aceptados")
    finally:
        os.unlink(script_path)


def probar_cinematica_validar_integracion():
    script = r'''
extends SceneTree

func _init():
    var editor = load("res://debug/editor_niveles_cinematicas.gd").new()
    var cinematica_mod = load("res://guion/cinematica.gd")

    # La validación del editor debe ser consistente con Cinematica.validar
    var planos = []
    planos.append({"tipo": "3d", "segundos": 1.0, "camara": [0,0,0], "mira": [0,0,1]})
    planos.append({"tipo": "2d", "segundos": 1.0, "figura": [{"rect": {"x":0,"y":0,"width":1,"height":1}, "color": [1,1,1,1]}]})

    var errores_editor = editor.validar_cinematica({"tipo": "cinematica", "id": "test", "version": "1", "planos": planos})
    var errores_cinematica = cinematica_mod.validar(planos)

    # Ambos deben estar de acuerdo en validez básica
    if (errores_editor.is_empty()) != (errores_cinematica.is_empty()):
        print("ERROR: discrepancia validación editor vs Cinematica.validar")
        print("Editor: " + str(errores_editor))
        print("Cinematica: " + str(errores_cinematica))
        quit(1)

    print("OK: validación consistente con Cinematica.validar")
    quit(0)
'''
    with tempfile.NamedTemporaryFile(mode='w', suffix='.gd', delete=False) as f:
        f.write(script)
        script_path = f.name
    try:
        code, out, err = godot_headless(script_path)
        if code != 0:
            raise AssertionError("Integración Cinematica.validar falló:\n{}\n{}".format(out, err))
        assert "OK: validación consistente con Cinematica.validar" in out
        print("OK: validar_cinematica consistente con Cinematica.validar(planos)")
    finally:
        os.unlink(script_path)


def probar_persistencia_user_dir():
    script = r'''
extends SceneTree

func _init():
    var editor = load("res://debug/editor_niveles_cinematicas.gd").new()

    # Verificar que la constante DIRECTORIO usa user://
    var script_src = FileAccess.open("res://debug/editor_niveles_cinematicas.gd", FileAccess.READ).get_as_text()
    if "user://editor_niveles_cinematicas" not in script_src:
        print("ERROR: DIRECTORIO no usa user://")
        quit(1)
    if "res://editor_niveles_cinematicas" in script_src:
        print("ERROR: DIRECTORIO usa res:// incorrectamente")
        quit(1)

    print("OK: persistencia en user://")
    quit(0)
'''
    with tempfile.NamedTemporaryFile(mode='w', suffix='.gd', delete=False) as f:
        f.write(script)
        script_path = f.name
    try:
        code, out, err = godot_headless(script_path)
        if code != 0:
            raise AssertionError("Persistencia user:// falló:\n{}\n{}".format(out, err))
        assert "OK: persistencia en user://" in out
        print("OK: Persistencia usa user:// exclusivamente")
    finally:
        os.unlink(script_path)


def probar_solo_debug_qa():
    script = r'''
extends SceneTree

func _init():
    var cargador = load("res://guion/cargador_consola_depuracion.gd").new()
    var script_src = FileAccess.open("res://guion/cargador_consola_depuracion.gd", FileAccess.READ).get_as_text()

    # Debe comprobar OS.is_debug_build() o feature qa_tools
    if "is_debug_build" not in script_src and "qa_tools" not in script_src:
        print("ERROR: cargador no verifica debug/QA")
        quit(1)

    # Debe haber flag para editor_niveles_cinematicas
    if "EDITOR_NIVELES_CINEMATICAS" not in script_src:
        print("ERROR: no hay flag de entorno para editor_niveles_cinematicas")
        quit(1)

    print("OK: solo debug/QA")
    quit(0)
'''
    with tempfile.NamedTemporaryFile(mode='w', suffix='.gd', delete=False) as f:
        f.write(script)
        script_path = f.name
    try:
        code, out, err = godot_headless(script_path)
        if code != 0:
            raise AssertionError("Solo debug/QA falló:\n{}\n{}".format(out, err))
        assert "OK: solo debug/QA" in out
        print("OK: Editor solo activable en debug/QA via flag entorno")
    finally:
        os.unlink(script_path)


def probar_escena_editor_runtime():
    script = r'''
extends SceneTree

func _init():
    call_deferred("_probar")

func _probar():
    var escena = load("res://escenas/editor_niveles_cinematicas.tscn")
    if escena == null:
        push_error("No carga la escena del editor")
        quit(1)
        return
    var editor = escena.instantiate()
    root.add_child(editor)
    await process_frame
    if editor.get("_fase") == null or editor.get("_tipo_doc") == null:
        push_error("La UI no montó sus controles")
        quit(1)
        return
    var id = "smoke_" + str(Time.get_ticks_usec())
    var contrato = load("res://debug/editor_niveles_cinematicas_contrato.gd")
    var decorado_archivo = contrato.escenario_catalogado_json("archivo")
    if decorado_archivo.is_empty() or not decorado_archivo.get("bultos", [])[0].get("pos") is Array:
        push_error("El catálogo no produce un decorado serializable para cinemática")
        quit(1)
        return
    var ruta_nivel = "user://editor_niveles_cinematicas/%s_nivel.json" % id
    var ruta_cine = "user://editor_niveles_cinematicas/%s_cinematica.json" % id
    var nivel = {
        "tipo": "nivel", "id": id, "version": "1", "fase": "archivo",
        "colocaciones": [{
            "tipo": "bulto", "id": "mesa", "recurso": "desk",
            "transform": {"posicion": [1.25, 2.5, -3.75], "rotacion": [0, 0, 0], "escala": [1, 1, 1]}
        }]
    }
    editor.get("_id").text = id
    editor.set("_doc_actual", nivel)
    editor.call("_guardar")
    if not FileAccess.file_exists(ruta_nivel):
        push_error("No se guardó el nivel")
        quit(1)
        return

    editor.get("_tipo_doc").select(1)
    editor.call("_nuevo")
    var cine = {
        "tipo": "cinematica", "id": id, "version": "1",
        "planos": [
            {
                "tipo": "3d", "segundos": 2.0,
                "camara_desde": [0.0, 2.0, 8.0], "camara": [4.5, 2.0, 8.0],
                "mira_desde": [0.0, 1.0, 0.0], "mira": [1.0, 1.0, 0.0],
                "fov": 45.0,
                "decorado": decorado_archivo
            },
            {"tipo": "3d", "segundos": 1.0, "camara": [0, 2, 3], "mira": [0, 1, 0]}
        ]
    }
    editor.get("_id").text = id
    editor.set("_doc_actual", cine)
    editor.call("_guardar")
    if not FileAccess.file_exists(ruta_cine):
        push_error("No se guardó la cinemática con ID compartido")
        quit(1)
        return
    editor.call("_refrescar_lista")
    await process_frame
    var vista_cinematica = editor.get("_vista")
    var raiz_decorado = vista_cinematica.get("_raiz_escenario")
    if raiz_decorado == null or raiz_decorado.get_child_count() == 0:
        push_error("El plano no previsualizó el escenario catalogado serializado")
        quit(1)
        return
    editor.call("_al_seleccionar", 0)
    var selector_decorado = editor.get("_biblioteca_mueble")
    if selector_decorado == null or selector_decorado.item_count == 0:
        push_error("El plano 3D no expone la biblioteca de muebles catalogados")
        quit(1)
        return
    var filtros_decorado = selector_decorado.get_parent().get_parent().get_child(0)
    var tipos_decorado = filtros_decorado.get_child(1)
    var indice_modelo_decorado = -1
    for indice in tipos_decorado.item_count:
        if tipos_decorado.get_item_text(indice) == "modelo":
            indice_modelo_decorado = indice
            break
    if indice_modelo_decorado < 0:
        push_error("El plano no permite filtrar modelos colocables")
        quit(1)
        return
    tipos_decorado.select(indice_modelo_decorado)
    tipos_decorado.item_selected.emit(indice_modelo_decorado)
    var boton_decorado = selector_decorado.get_parent().get_child(1)
    var bultos_antes = editor.get("_doc_actual")["planos"][0]["decorado"]["bultos"].size()
    boton_decorado.pressed.emit()
    editor.call("_aplicar_plano")
    var decorado_actual = editor.get("_doc_actual")["planos"][0]["decorado"]
    if decorado_actual.get("bultos", []).size() != bultos_antes + 1:
        push_error("Añadir objeto al decorado no se conservó al aplicar el plano")
        quit(1)
        return
    var indice_bulto = decorado_actual["bultos"].size() - 1
    vista_cinematica.transformacion_cambiada.emit(indice_bulto, Vector3(3.0, 0.375, 2.0))
    var posicion_bulto = editor.get("_doc_actual")["planos"][0]["decorado"]["bultos"][indice_bulto]["pos"]
    if not is_equal_approx(posicion_bulto[0], 3.0) or not is_equal_approx(posicion_bulto[2], 2.0):
        push_error("Mover un objeto del decorado no actualizó los datos serializados")
        quit(1)
        return
    var buscador_assets = filtros_decorado.get_child(2)
    buscador_assets.text = "rocketbox"
    buscador_assets.text_changed.emit("rocketbox")
    var indice_personaje = -1
    for indice in selector_decorado.item_count:
        var ruta_personaje = String(selector_decorado.get_item_metadata(indice))
        if ruta_personaje.begins_with("res://assets/modelos/rocketbox/"):
            indice_personaje = indice
            break
    if indice_personaje < 0:
        push_error("La biblioteca no ofrece avatares Rocketbox como personajes")
        quit(1)
        return
    selector_decorado.select(indice_personaje)
    selector_decorado.item_selected.emit(indice_personaje)
    var boton_personaje = selector_decorado.get_parent().get_child(3)
    if not boton_personaje.visible:
        push_error("La biblioteca no activa Añadir personaje para un avatar humano")
        quit(1)
        return
    var figuras_antes = editor.get("_doc_actual")["planos"][0]["decorado"].get("figuras", []).size()
    boton_personaje.pressed.emit()
    editor.call("_aplicar_plano")
    var figuras_actuales = editor.get("_doc_actual")["planos"][0]["decorado"].get("figuras", [])
    if figuras_actuales.size() != figuras_antes + 1:
        push_error("Añadir personaje no lo guardó en el decorado del plano")
        quit(1)
        return
    var figura_creada = figuras_actuales.back()
    if not String(figura_creada.get("modelo", "")).begins_with("rocketbox/"):
        push_error("El personaje no conservó el identificador de avatar Rocketbox")
        quit(1)
        return
    var errores_personaje = contrato.validar_cinematica(editor.get("_doc_actual"))
    if not errores_personaje.is_empty():
        push_error("El decorado con personaje no pasa el contrato: %s" % [errores_personaje])
        quit(1)
        return
    editor.call("_al_cambiar_tiempo", 0, 0.0)
    await process_frame
    var esqueletos_personaje = vista_cinematica.get("_raiz_escenario").find_children("*", "Skeleton3D", true, false)
    if esqueletos_personaje.is_empty():
        push_error("El decorado no previsualizó el modelo humano con esqueleto")
        quit(1)
        return
    editor.call("_guardar")
    editor.call("_cargar")
    var figuras_reabiertas = editor.get("_doc_actual")["planos"][0]["decorado"].get("figuras", [])
    if figuras_reabiertas.size() != figuras_antes + 1:
        push_error("Roundtrip de cinemática perdió el personaje añadido")
        quit(1)
        return
    editor.call("_al_seleccionar", 0)
    await process_frame
    var controles_efectos = editor.get("_efectos_plano")
    if controles_efectos.is_empty():
        push_error("El editor no expone los controles de efectos del plano")
        quit(1)
        return
    controles_efectos["crt_activo"].button_pressed = true
    controles_efectos["crt_intensidad"].value = 0.73
    controles_efectos["crt_duracion"].value = 0.27
    controles_efectos["crt_semilla"].value = 12.5
    controles_efectos["superposicion"].text = "ARCHIVO EN TRÁNSITO"
    controles_efectos["sup_intensidad"].value = 0.65
    controles_efectos["sup_ruido"].value = 0.01
    controles_efectos["sup_scanline"].value = 0.2
    controles_efectos["sup_semilla"].value = 8.5
    controles_efectos["grano_sin_estrobo"].button_pressed = true
    var selector_audio_plano = editor.get("_biblioteca_mueble")
    var biblioteca_audio_plano = selector_audio_plano.get_parent().get_parent()
    var filtros_audio_plano = biblioteca_audio_plano.get_child(0)
    var tipos_audio_plano = filtros_audio_plano.get_child(1)
    var indice_tipo_audio = -1
    for indice in tipos_audio_plano.item_count:
        if tipos_audio_plano.get_item_text(indice) == "audio":
            indice_tipo_audio = indice
            break
    if indice_tipo_audio < 0:
        push_error("La biblioteca del plano no ofrece el filtro de audio")
        quit(1)
        return
    tipos_audio_plano.select(indice_tipo_audio)
    tipos_audio_plano.item_selected.emit(indice_tipo_audio)
    var buscador_audio_plano = filtros_audio_plano.get_child(2)
    buscador_audio_plano.text = "ui_pulsar_01"
    buscador_audio_plano.text_changed.emit("ui_pulsar_01")
    var indice_audio_plano = -1
    for indice in selector_audio_plano.item_count:
        if String(selector_audio_plano.get_item_metadata(indice)) == "res://assets/audio/chip/ui_pulsar_01.ogg":
            indice_audio_plano = indice
            break
    if indice_audio_plano < 0:
        push_error("No se encontró el sonido del catálogo en el explorador de cinemáticas")
        quit(1)
        return
    selector_audio_plano.select(indice_audio_plano)
    selector_audio_plano.item_selected.emit(indice_audio_plano)
    var boton_asignar_sonido = biblioteca_audio_plano.get_node("BotonAsignarSonidoPlano")
    if not boton_asignar_sonido.visible:
        push_error("Un sonido catalogado no se ofrece para asignar al plano")
        quit(1)
        return
    boton_asignar_sonido.pressed.emit()
    editor.call("_aplicar_plano")
    if editor.get("_doc_actual")["planos"][0].get("sonido", "") != "pulsar":
        push_error("El sonido elegido no se asignó al plano con su clave runtime")
        quit(1)
        return
    var plano_con_efectos = editor.get("_doc_actual")["planos"][0]
    if not plano_con_efectos.get("interrupcion_crt", false):
        push_error("El plano no serializó la interrupción CRT")
        quit(1)
        return
    if not is_equal_approx(float(plano_con_efectos.get("crt_intensidad", 0.0)), 0.73):
        push_error("El editor perdió la intensidad CRT")
        quit(1)
        return
    if String(plano_con_efectos.get("superposicion_texto", "")) != "ARCHIVO EN TRÁNSITO":
        push_error("El editor no serializó la superposición tipográfica")
        quit(1)
        return
    if not is_equal_approx(float(plano_con_efectos.get("sup_scanline", 0.0)), 0.2):
        push_error("El editor perdió la intensidad de scanline")
        quit(1)
        return
    if not is_equal_approx(float(plano_con_efectos.get("sup_semilla", 0.0)), 8.5):
        push_error("El editor perdió la semilla de superposición")
        quit(1)
        return
    if not plano_con_efectos.get("grano_no_estroboscopico", false):
        push_error("El plano no guardó el modo de grano accesible")
        quit(1)
        return
    var errores_efectos = contrato.validar_cinematica(editor.get("_doc_actual"))
    if not errores_efectos.is_empty():
        push_error("El plano con efectos no pasa el contrato: %s" % [errores_efectos])
        quit(1)
        return
    editor.call("_guardar")
    editor.call("_cargar")
    var decorado_reabierto: Dictionary = editor.get("_doc_actual")["planos"][0]["decorado"]
    var efectos_reabiertos: Dictionary = editor.get("_doc_actual")["planos"][0]
    if not efectos_reabiertos.get("interrupcion_crt", false) or not efectos_reabiertos.get("grano_no_estroboscopico", false):
        push_error("Roundtrip perdió los efectos visuales del plano")
        quit(1)
        return
    if String(efectos_reabiertos.get("superposicion_texto", "")) != "ARCHIVO EN TRÁNSITO":
        push_error("Roundtrip perdió el texto de superposición")
        quit(1)
        return
    if not is_equal_approx(float(efectos_reabiertos.get("crt_semilla", 0.0)), 12.5):
        push_error("Roundtrip perdió la semilla del efecto CRT")
        quit(1)
        return
    var bultos_reabiertos: Array = decorado_reabierto.get("bultos", [])
    if bultos_reabiertos.size() != bultos_antes + 1:
        push_error("Roundtrip de cinemática perdió el objeto añadido al decorado")
        quit(1)
        return
    var bulto_reabierto: Dictionary = bultos_reabiertos[indice_bulto]
    if not is_equal_approx(bulto_reabierto["pos"][0], 3.0) or not is_equal_approx(bulto_reabierto["pos"][2], 2.0):
        push_error("Roundtrip de cinemática perdió la posición del objeto del decorado")
        quit(1)
        return

    editor.get("_tipo_doc").select(0)
    editor.get("_id").text = id
    editor.call("_cargar")
    editor.call("_al_seleccionar", 0)
    await process_frame
    if editor.get("_colocacion_pos_x").value != 1.25:
        push_error("Roundtrip de nivel perdió la posición: %s; estado %s; doc %s" % [editor.get("_colocacion_pos_x").value, editor.get("_estado").text, editor.get("_doc_actual")])
        quit(1)
        return
    var vista = editor.get("_vista")
    if vista == null or vista.get_child_count() == 0 or not vista.get_child(0) is SubViewport:
        push_error("El editor no montó un SubViewport 3D real")
        quit(1)
        return
    var raiz_escenario = vista.get("_raiz_escenario")
    if raiz_escenario == null or raiz_escenario.get_child_count() == 0:
        push_error("El viewport no construyó el escenario real del catálogo")
        quit(1)
        return
    var biblioteca = editor.get("_biblioteca_mueble")
    if biblioteca == null or biblioteca.item_count == 0:
        push_error("La biblioteca no ofrece assets del proyecto")
        quit(1)
        return
    var assets_idx = load("res://debug/editor_niveles_cinematicas_assets.gd")
    for ruta_escena in [
        "res://scenes/meta_dream.tscn",
        "res://interactables/libros/libro_interactivo.tscn",
        "res://rituales/literarios/ritual_cita.tscn",
    ]:
        if not assets_idx.hay(ruta_escena):
            push_error("La biblioteca omite el recurso de escena del juego '%s'" % ruta_escena)
            quit(1)
            return
    var filtros_assets = biblioteca.get_parent().get_parent().get_child(0)
    var selector_tipo = filtros_assets.get_child(1)
    for esperado in ["audio", "imagen", "material", "fuente", "modelo", "escena"]:
        var existe_tipo = false
        for indice in selector_tipo.item_count:
            if selector_tipo.get_item_text(indice) == esperado:
                existe_tipo = true
                break
        if not existe_tipo:
            push_error("La biblioteca oculta el tipo de asset '%s'" % esperado)
            quit(1)
            return
    var catalogo = load("res://debug/editor_niveles_cinematicas_catalogo.gd")
    var panel_biblioteca = catalogo._biblioteca("Añadir al nivel", Callable())
    if panel_biblioteca.get("copiar") == null or panel_biblioteca.get("vista_previa") == null:
        push_error("El explorador no ofrece copia de ruta ni previsualización")
        quit(1)
        return
    # El control integrado también debe exponer las rutas de todas las categorías.
    var indice_audio = -1
    var selector_catalogo = panel_biblioteca.get("tipos")
    for indice in selector_catalogo.item_count:
        if selector_catalogo.get_item_text(indice) == "audio":
            indice_audio = indice
            break
    if indice_audio < 0:
        push_error("La biblioteca no expone el filtro de audio")
        quit(1)
        return
    selector_catalogo.select(indice_audio)
    selector_catalogo.item_selected.emit(indice_audio)
    var panel_audio = panel_biblioteca.get("reproducir")
    if not panel_audio.visible or panel_biblioteca["selector"].item_count == 0:
        push_error("La biblioteca no permite previsualizar audio")
        quit(1)
        return
    var indice_imagen = -1
    for indice in selector_catalogo.item_count:
        if selector_catalogo.get_item_text(indice) == "imagen":
            indice_imagen = indice
            break
    if indice_imagen < 0:
        push_error("La biblioteca no expone el filtro de imágenes")
        quit(1)
        return
    selector_catalogo.select(indice_imagen)
    selector_catalogo.item_selected.emit(indice_imagen)
    if panel_biblioteca["vista_previa"].texture == null:
        push_error("La biblioteca no carga la previsualización de imagen")
        quit(1)
        return
    var indice_fuente = -1
    for indice in selector_catalogo.item_count:
        if selector_catalogo.get_item_text(indice) == "fuente":
            indice_fuente = indice
            break
    if indice_fuente < 0:
        push_error("La biblioteca no expone el filtro de fuentes")
        quit(1)
        return
    selector_catalogo.select(indice_fuente)
    selector_catalogo.item_selected.emit(indice_fuente)
    if not panel_biblioteca["vista_fuente"].visible:
        push_error("La biblioteca no muestra la previsualización tipográfica")
        quit(1)
        return
    var indice_modelo = -1
    for indice in selector_catalogo.item_count:
        if selector_catalogo.get_item_text(indice) == "modelo":
            indice_modelo = indice
            break
    if indice_modelo < 0:
        push_error("La biblioteca no expone el filtro de modelos")
        quit(1)
        return
    selector_catalogo.select(indice_modelo)
    selector_catalogo.item_selected.emit(indice_modelo)
    var selector_nivel = panel_biblioteca.get("selector")
    var indice_colocable = -1
    for indice in selector_nivel.item_count:
        var ruta_asset = String(selector_nivel.get_item_metadata(indice))
        if assets_idx.es_colocable(ruta_asset):
            indice_colocable = indice
            break
    if indice_colocable < 0:
        push_error("La biblioteca no encuentra un asset 3D colocable")
        quit(1)
        return
    selector_nivel.select(indice_colocable)
    selector_nivel.item_selected.emit(indice_colocable)
    if panel_biblioteca.get("vista_previa").texture != null:
        push_error("La vista previa de imagen debería ocultarse al elegir un modelo")
        quit(1)
        return
    var ruta_elegida = String(selector_nivel.get_item_metadata(indice_colocable))
    if ruta_elegida.is_empty():
        push_error("La biblioteca no expone la ruta del asset en sus metadatos")
        quit(1)
        return
    panel_biblioteca["fila"].free()
    editor.call("_anadir_asset_al_nivel", ruta_elegida)
    if editor.get("_doc_actual")["colocaciones"].size() != 2 or editor.get("_doc_actual")["colocaciones"][1].get("tipo") != "modelo":
        push_error("Añadir un asset no creó una colocación de modelo serializable")
        quit(1)
        return
    editor.call("_guardar")
    editor.call("_cargar")
    if editor.get("_doc_actual").get("colocaciones", []).size() != 2:
        push_error("Roundtrip del nivel perdió el mueble de la biblioteca")
        quit(1)
        return
    if not is_equal_approx(vista.posicion_colocacion(0).x, 1.25):
        push_error("La colocación no aparece en la posición del documento dentro del viewport")
        quit(1)
        return
    vista.transformacion_cambiada.emit(0, Vector3(2.25, 2.5, -3.75))
    if not is_equal_approx(editor.get("_doc_actual")["colocaciones"][0]["transform"]["posicion"][0], 2.25):
        push_error("Mover una colocación en el viewport no actualiza el documento")
        quit(1)
        return

    editor.get("_tipo_doc").select(1)
    editor.get("_id").text = id
    editor.call("_cargar")
    editor.call("_al_seleccionar", 0)
    await process_frame
    if editor.get("_plano_camara_x").value != 4.5:
        push_error("Roundtrip de cinemática perdió la cámara")
        quit(1)
        return
    var camara_preview = vista.get_child(0).get_node("EscenaAutoría/CamaraEditor")
    if not is_equal_approx(camara_preview.position.x, 0.0):
        push_error("El inicio del plano no respeta camara_desde")
        quit(1)
        return
    if not is_equal_approx(camara_preview.fov, 45.0):
        push_error("La previsualización no respeta el FOV del plano")
        quit(1)
        return
    var timeline = editor.get("_timeline")
    if timeline == null or not timeline is HBoxContainer or timeline.get_child_count() != 3:
        push_error("El editor no montó controles de timeline con playhead")
        quit(1)
        return
    if not is_equal_approx(timeline.call("duracion_total"), 3.0):
        push_error("El scrub no suma la duración de todos los planos")
        quit(1)
        return
    var muestra = timeline.call("muestra_en", 2.0)
    if muestra.get("indice", -1) != 1 or not is_equal_approx(muestra.get("avance", -1.0), 0.0):
        push_error("El límite temporal no selecciona el siguiente plano")
        quit(1)
        return
    editor.call("_al_seleccionar", 1)
    if not is_equal_approx(timeline.call("tiempo_actual"), 2.0):
        push_error("Seleccionar un plano no lleva el playhead a su inicio")
        quit(1)
        return
    editor.call("_al_seleccionar", 0)
    timeline.call("_establecer_tiempo", 1.0)
    if not is_equal_approx(camara_preview.position.x, 2.25):
        push_error("El scrub no interpola la cámara suavemente")
        quit(1)
        return
    var marcador_mira = vista.get_child(0).get_node("EscenaAutoría/MiraCinematica")
    if not is_equal_approx(marcador_mira.position.x, 0.5):
        push_error("El scrub no interpola el punto de mira")
        quit(1)
        return
    timeline.call("_establecer_tiempo", 2.0)
    timeline.call("alternar_reproduccion")
    timeline.call("_process", 0.5)
    if not is_equal_approx(timeline.call("tiempo_actual"), 2.5):
        push_error("La reproducción no avanza el tiempo del timeline")
        quit(1)
        return
    timeline.call("alternar_reproduccion")
    editor.set("_editando_indice", 0)
    editor.call("_aplicar_plano")
    var plano_guardado = editor.get("_doc_actual")["planos"][0]
    if plano_guardado.get("camara_desde", [])[0] != 0.0:
        push_error("Aplicar el plano perdió su posición inicial de cámara")
        quit(1)
        return
    if plano_guardado.get("mira_desde", [])[0] != 0.0:
        push_error("Aplicar el plano perdió su posición inicial de mira")
        quit(1)
        return

    var id_malo = id + "_malo"
    var ruta_mala = "user://editor_niveles_cinematicas/%s_nivel.json" % id_malo
    var archivo_malo = FileAccess.open(ruta_mala, FileAccess.WRITE)
    archivo_malo.store_string(JSON.stringify({
        "formato": "siga98-nivel-v1",
        "documento": {"tipo": "nivel", "id": id_malo, "version": "1", "fase": "archivo", "colocaciones": "mal"}
    }))
    archivo_malo.close()
    editor.get("_tipo_doc").select(0)
    editor.get("_id").text = id_malo
    editor.call("_cargar")
    if editor.get("_doc_actual").get("id", "") != id or not editor.get("_estado").text.begins_with("No se cargó:"):
        push_error("Una carga malformada reemplazó el documento activo")
        quit(1)
        return

    print("OK: escena, controles, guardado, recarga y rechazo de datos malformados")
    editor.queue_free()
    DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta_nivel))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta_cine))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta_mala))
    quit(0)
'''
    with tempfile.NamedTemporaryFile(mode="w", suffix=".gd", delete=False) as f:
        f.write(script)
        script_path = f.name
    try:
        # Los avatares riggeados importan mallas y animaciones; damos margen al
        # runtime headless sin recortar la comprobación de la escena real.
        code, out, err = godot_headless(script_path, timeout=180)
        if code != 0 or "SCRIPT ERROR" in out + err or "ERROR:" in out + err:
            raise AssertionError("Smoke de la escena falló:\n{}\n{}".format(out, err))
        assert "OK: escena, controles, guardado, recarga y rechazo de datos malformados" in out
        print("OK: editor real persiste, recarga y protege documentos")
    finally:
        os.unlink(script_path)


def probar_indice_assets():
    """El índice se construye del disco y cubre todo el contenido, no una tabla."""
    script = r'''
extends SceneTree

func _init():
    var assets = load("res://debug/editor_niveles_cinematicas_assets.gd")
    var todos = assets.indice()
    if todos.size() < 100:
        print("ERROR: el índice solo encontró %d assets" % todos.size())
        quit(1)
        return
    var colocables = assets.filtrar("", "", "", true)
    if colocables.size() < 50:
        print("ERROR: solo %d assets colocables" % colocables.size())
        quit(1)
        return
    # Tiene que haber piezas fuera de assets/modelos/: ese era justo el límite
    # de la biblioteca anterior, que solo resolvía nombres de esa carpeta.
    var de_arte = assets.filtrar("", "", "res://arte/", true)
    if de_arte.is_empty():
        print("ERROR: el índice no ofrece piezas de arte/")
        quit(1)
        return
    var props_escena = assets.filtrar("", "modelo", "archivador_desierto_psx.obj", true)
    if props_escena.is_empty() or not String(props_escena[0]["ruta"]).begins_with("res://escenas/"):
        print("ERROR: el índice deja fuera los modelos organizados bajo escenas/")
        quit(1)
        return
    var tipos = assets.tipos()
    for esperado in ["modelo", "escena", "imagen", "audio"]:
        if not tipos.has(esperado):
            print("ERROR: el índice no clasifica el tipo '%s': %s" % [esperado, tipos])
            quit(1)
            return
    if assets.carpetas(colocables).size() < 10:
        print("ERROR: el índice agrupa en muy pocas carpetas")
        quit(1)
        return
    # El filtro de texto busca en la ruta completa.
    var filtrado = assets.filtrar("", "modelo", "household_goods", true)
    if filtrado.is_empty():
        print("ERROR: el filtro por texto no encuentra household_goods")
        quit(1)
        return
    for entrada in filtrado:
        if not String(entrada["ruta"]).contains("household_goods"):
            print("ERROR: el filtro devolvió algo ajeno: %s" % entrada["ruta"])
            quit(1)
            return
    # Una imagen está en el índice pero no se coloca como pieza 3D.
    var imagenes = assets.filtrar("", "imagen", "", false)
    if imagenes.is_empty():
        print("ERROR: el índice no lista imágenes")
        quit(1)
        return
    if assets.es_colocable(String(imagenes[0]["ruta"])):
        print("ERROR: una imagen no debe ser colocable como bulto")
        quit(1)
        return
    var etiqueta = assets.etiqueta(filtrado[0])
    if not etiqueta.contains("/"):
        print("ERROR: la etiqueta no distingue la carpeta de origen: %s" % etiqueta)
        quit(1)
        return
    print("OK: indice %d assets, %d colocables" % [todos.size(), colocables.size()])
    quit(0)
'''
    with tempfile.NamedTemporaryFile(mode="w", suffix=".gd", delete=False) as f:
        f.write(script)
        script_path = f.name
    try:
        code, out, err = godot_headless(script_path)
        if code != 0:
            raise AssertionError("Índice de assets falló:\n{}\n{}".format(out, err))
        assert "OK: indice" in out
        print("OK: la biblioteca indexa los assets reales del proyecto")
    finally:
        os.unlink(script_path)


def probar_modelos_acepta_ruta_absoluta():
    """Un bulto puede declarar cualquier asset del proyecto por su ruta res://."""
    script = r'''
extends SceneTree

func _init():
    var modelos = load("res://guion/modelos.gd")
    var assets = load("res://debug/editor_niveles_cinematicas_assets.gd")
    # El nombre suelto sigue resolviendo dentro de assets/modelos/.
    if not modelos.hay("desk"):
        print("ERROR: se perdió la resolución por nombre catalogado")
        quit(1)
        return
    var candidatos = assets.filtrar("", "modelo", "res://arte/", true)
    if candidatos.is_empty():
        candidatos = assets.filtrar("", "modelo", "household_goods", true)
    if candidatos.is_empty():
        print("ERROR: no hay modelos indexados con los que probar")
        quit(1)
        return
    var ruta = String(candidatos[0]["ruta"])
    if not modelos.hay(ruta):
        print("ERROR: Modelos.hay no acepta la ruta completa '%s'" % ruta)
        quit(1)
        return
    if modelos.hay("res://assets/modelos/no_existe_jamas.glb"):
        print("ERROR: Modelos.hay acepta una ruta inexistente")
        quit(1)
        return
    print("OK: rutas res:// resueltas")
    quit(0)
'''
    with tempfile.NamedTemporaryFile(mode="w", suffix=".gd", delete=False) as f:
        f.write(script)
        script_path = f.name
    try:
        code, out, err = godot_headless(script_path)
        if code != 0:
            raise AssertionError("Resolución de rutas absolutas falló:\n{}\n{}".format(out, err))
        assert "OK: rutas res://" in out
        print("OK: Modelos resuelve assets por ruta completa sin perder los nombres catalogados")
    finally:
        os.unlink(script_path)


def probar_asset_cualquiera_en_documento():
    """Insertar un asset de fuera de assets/modelos/ y que sobreviva al roundtrip."""
    script = r'''
extends SceneTree

func _init():
    var assets = load("res://debug/editor_niveles_cinematicas_assets.gd")
    var contrato = load("res://debug/editor_niveles_cinematicas_contrato.gd")
    var candidatos = assets.filtrar("", "", "res://arte/", true)
    if candidatos.is_empty():
        print("ERROR: no hay assets de arte/ para colocar")
        quit(1)
        return
    var ruta = String(candidatos[0]["ruta"])

    var nivel = {"tipo": "nivel", "id": "assets-01", "version": "1", "fase": "archivo", "colocaciones": []}
    var indice = contrato.agregar_asset_a_nivel(nivel, ruta)
    if indice != 0:
        print("ERROR: no se colocó el asset en el nivel")
        quit(1)
        return
    var colocacion = nivel["colocaciones"][0]
    if String(colocacion["recurso"]) != ruta or String(colocacion["origen"]) != "biblioteca_proyecto":
        print("ERROR: la colocación no apunta al asset: %s" % colocacion)
        quit(1)
        return
    if not contrato.id_ruta_valido(String(colocacion["id"])):
        print("ERROR: el id derivado de la ruta no es válido: %s" % colocacion["id"])
        quit(1)
        return
    var tam = colocacion["extra"]["tam"]
    if tam[0] <= 0.0 or tam[1] <= 0.0 or tam[2] <= 0.0:
        print("ERROR: el asset se colocó sin tamaño utilizable: %s" % [tam])
        quit(1)
        return
    var errores_nivel = contrato.validar_nivel(nivel)
    if errores_nivel.size() > 0:
        print("ERROR: el nivel con el asset no valida: %s" % ", ".join(errores_nivel))
        quit(1)
        return

    var resultado = contrato.agregar_asset_a_decorado('{"suelo": [10, 10], "bultos": []}', ruta)
    if not String(resultado.get("error", "")).is_empty():
        print("ERROR: " + String(resultado["error"]))
        quit(1)
        return
    var decorado = resultado["decorado"]
    var cine = {
        "tipo": "cinematica", "id": "assets-01", "version": "1",
        "planos": [{"tipo": "3d", "segundos": 1.0, "camara": [0, 2, 3], "mira": [0, 1, 0], "decorado": decorado}]
    }
    var errores_cine = contrato.validar_cinematica(cine)
    if errores_cine.size() > 0:
        print("ERROR: la cinemática con el asset no valida: %s" % ", ".join(errores_cine))
        quit(1)
        return
    # Roundtrip por JSON: el documento es el formato de intercambio.
    var reabierto = JSON.parse_string(JSON.stringify(cine, "  "))
    if not reabierto is Dictionary:
        print("ERROR: el documento con assets no serializa")
        quit(1)
        return
    var bulto = reabierto["planos"][0]["decorado"]["bultos"][0]
    if String(bulto["modelo"]) != ruta:
        print("ERROR: el roundtrip perdió el asset: %s" % bulto)
        quit(1)
        return
    if contrato.agregar_asset_a_nivel(nivel, "res://arte/no_existe.glb") != -1:
        print("ERROR: se aceptó un asset inexistente")
        quit(1)
        return
    var imagenes = assets.filtrar("", "imagen", "", false)
    if not imagenes.is_empty():
        var fallo = contrato.agregar_asset_a_decorado('{"bultos": []}', String(imagenes[0]["ruta"]))
        if String(fallo.get("error", "")).is_empty():
            print("ERROR: una imagen se aceptó como bulto 3D")
            quit(1)
            return
    print("OK: asset de proyecto colocado y conservado")
    quit(0)
'''
    with tempfile.NamedTemporaryFile(mode="w", suffix=".gd", delete=False) as f:
        f.write(script)
        script_path = f.name
    try:
        code, out, err = godot_headless(script_path)
        if code != 0:
            raise AssertionError("Colocación de asset libre falló:\n{}\n{}".format(out, err))
        assert "OK: asset de proyecto colocado y conservado" in out
        print("OK: cualquier asset del proyecto se coloca, valida y sobrevive al roundtrip")
    finally:
        os.unlink(script_path)


def main():
    print("=" * 60)
    print("PRUEBAS EDITOR NIVELES Y CINEMÁTICAS (#2942)")
    print("=" * 60)

    tests = [
        ("Syntax GDScript", probar_gdscript_syntax),
        ("Validar nivel válido", probar_validar_nivel_valido),
        ("Validar nivel inválido", probar_validar_nivel_invalido),
        ("Validar cinemática válida", probar_validar_cinematica_valida),
        ("Validar cinemática inválida", probar_validar_cinematica_invalida),
        ("Roundtrip nivel", probar_roundtrip_nivel),
        ("Roundtrip cinemática", probar_roundtrip_cinematica),
        ("Formato versionado", probar_formato_versionado),
        ("Carga inválida no corrompe", probar_carga_invalida_no_sobrescribe),
        ("Rutas seguras", probar_rutas_seguras),
        ("Integración Cinematica.validar", probar_cinematica_validar_integracion),
        ("Persistencia user://", probar_persistencia_user_dir),
        ("Solo debug/QA", probar_solo_debug_qa),
        ("Instanciar editor real", probar_escena_editor_runtime),
        ("Índice completo de assets", probar_indice_assets),
        ("Modelos: ruta res://", probar_modelos_acepta_ruta_absoluta),
        ("Colocar assets del proyecto", probar_asset_cualquiera_en_documento),
    ]

    passed = 0
    failed = 0

    for name, probar_fn in tests:
        try:
            probar_fn()
            passed += 1
        except Exception as e:
            failed += 1
            print("FAIL {}: {}".format(name, e))

    print("=" * 60)
    print("Resultados: {} pasadas, {} fallos".format(passed, failed))
    print("=" * 60)

    if failed > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
