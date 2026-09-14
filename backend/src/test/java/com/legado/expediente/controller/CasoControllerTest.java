package com.legado.expediente.controller;

import com.legado.expediente.model.Caso;
import com.legado.expediente.model.Pista;
import com.legado.expediente.model.Descubrimiento;
import com.legado.expediente.repository.DescubrimientoRepository;
import com.legado.expediente.model.CombateEnCurso;
import com.legado.expediente.model.Rol;
import com.legado.expediente.model.Sospechoso;
import com.legado.expediente.model.Usuario;
import com.legado.expediente.repository.CasoRepository;
import com.legado.expediente.repository.CombateEnCursoRepository;
import com.legado.expediente.repository.PistaRepository;
import com.legado.expediente.repository.SospechosoRepository;
import com.legado.expediente.repository.UsuarioRepository;
import com.legado.expediente.repository.VeredictoRepository;
import com.legado.expediente.service.UsuarioContexto;
import com.legado.expediente.service.InvestigacionCasoService;
import com.legado.expediente.service.ResolucionCasoService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.servlet.mvc.support.RedirectAttributesModelMap;

import java.lang.reflect.Proxy;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Cubre la lógica de acusar() que decide entre veredicto directo, combate,
 * y la señal "accionReciente" que el cliente usa para juzgar si la
 * acusación estuvo respaldada por evidencia suficiente.
 */
class CasoControllerTest {

    private static final Long CASO_ID = 10L;
    private static final Long USUARIO_ID = 1L;

    private final Map<Long, com.legado.expediente.model.Veredicto> veredictosPorCaso = new HashMap<>();
    private final Map<Long, CombateEnCurso> combatesPorCaso = new HashMap<>();
    private final Map<Long, Sospechoso> sospechosos = new HashMap<>();
    private final List<CombateEnCurso> combatesGuardados = new ArrayList<>();

    private final Usuario usuario = new Usuario();
    private final Authentication authentication = new UsernamePasswordAuthenticationToken("auditor01", "n/a");
    private final Caso caso = new Caso();

    private CasoController controller;
    private final Map<Long, Pista> pistas = new HashMap<>();
    private final List<Descubrimiento> descubrimientos = new ArrayList<>();
    private Pista combinacion;

    @BeforeEach
    void configurar() {
        usuario.setId(USUARIO_ID);
        usuario.setRol(Rol.AUDITOR);
        caso.setId(CASO_ID);
        caso.setConfidencial(false);

        UsuarioRepository usuarioRepository = fake(UsuarioRepository.class, Map.of(
                "findByUsername", args -> Optional.of(usuario)
        ));
        CasoRepository casoRepository = fake(CasoRepository.class, Map.of(
                "findById", args -> Optional.of(caso)
        ));
        VeredictoRepository veredictoRepository = fake(VeredictoRepository.class, Map.of(
                "findByUsuarioIdAndCasoId", args -> Optional.ofNullable(veredictosPorCaso.get((Long) args[1])),
                "save", args -> {
                    com.legado.expediente.model.Veredicto v = (com.legado.expediente.model.Veredicto) args[0];
                    veredictosPorCaso.put(CASO_ID, v);
                    return v;
                }
        ));
        CombateEnCursoRepository combateEnCursoRepository = fake(CombateEnCursoRepository.class, Map.of(
                "findByUsuarioIdAndCasoId", args -> Optional.ofNullable(combatesPorCaso.get((Long) args[1])),
                "save", args -> {
                    CombateEnCurso c = (CombateEnCurso) args[0];
                    combatesPorCaso.put(CASO_ID, c);
                    combatesGuardados.add(c);
                    return c;
                },
                "delete", args -> {
                    combatesPorCaso.remove(CASO_ID);
                    return null;
                }
        ));
        SospechosoRepository sospechosoRepository = fake(SospechosoRepository.class, Map.of(
                "findById", args -> Optional.ofNullable(sospechosos.get((Long) args[0]))
        ));
        PistaRepository pistaRepository = fake(PistaRepository.class, Map.of(
                "findById", args -> Optional.ofNullable(pistas.get((Long) args[0])),
                "findCombinacion", args -> {
                    assertEquals(CASO_ID, args[0]);
                    assertEquals(1L, args[1]);
                    assertEquals(2L, args[2]);
                    return Optional.ofNullable(combinacion);
                }
        ));
        DescubrimientoRepository descubrimientoRepository = fake(DescubrimientoRepository.class, Map.of(
                "existsByUsuarioIdAndPistaId", args -> descubrimientos.stream().anyMatch(
                        d -> d.getUsuario().getId().equals(args[0]) && d.getPista().getId().equals(args[1])),
                "save", args -> {
                    Descubrimiento descubrimiento = (Descubrimiento) args[0];
                    descubrimientos.add(descubrimiento);
                    return descubrimiento;
                }
        ));

        controller = new CasoController(casoRepository,
                new InvestigacionCasoService(null, pistaRepository, descubrimientoRepository, null, null, null),
                new ResolucionCasoService(sospechosoRepository, veredictoRepository, combateEnCursoRepository),
                null, new UsuarioContexto(usuarioRepository));
    }

    @Test
    void acusarSospechosoSinAtaquesRegistraVeredictoDirectoYMarcaAccionReciente() {
        sospechosos.put(5L, sospechoso(5L, Arrays.asList()));
        RedirectAttributesModelMap redirectAttributes = new RedirectAttributesModelMap();

        String vista = controller.acusar(CASO_ID, 5L, authentication, redirectAttributes);

        assertEquals("redirect:/casos/" + CASO_ID, vista);
        assertTrue(veredictosPorCaso.containsKey(CASO_ID));
        assertTrue(combatesGuardados.isEmpty());
        assertEquals("acusacion", redirectAttributes.getFlashAttributes().get("accionReciente"));
    }

    @Test
    void acusarSospechosoConAtaquesIniciaCombateEnLugarDeVeredicto() {
        sospechosos.put(6L, sospechoso(6L, Arrays.asList("Primer ataque", "Segundo ataque")));
        RedirectAttributesModelMap redirectAttributes = new RedirectAttributesModelMap();

        controller.acusar(CASO_ID, 6L, authentication, redirectAttributes);

        assertFalse(veredictosPorCaso.containsKey(CASO_ID));
        assertEquals(1, combatesGuardados.size());
        assertEquals("acusacion", redirectAttributes.getFlashAttributes().get("accionReciente"));
    }

    @Test
    void finalizarCombateRegistraVeredictoYBorraElCombateGaneOPierdaElJugador() {
        Sospechoso sospechoso = sospechoso(6L, Arrays.asList("Primer ataque", "Segundo ataque"));
        CombateEnCurso combate = new CombateEnCurso();
        combate.setUsuario(usuario);
        combate.setCaso(caso);
        combate.setSospechoso(sospechoso);
        combatesPorCaso.put(CASO_ID, combate);
        RedirectAttributesModelMap redirectAttributes = new RedirectAttributesModelMap();

        String vista = controller.finalizarCombate(CASO_ID, authentication, redirectAttributes);

        assertEquals("redirect:/casos/" + CASO_ID, vista);
        assertTrue(veredictosPorCaso.containsKey(CASO_ID));
        assertEquals(sospechoso, veredictosPorCaso.get(CASO_ID).getSospechoso());
        assertFalse(combatesPorCaso.containsKey(CASO_ID));
    }

    @Test
    void finalizarCombateSinCombatePendienteEsNoOpSinExcepcion() {
        // Doble POST (doble clic tras respuesta lenta): el combate ya se
        // resolvió y borró; el segundo envío no debe petar con 500 (#39)
        // ni registrar un segundo veredicto.
        RedirectAttributesModelMap redirectAttributes = new RedirectAttributesModelMap();

        String vista = controller.finalizarCombate(CASO_ID, authentication, redirectAttributes);

        assertEquals("redirect:/casos/" + CASO_ID, vista);
        assertFalse(veredictosPorCaso.containsKey(CASO_ID));
    }

    @Test
    void acusarEnCasoConfidencialSinSerAdminEsDenegado() {
        caso.setConfidencial(true);
        sospechosos.put(5L, sospechoso(5L, Arrays.asList()));
        RedirectAttributesModelMap redirectAttributes = new RedirectAttributesModelMap();

        String vista = controller.acusar(CASO_ID, 5L, authentication, redirectAttributes);

        assertEquals("redirect:/", vista);
        assertFalse(veredictosPorCaso.containsKey(CASO_ID));
        assertTrue(combatesGuardados.isEmpty());
        assertEquals("Solicitud denegada. Nivel de acreditación insuficiente para este expediente.",
                redirectAttributes.getFlashAttributes().get("mensaje"));
    }

    @Test
    void acusarSospechosoDeOtroCasoEsDenegado() {
        // El caso de la ruta (CASO_ID) es público y pasa el control de acceso,
        // pero el sospechoso pertenece a otro caso (p.ej. uno confidencial).
        // No debe poder acusarse: sería saltarse el guard de acceso.
        sospechosos.put(9L, sospechosoDeCaso(9L, Arrays.asList(), 99L));
        RedirectAttributesModelMap redirectAttributes = new RedirectAttributesModelMap();

        String vista = controller.acusar(CASO_ID, 9L, authentication, redirectAttributes);

        assertEquals("redirect:/", vista);
        assertFalse(veredictosPorCaso.containsKey(CASO_ID));
        assertTrue(combatesGuardados.isEmpty());
        assertEquals("Solicitud denegada. Nivel de acreditación insuficiente para este expediente.",
                redirectAttributes.getFlashAttributes().get("mensaje"));
    }

    @Test
    void finalizarCombateMarcaAccionRecienteComoAcusar() {
        // La penalización por acusación precipitada se juzga en el cliente con
        // la marca accionReciente; el cierre vía combate debe emitirla igual
        // que la acusación directa, o acusar con cartas nunca costaría vida.
        Sospechoso sospechoso = sospechoso(6L, Arrays.asList("Primer ataque"));
        CombateEnCurso combate = new CombateEnCurso();
        combate.setUsuario(usuario);
        combate.setCaso(caso);
        combate.setSospechoso(sospechoso);
        combatesPorCaso.put(CASO_ID, combate);
        RedirectAttributesModelMap redirectAttributes = new RedirectAttributesModelMap();

        controller.finalizarCombate(CASO_ID, authentication, redirectAttributes);

        assertEquals("acusacion", redirectAttributes.getFlashAttributes().get("accionReciente"));
    }

    @Test
    void combinarEnCasoConfidencialSinSerAdminEsDenegado() {
        caso.setConfidencial(true);
        RedirectAttributesModelMap redirectAttributes = new RedirectAttributesModelMap();

        String vista = controller.combinar(CASO_ID, Arrays.asList(1L, 2L), authentication, redirectAttributes);

        assertEquals("redirect:/", vista);
        assertEquals("Solicitud denegada. Nivel de acreditación insuficiente para este expediente.",
                redirectAttributes.getFlashAttributes().get("mensaje"));
    }

    @Test
    void finalizarCombateEnCasoConfidencialSinSerAdminEsDenegado() {
        caso.setConfidencial(true);
        Sospechoso sospechoso = sospechoso(6L, Arrays.asList("Primer ataque", "Segundo ataque"));
        CombateEnCurso combate = new CombateEnCurso();
        combate.setUsuario(usuario);
        combate.setCaso(caso);
        combate.setSospechoso(sospechoso);
        combatesPorCaso.put(CASO_ID, combate);
        RedirectAttributesModelMap redirectAttributes = new RedirectAttributesModelMap();

        String vista = controller.finalizarCombate(CASO_ID, authentication, redirectAttributes);

        assertEquals("redirect:/", vista);
        assertFalse(veredictosPorCaso.containsKey(CASO_ID));
        assertTrue(combatesPorCaso.containsKey(CASO_ID));
        assertEquals("Solicitud denegada. Nivel de acreditación insuficiente para este expediente.",
                redirectAttributes.getFlashAttributes().get("mensaje"));
    }

    @Test
    void acusarDeNuevoCuandoYaHayVeredictoNoHaceNadaNiMarcaAccionReciente() {
        com.legado.expediente.model.Veredicto existente = new com.legado.expediente.model.Veredicto();
        veredictosPorCaso.put(CASO_ID, existente);
        sospechosos.put(5L, sospechoso(5L, Arrays.asList()));
        RedirectAttributesModelMap redirectAttributes = new RedirectAttributesModelMap();

        controller.acusar(CASO_ID, 5L, authentication, redirectAttributes);

        assertEquals(existente, veredictosPorCaso.get(CASO_ID));
        assertTrue(combatesGuardados.isEmpty());
        assertNull(redirectAttributes.getFlashAttributes().get("accionReciente"));
    }

    @Test
    void descubrirPistaDeOtroCasoEsDenegadoSinGuardar() {
        Pista pista = pista(40L);
        Caso otro = new Caso();
        otro.setId(99L);
        pista.setCaso(otro);
        RedirectAttributesModelMap mensajes = new RedirectAttributesModelMap();

        assertEquals("redirect:/", controller.descubrirPista(CASO_ID, 40L, authentication, mensajes));
        assertTrue(descubrimientos.isEmpty());
        assertNull(mensajes.getFlashAttributes().get("pistaDescubiertaId"));
    }

    @Test
    void descubrirPistaConfidencialExigeAdmin() {
        caso.setConfidencial(true);
        pista(40L);
        assertEquals("redirect:/", controller.descubrirPista(
                CASO_ID, 40L, authentication, new RedirectAttributesModelMap()));
        assertTrue(descubrimientos.isEmpty());

        usuario.setRol(Rol.ADMIN);
        assertEquals("redirect:/casos/" + CASO_ID, controller.descubrirPista(
                CASO_ID, 40L, authentication, new RedirectAttributesModelMap()));
        assertEquals(1, descubrimientos.size());
    }

    @Test
    void descubrirDosVecesConservaUnSoloDescubrimientoYElMensaje() {
        Pista pista = pista(40L);
        controller.descubrirPista(CASO_ID, 40L, authentication, new RedirectAttributesModelMap());
        RedirectAttributesModelMap mensajes = new RedirectAttributesModelMap();
        assertEquals("redirect:/casos/" + CASO_ID,
                controller.descubrirPista(CASO_ID, 40L, authentication, mensajes));
        assertEquals(1, descubrimientos.size());
        assertEquals(usuario, descubrimientos.get(0).getUsuario());
        assertEquals(pista, descubrimientos.get(0).getPista());
        assertEquals("Pista añadida a tu carpeta.", mensajes.getFlashAttributes().get("mensaje"));
        assertEquals(40L, mensajes.getFlashAttributes().get("pistaDescubiertaId"));
    }

    @Test
    void combinarRegistraLaConclusionUnaVezYDistingueElDuplicado() {
        combinacion = pista(41L);
        RedirectAttributesModelMap primera = new RedirectAttributesModelMap();
        assertEquals("redirect:/casos/" + CASO_ID,
                controller.combinar(CASO_ID, List.of(1L, 2L), authentication, primera));
        assertEquals("Nueva conclusión anotada al expediente.", primera.getFlashAttributes().get("mensaje"));
        assertEquals(41L, primera.getFlashAttributes().get("pistaDescubiertaId"));
        RedirectAttributesModelMap segunda = new RedirectAttributesModelMap();
        controller.combinar(CASO_ID, List.of(1L, 2L), authentication, segunda);
        assertEquals("Esa conclusión ya estaba anotada.", segunda.getFlashAttributes().get("mensaje"));
        assertNull(segunda.getFlashAttributes().get("pistaDescubiertaId"));
        assertEquals(1, descubrimientos.size());
    }

    @Test
    void combinarSinRelacionNoGuardaDescubrimientos() {
        RedirectAttributesModelMap mensajes = new RedirectAttributesModelMap();
        controller.combinar(CASO_ID, List.of(1L, 2L), authentication, mensajes);
        assertEquals("No encuentra ninguna relación entre esos documentos.", mensajes.getFlashAttributes().get("mensaje"));
        assertTrue(descubrimientos.isEmpty());
    }

    @Test
    void combinarExigeExactamenteDosDocumentos() {
        for (List<Long> ids : Arrays.asList(null, List.<Long>of(), List.of(1L), List.of(1L, 2L, 3L))) {
            RedirectAttributesModelMap mensajes = new RedirectAttributesModelMap();
            assertEquals("redirect:/casos/" + CASO_ID, controller.combinar(CASO_ID, ids, authentication, mensajes));
            assertEquals("Selecciona exactamente dos documentos para combinarlos.",
                    mensajes.getFlashAttributes().get("mensaje"));
        }
        assertTrue(descubrimientos.isEmpty());
    }

    @Test
    void acusarConCombatePendienteNoLoSustituyeNiMarcaOtraAccion() {
        Sospechoso sospechoso = sospechoso(6L, List.of("Ataque"));
        sospechosos.put(6L, sospechoso);
        CombateEnCurso pendiente = new CombateEnCurso();
        pendiente.setCaso(caso);
        pendiente.setSospechoso(sospechoso);
        combatesPorCaso.put(CASO_ID, pendiente);
        RedirectAttributesModelMap mensajes = new RedirectAttributesModelMap();
        controller.acusar(CASO_ID, 6L, authentication, mensajes);
        assertEquals(pendiente, combatesPorCaso.get(CASO_ID));
        assertTrue(combatesGuardados.isEmpty());
        assertTrue(veredictosPorCaso.isEmpty());
        assertNull(mensajes.getFlashAttributes().get("accionReciente"));
    }

    private Pista pista(Long id) {
        Pista pista = new Pista();
        pista.setId(id);
        pista.setCaso(caso);
        pistas.put(id, pista);
        return pista;
    }

    private Sospechoso sospechoso(Long id, List<String> ataques) {
        return sospechosoDeCaso(id, ataques, CASO_ID);
    }

    private Sospechoso sospechosoDeCaso(Long id, List<String> ataques, Long casoId) {
        Sospechoso sospechoso = new Sospechoso();
        sospechoso.setId(id);
        Caso casoDelSospechoso = new Caso();
        casoDelSospechoso.setId(casoId);
        sospechoso.setCaso(casoDelSospechoso);
        sospechoso.setAtaques(ataques);
        return sospechoso;
    }

    @SuppressWarnings("unchecked")
    private <T> T fake(Class<T> tipo, Map<String, java.util.function.Function<Object[], Object>> handlers) {
        return (T) Proxy.newProxyInstance(tipo.getClassLoader(), new Class<?>[]{tipo}, (proxy, method, args) -> {
            if ("toString".equals(method.getName())) {
                return "Fake" + tipo.getSimpleName();
            }
            java.util.function.Function<Object[], Object> handler = handlers.get(method.getName());
            if (handler != null) {
                return handler.apply(args);
            }
            return defaultValue(method.getReturnType());
        });
    }

    private Object defaultValue(Class<?> returnType) {
        if (returnType == boolean.class) {
            return false;
        }
        if (returnType == int.class) {
            return 0;
        }
        if (returnType == long.class) {
            return 0L;
        }
        return null;
    }
}
