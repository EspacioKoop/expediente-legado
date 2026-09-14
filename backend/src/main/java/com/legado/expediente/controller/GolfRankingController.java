package com.legado.expediente.controller;

import com.legado.expediente.model.PuntuacionGolf;
import com.legado.expediente.repository.PuntuacionGolfRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/golf/ranking")
public class GolfRankingController {

    private static final int HOYOS = 3;
    private static final int GOLPES_MINIMOS = 3;
    private static final int GOLPES_MAXIMOS = 36;
    private static final int ALIAS_MAXIMO = 24;

    private final PuntuacionGolfRepository puntuacionGolfRepository;

    public GolfRankingController(PuntuacionGolfRepository puntuacionGolfRepository) {
        this.puntuacionGolfRepository = puntuacionGolfRepository;
    }

    public record SolicitudRanking(String alias, Integer golpes, Integer hoyos) {
    }

    public record EntradaRanking(String alias, int golpes, int hoyos, LocalDateTime creadoEn) {
    }

    @GetMapping
    public List<EntradaRanking> ranking() {
        return puntuacionGolfRepository.findTop50ByOrderByGolpesAscCreadoEnAsc().stream()
                .map(GolfRankingController::aEntrada)
                .toList();
    }

    @PostMapping
    public ResponseEntity<?> publicar(@RequestBody SolicitudRanking solicitud) {
        String alias = normalizarAlias(solicitud.alias());
        if (!aliasValido(alias)) {
            return ResponseEntity.badRequest().body(Map.of("error", "alias_invalido"));
        }
        if (solicitud.hoyos() == null || solicitud.hoyos() != HOYOS) {
            return ResponseEntity.badRequest().body(Map.of("error", "hoyos_invalidos"));
        }
        if (solicitud.golpes() == null
                || solicitud.golpes() < GOLPES_MINIMOS
                || solicitud.golpes() > GOLPES_MAXIMOS) {
            return ResponseEntity.badRequest().body(Map.of("error", "golpes_invalidos"));
        }

        PuntuacionGolf guardada = puntuacionGolfRepository.save(
                new PuntuacionGolf(alias, solicitud.golpes(), solicitud.hoyos()));
        return ResponseEntity.status(HttpStatus.CREATED).body(aEntrada(guardada));
    }

    private static EntradaRanking aEntrada(PuntuacionGolf puntuacion) {
        return new EntradaRanking(
                puntuacion.getAlias(),
                puntuacion.getGolpes(),
                puntuacion.getHoyos(),
                puntuacion.getCreadoEn());
    }

    private static String normalizarAlias(String alias) {
        if (alias == null) {
            return "";
        }
        return alias.strip().replaceAll("\\s+", " ");
    }

    private static boolean aliasValido(String alias) {
        if (alias.isEmpty() || alias.length() > ALIAS_MAXIMO) {
            return false;
        }
        return alias.matches("[\\p{L}\\p{N} ._-]+");
    }
}
