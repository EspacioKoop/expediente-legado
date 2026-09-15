# Instrucciones para agentes de código

Lee y respeta `AGENTS.md` antes de modificar el repositorio.

## Reservas

Antes de editar publica en #182 un `CLAIM` con `lease=48h` al final:

```text
CLAIM issue=#N agent=<nombre> branch=<rama> files=<rutas> goal=<objetivo> lease=48h
```

Si sigues trabajando 48 horas después sin PR abierta, renueva con:

```text
HEARTBEAT issue=#N branch=<rama>
```

Una `PR_READY` con PR abierta mantiene la reserva. No hace falta publicar `RELEASE` tras merge/cierre: `.github/workflows/reservas.yml` lo hace automáticamente. Si abandonas antes de abrir PR, publica `RELEASE issue=#N motivo=abandonado`.

## GDScript: preflight obligatorio

Si tocas cualquier archivo `*.gd`, antes de dar el trabajo por terminado ejecuta desde la raíz:

```bash
bash scripts/check_gdscript.sh
```

Ese comando es la referencia local para formato, lint y regresiones Python relacionadas con Godot.

Reglas adicionales:

- no abras ni marques como listo un PR con cambios GDScript sin ejecutar el preflight;
- `gdformat` puede reescribir saltos de línea y encadenamientos: no escribas tests que dependan de whitespace o de una representación textual que el formatter pueda cambiar;
- cuando un test Python necesite comprobar una llamada GDScript, prefiere regex tolerante a whitespace o una prueba de comportamiento/contrato;
- no rebajes `gdlint`, `gdformat` ni tests para poner verde un PR;
- CI usa el mismo `scripts/check_gdscript.sh`, con `gdtoolkit==4.3.4`.
