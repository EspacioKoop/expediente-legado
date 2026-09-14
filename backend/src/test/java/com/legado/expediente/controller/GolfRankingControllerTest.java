package com.legado.expediente.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import com.legado.expediente.model.PuntuacionGolf;
import com.legado.expediente.repository.PuntuacionGolfRepository;
import java.lang.reflect.Proxy;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

class GolfRankingControllerTest {

    @Test
    void publicaAliasNormalizadoYPuntuacionValida() {
        AtomicReference<PuntuacionGolf> guardada = new AtomicReference<>();
        GolfRankingController controller = new GolfRankingController(
                repositorio(new ArrayList<>(), guardada));

        var respuesta = controller.publicar(
                new GolfRankingController.SolicitudRanking("  Ana   98 ", 7, 3));

        assertEquals(HttpStatus.CREATED, respuesta.getStatusCode());
        assertNotNull(guardada.get());
        assertEquals("Ana 98", guardada.get().getAlias());
        assertEquals(7, guardada.get().getGolpes());
        assertEquals(3, guardada.get().getHoyos());
    }

    @Test
    void rechazaPuntuacionFueraDeLimites() {
        AtomicReference<PuntuacionGolf> guardada = new AtomicReference<>();
        GolfRankingController controller = new GolfRankingController(
                repositorio(new ArrayList<>(), guardada));

        var respuesta = controller.publicar(
                new GolfRankingController.SolicitudRanking("Jugador", 2, 3));

        assertEquals(HttpStatus.BAD_REQUEST, respuesta.getStatusCode());
        assertEquals(null, guardada.get());
    }

    @Test
    void devuelveElTopRecibidoDelRepositorio() {
        List<PuntuacionGolf> entradas = List.of(
                new PuntuacionGolf("A", 5, 3),
                new PuntuacionGolf("B", 8, 3));
        GolfRankingController controller = new GolfRankingController(
                repositorio(entradas, new AtomicReference<>()));

        var ranking = controller.ranking();

        assertEquals(2, ranking.size());
        assertEquals("A", ranking.get(0).alias());
        assertEquals(5, ranking.get(0).golpes());
    }

    private static PuntuacionGolfRepository repositorio(
            List<PuntuacionGolf> ranking, AtomicReference<PuntuacionGolf> guardada) {
        return (PuntuacionGolfRepository) Proxy.newProxyInstance(
                GolfRankingControllerTest.class.getClassLoader(),
                new Class<?>[]{PuntuacionGolfRepository.class},
                (proxy, method, args) -> {
                    if ("findTop50ByOrderByGolpesAscCreadoEnAsc".equals(method.getName())) {
                        return ranking;
                    }
                    if ("save".equals(method.getName())) {
                        PuntuacionGolf puntuacion = (PuntuacionGolf) args[0];
                        guardada.set(puntuacion);
                        return puntuacion;
                    }
                    if ("toString".equals(method.getName())) {
                        return "PuntuacionGolfRepositoryFake";
                    }
                    return valorPorDefecto(method.getReturnType());
                });
    }

    private static Object valorPorDefecto(Class<?> tipo) {
        if (!tipo.isPrimitive()) {
            return null;
        }
        if (tipo == boolean.class) {
            return false;
        }
        if (tipo == char.class) {
            return '\0';
        }
        if (tipo == byte.class) {
            return (byte) 0;
        }
        if (tipo == short.class) {
            return (short) 0;
        }
        if (tipo == int.class) {
            return 0;
        }
        if (tipo == long.class) {
            return 0L;
        }
        if (tipo == float.class) {
            return 0.0F;
        }
        return 0.0D;
    }
}
