package com.legado.expediente.repository;

import com.legado.expediente.model.PuntuacionGolf;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PuntuacionGolfRepository extends JpaRepository<PuntuacionGolf, Long> {

    List<PuntuacionGolf> findTop50ByOrderByGolpesAscCreadoEnAsc();
}
