# Instrucciones para agentes de código

Lee y respeta `AGENTS.md` antes de modificar el repositorio.

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
