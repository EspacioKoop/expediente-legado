# Evidencia visual #437 — regla espacial del Minotauro

Este gate genera tres capturas deterministas del mismo vertical 3D para **revisión humana**. No marca automáticamente como cumplido el criterio de legibilidad.

1. `inicial.png`: laberinto antes de dejar marcas.
2. `marca-estable.png`: primera marca de Ariadna e hilo ligados al cruce norte real.
3. `marca-desplazada.png`: tras bisagra + centro, la misma marca real reaparece en el cruce sur aparente mientras el hilo conserva la topología real.

La pregunta de aceptación es concreta: **¿se puede deducir por las anclas rojas y el hilo que el espacio cambió de lectura, sin ensayo ciego ni HUD explicativo?**

Si la respuesta humana es no, abrir un fallo reproducible señalando qué estado, ancla, tramo de hilo o encuadre resulta ambiguo. No añadir otra mecánica ni tutorial antes de localizar esa ambigüedad.

Refs #437 #435.
