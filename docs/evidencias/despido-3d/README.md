# Despido 3D (#899)

Capturas en GPU real (Intel Alder Lake-N, `DISPLAY=:0`) del reproductor común
con los tres planos de `DespidoCinematica`, al empezar (`-0`) y al terminar
(`-1`) cada travelling:

- `puesto`: la carpeta sellada en la mesa del archivo y la silla retirada.
- `salida`: la persona y dos escoltas, de espaldas, hacia la puerta iluminada,
  con la voz del cuñado.
- `nuevo-dia`: la credencial nueva en la mesa de casa; con el gato real si
  seguía presente (`con-gato-*`) y sin él si no (`sin-gato-*`).

Regenerar:

```bash
env DISPLAY=:0 godot4 --path godot --script res://pruebas/capturar_despido_3d.gd
```

No hay validación humana ni con mando: solo capturas y la regresión headless.
