# WEBKEEPER 98

Prototipo GBC propio para #748, asociado al vertical de Anansi (#656) sin reutilizar audio, texto ni iconografía cultural externa. El vínculo temático está en la **lectura de amagos y el contraengaño**, no en presentar la red del juego como símbolo tradicional akan.

## Premisa

Kwaku es una pequeña araña suplente de **Web United**. Una lesión deja al equipo sin portero durante un torneo nocturno y Kwaku entra bajo palos. Su tamaño parece una desventaja hasta que empieza a cubrir la portería con ocho patas y una telaraña de emergencia.

La historia se cuenta en tres partidos cortos:

1. **El debut** — 6 tiros, hacen falta 3 paradas. Funciona como tutorial y los lanzamientos no tienen amago.
2. **Los tramposos** — 8 tiros, hacen falta 4 paradas. Algunos delanteros enseñan primero un destino falso y revelan el real con margen suficiente.
3. **La final** — 9 tiros, hacen falta 5 paradas. Mezcla tiros altos, rasos y amagos sin subir de forma agresiva la velocidad.

Perder no reinicia el torneo: se repite **solo el partido actual**. Tras dos derrotas en el mismo partido el juego activa una ayuda y deja de ocultar el destino real durante los amagos.

## Controles

- **Izquierda / derecha**: mover a Kwaku entre tres carriles.
- **Arriba / abajo**: preparar una parada alta o rasa.
- **A**: estirada. La ventana de parada dura lo bastante para reaccionar al último telegraph.
- **B**: telaraña de emergencia. Cubre ambas alturas del carril actual, pero tiene recuperación larga.
- **Start/A**: avanzar pantallas narrativas y reintentos.

## Integración

`webkeeper_98` es una ROM jugable del catálogo y entra en el build de runtime. Se vende como cartucho opcional en la tienda de videojuegos; no viene incluida de serie.

- cabecera: `WEBKEEPER98`;
- modo CGB: dual (`0x80`);
- tamaño objetivo: 32 KiB;
- completar de verdad la final escribe `0xA5` en WRAM `$C100`;
- arrancar, ganar solo uno o dos partidos, perder o reintentar nunca escribe el handshake.

`Webkeeper98Vigilia`, montado en la casa real desde el controller de Anansi, observa la cabecera `WEBKEEPER98` y solo registra `anansi_akan` cuando lee `0xA5` en `$C100`. La fuente estable es `rom:webkeeper_98`; comprar o arrancar la ROM no activa nada. La consola y el emulador permanecen genéricos.
