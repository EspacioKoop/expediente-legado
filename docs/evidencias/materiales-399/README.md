# Evidencia visual de materiales · #399

Este gate produce cuatro capturas comparables del recorrido real de `dia.tscn`:
**oficina**, **calle**, **casa** y **sueño**. Todas usan la cámara del jugador a
1280×720, FOV 70 y HUD oculto. El harness fija además un rumbo e inclinación de
QA por fase: la toma no hereda la orientación de la fase anterior, porque eso
puede convertir una captura de materiales en una foto de la pared de entrada.

Las PNG se publican como artifact del workflow `Evidencia materiales 399`; no
se versionan en Git porque los binarios de imagen están sujetos a Git LFS.

## Qué contiene el artifact

- `oficina.png`, `calle.png`, `casa.png` y `sueno.png`: las cuatro tomas
  canónicas sin HUD.
- `comparativa.png`: **comparativa 2×2** a 1280×720, en orden
  **oficina · calle / casa · sueño**, generada a partir de las mismas imágenes
  ya capturadas, sin volver a renderizar el juego.
- `manifest.json`: encuadre, SHA-256 y diagnóstico material efectivo por fase.
- `resumen.md`: entrada de revisión con la comparativa y una tabla de suelo,
  muro y contadores de materiales PSX/texturados/deformados.

La automatización comprueba que las cuatro capturas existen, no están vacías y
no son el mismo frame; también exige que la comparativa y el resumen existan y
que el sueño conserve su material deformado/detallado opt-in. Eso evita evidencia
rota, pero **no sustituye la revisión humana** exigida por #399.

## Qué revisar sin HUD

- **Oficina:** suelo, pared y mobiliario deben leerse como materiales distintos;
  metal/ABS/melamina no deben colapsar en el mismo bloque de color.
- **Calle:** calzada y aceras deben separarse con claridad, las fachadas no deben
  parecer una única pared y vidrio/metal comercial deben conservar identidad.
- **Casa:** el conjunto debe leerse doméstico por suelo, paredes, madera, cocina,
  textiles y mobiliario, no como una recoloración de oficina.
- **Sueño:** debe seguir siendo reconocible la materia de vigilia, pero con
  escala/deformación imposible y tratamiento PSX coherente.

El artifact es deliberadamente una entrada de revisión. Un cambio puede pasar
el workflow y aun así necesitar correcciones si un humano no distingue los
espacios o detecta repetición, escalas incoherentes, transparencia defectuosa o
pérdida de lectura bajo el tratamiento PSX.
