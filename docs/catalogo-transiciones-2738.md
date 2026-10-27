# Catálogo de transiciones narrativas · #2738

Generado por `scripts/catalogar_transiciones_20261026.py` (offline,
determinista, solo lectura del checkout). No es un detector de errores —eso ya
lo cubren `auditar_siga98_estados` (#2692) y el recorrido de softlocks
(#2736)—: es el inventario consultable de qué rutas declara cada expediente y
qué variables las persisten.

```bash
python3 scripts/catalogar_transiciones_20261026.py --root . --json catalogo.json
python3 -m unittest scripts.test_catalogar_transiciones_20261026
```

## Resultado sobre `main` · 2026-10-26

```
casos=11 pistas=79 doble_origen=42 conceptos=16 enlaces=26
consistencia: variables con esquema y consumidor reales
```

- **11 expedientes** con sus registros, sospechosos y estado.
- **79 pistas**: cada una con su registro de origen y frase gatillo; **42 son
  de doble origen** (`registroOrigen` + `registroOrigen2`), o sea más de la
  mitad de las transiciones oculto→descubierta son combinables.
- **16 conceptos** con **26 enlaces `[[...]]`** entre resúmenes; los destinos
  sin concepto real quedan listados por ficha (`enlaces_sin_destino`), que es
  inventario, no error: el veredicto de si es intencional es del detector.

## Variables y escenas que las consumen

| Variable de partida | Consumidor canónico |
| --- | --- |
| `pistas_descubiertas` | `guion/visor_expediente.gd:68`, `guion/careo_contexto_app.gd:20` |
| `sellos_obtenidos` | `guion/sellos.gd:11` |
| `anomalias_descubiertas` / `_vuelta` | `guion/catalogo_anomalias.gd:12-13` |
| `veredictos` | `guion/acusacion.gd:52` |
| `reconstrucciones` | `guion/reconstruccion_expediente.gd:142` |
| `pronosticos` | `guion/pronosticos_auditoria.gd:11` |

La comprobación de consistencia verifica dos cosas por variable: que siga en
el esquema de guardado de `partida.gd` y que su escena consumidora siga
citándola, con línea exacta. Hoy todo está en verde.

## Regeneración

El catálogo no se versiona: se regenera bajo demanda. Cualquier cambio en
`casos.json`, `partida.gd` o los consumidores que rompa una referencia hace
salir el comando con código 1 y lista la variable afectada.
