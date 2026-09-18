# Imprevistos por vida laboral (#93)

Este corte convierte la parte de “imprevistos” de #93 en una regla reproducible y acotada.

- Aproximadamente una de cada cinco vidas laborales no recibe ninguno.
- Cuando una vuelta sí trae imprevistos, recibe **2–4** sucesos.
- No se repite un mismo suceso dentro de la vuelta.
- Hay al menos una jornada completa entre dos sucesos.
- Como máximo aparece **un imprevisto fuerte**.
- La selección depende de la semilla de partida y del número de vuelta; guardar y cargar no vuelve a tirar.
- Los costes normales quedan por debajo del coste diario de #83 (26) y los fuertes rondan un sueldo base (40).
- Nunca hay crédito, deuda ni saldo negativo.

Los sucesos se resuelven al cerrar el día en casa. Si hay saldo suficiente, el gasto se paga. Si no lo hay, el dinero queda intacto y se registra una consecuencia ambiental de tipo casa_* para que #96 pueda representarla sin un medidor: luz reducida, persiana atascada, agua caliente averiada, etc.

El plan vive dentro de jornada["imprevistos"], por lo que se guarda con la vida laboral y se reinicia al reasignar. Las partidas creadas antes de este corte reciben su plan al completar la jornada con la semilla real de la partida.

Este primer vertical no añade deuda acumulativa, intereses, cadenas de eventos ni game over económico. Tampoco concede ventajas: un imprevisto solo quita margen o deja una incomodidad doméstica persistente.

Refs #83 #93 #96.
