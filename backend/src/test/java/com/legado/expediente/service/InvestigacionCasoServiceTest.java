package com.legado.expediente.service;

import com.legado.expediente.model.Descubrimiento;
import com.legado.expediente.model.Pista;
import com.legado.expediente.model.RegistroLegado;
import com.legado.expediente.model.Usuario;
import com.legado.expediente.repository.DescubrimientoRepository;
import com.legado.expediente.repository.PistaRepository;
import com.legado.expediente.repository.RegistroLegadoRepository;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Proxy;
import java.util.List;
import java.util.Map;
import java.util.function.Function;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class InvestigacionCasoServiceTest {

    @Test
    void prepararConservaDocumentosHotspotsCartasYContadoresPorUsuario() {
        RegistroLegado registro = registro(1L, "ACTA-1999-014",
                "<dato> pista cinco minutos después de la hora de registro");
        RegistroLegado sinPista = registro(2L, "SIN-PISTA", "Documento sin pista");
        Pista directa = pista(10L, registro, null);
        directa.setFraseGatillo("pista");
        Pista conclusion = pista(11L, registro, sinPista);
        Pista pendiente = pista(12L, registro, sinPista);
        Usuario usuario = new Usuario();
        usuario.setId(7L);
        Descubrimiento descubierto = new Descubrimiento();
        descubierto.setPista(directa);
        Descubrimiento concluido = new Descubrimiento();
        concluido.setPista(conclusion);
        InvestigacionCasoService servicio = servicio(List.of(registro, sinPista),
                List.of(directa, conclusion, pendiente), List.of(descubierto, concluido));

        var vista = servicio.preparar(3L, usuario);

        assertEquals(3, vista.totalPistas());
        assertEquals(2, vista.pistasEncontradas());
        assertEquals(2, vista.totalConclusiones());
        assertEquals(1, vista.conclusionesEncontradas());
        assertEquals(2, vista.registros().size());
        assertEquals(registro, vista.registros().get(0).registro());
        assertEquals(10L, vista.registros().get(0).pista().id());
        assertTrue(vista.registros().get(0).pista().descubierta());
        String html = vista.registros().get(0).contenidoHtml();
        assertTrue(html.contains("&lt;dato&gt;"));
        assertTrue(html.contains("siga-hotspot-visto"));
        assertTrue(html.contains("la-justicia"));
        assertNull(vista.registros().get(1).pista());
        assertEquals("Documento sin pista", vista.registros().get(1).contenidoHtml());
        assertTrue(vista.conclusiones().get(0).descubierta());
        assertFalse(vista.conclusiones().get(1).descubierta());
    }

    @Test
    void prepararPistaPendienteMantieneElBotonDeDescubrimiento() {
        RegistroLegado registro = registro(1L, "OTRO", "Una pista pendiente");
        Pista pista = pista(10L, registro, null);
        pista.setFraseGatillo("pista");
        var vista = servicio(List.of(registro), List.of(pista), List.of()).preparar(3L, new Usuario());
        assertEquals(0, vista.pistasEncontradas());
        assertEquals(0, vista.totalConclusiones());
        assertFalse(vista.registros().get(0).pista().descubierta());
        assertTrue(vista.registros().get(0).contenidoHtml().contains("form-pista-10"));
    }

    @Test
    void prepararExpedienteVacioDevuelveListasYTotalesVacios() {
        var vista = servicio(List.of(), List.of(), List.of()).preparar(3L, new Usuario());
        assertTrue(vista.registros().isEmpty());
        assertTrue(vista.conclusiones().isEmpty());
        assertEquals(0, vista.totalPistas());
        assertEquals(0, vista.pistasEncontradas());
        assertEquals(0, vista.totalConclusiones());
        assertEquals(0, vista.conclusionesEncontradas());
    }

    private InvestigacionCasoService servicio(List<RegistroLegado> registros, List<Pista> pistas,
                                              List<Descubrimiento> descubrimientos) {
        RegistroLegadoRepository registroRepository = fake(RegistroLegadoRepository.class,
                Map.of("findByCasoId", args -> registros));
        PistaRepository pistaRepository = fake(PistaRepository.class, Map.of("findByCasoId", args -> pistas));
        DescubrimientoRepository descubrimientoRepository = fake(DescubrimientoRepository.class,
                Map.of("findByUsuarioId", args -> descubrimientos));
        return new InvestigacionCasoService(registroRepository, pistaRepository, descubrimientoRepository,
                new ProgresoService(descubrimientoRepository, pistaRepository), new HotspotService(), new CartaOcultaService());
    }

    private RegistroLegado registro(Long id, String folio, String contenido) {
        RegistroLegado registro = new RegistroLegado();
        registro.setId(id);
        registro.setFolio(folio);
        registro.setContenido(contenido);
        return registro;
    }

    private Pista pista(Long id, RegistroLegado origen, RegistroLegado segundo) {
        Pista pista = new Pista();
        pista.setId(id);
        pista.setDescripcion("Pista " + id);
        pista.setRegistroOrigen(origen);
        pista.setRegistroOrigen2(segundo);
        return pista;
    }

    private <T> T fake(Class<T> tipo, Map<String, Function<Object[], Object>> handlers) {
        return tipo.cast(Proxy.newProxyInstance(tipo.getClassLoader(), new Class<?>[]{tipo}, (proxy, method, args) -> {
            Function<Object[], Object> handler = handlers.get(method.getName());
            if (handler == null) {
                throw new AssertionError("Consulta inesperada: " + method.getName());
            }
            return handler.apply(args);
        }));
    }
}
