package net.inter.spring.sample.microservice.resource.pdiprocess;


import lombok.Getter;
import lombok.Setter;
import net.inter.spring.sample.microservice.resource.manufacturer.entity.Manufacturer;

import javax.persistence.*;

@Table(name="sample_h_resource.pdi_process")
@Entity
@Getter
@Setter
public class PdiProcess {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private Integer orderNum;
    private String name;
    private Integer active;

    @ManyToOne
    private Manufacturer manufacturer;
}
