package com.legado.expediente.service;

import com.legado.expediente.model.CombateEnCurso;
import com.legado.expediente.model.Sospechoso;
import com.legado.expediente.model.Usuario;
import com.legado.expediente.model.Veredicto;
import com.legado.expediente.repository.CombateEnCursoRepository;
import com.legado.expediente.repository.SospechosoRepository;
import com.legado.expediente.repository.VeredictoRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

/** Gestiona la acusación y el cierre de un expediente autorizado por el controlador. */
@Service
public class ResolucionCasoService {
    private final SospechosoRepository sospechosoRepository;
    private final VeredictoRepository veredictoRepository;
    private final CombateEnCursoRepository combateEnCursoRepository;

    public ResolucionCasoService(SospechosoRepository sospechosoRepository,
            VeredictoRepository veredictoRepository,
            CombateEnCursoRepository combateEnCursoRepository) {
        this.sospechosoRepository = sospechosoRepository;
        this.veredictoRepository = veredictoRepository;
        this.combateEnCursoRepository = combateEnCursoRepository;
    }

    public List<Sospechoso> sospechosos(Long casoId) {
        return sospechosoRepository.findByCasoId(casoId);
    }

    public Sospechoso buscarSospechoso(Long sospechosoId) {
        return sospechosoRepository.findById(sospechosoId).orElseThrow();
    }

    public Optional<Veredicto> veredicto(Usuario usuario, Long casoId) {
        return veredictoRepository.findByUsuarioIdAndCasoId(usuario.getId(), casoId);
    }

    public Optional<CombateEnCurso> combate(Usuario usuario, Long casoId) {
        return combateEnCursoRepository.findByUsuarioIdAndCasoId(usuario.getId(), casoId);
    }

    public boolean acusar(Usuario usuario, Sospechoso sospechoso) {
        Long casoId = sospechoso.getCaso().getId();
        boolean yaHayVeredicto = veredicto(usuario, casoId).isPresent();
        boolean yaHayCombate = combate(usuario, casoId).isPresent();
        if (yaHayVeredicto || yaHayCombate) {
            return false;
        }
        if (sospechoso.getAtaques().isEmpty()) {
            registrarVeredicto(usuario, sospechoso);
        } else {
            CombateEnCurso combate = new CombateEnCurso();
            combate.setUsuario(usuario);
            combate.setCaso(sospechoso.getCaso());
            combate.setSospechoso(sospechoso);
            combateEnCursoRepository.save(combate);
        }
        return true;
    }

    public void finalizar(Usuario usuario, CombateEnCurso combate) {
        registrarVeredicto(usuario, combate.getSospechoso());
        combateEnCursoRepository.delete(combate);
    }

    private void registrarVeredicto(Usuario usuario, Sospechoso sospechoso) {
        Veredicto veredicto = new Veredicto();
        veredicto.setUsuario(usuario);
        veredicto.setCaso(sospechoso.getCaso());
        veredicto.setSospechoso(sospechoso);
        veredictoRepository.save(veredicto);
    }
}
