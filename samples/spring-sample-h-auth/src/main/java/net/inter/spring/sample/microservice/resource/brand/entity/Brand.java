package net.inter.spring.sample.microservice.resource.brand.entity;

import lombok.Getter;
import lombok.Setter;
import net.inter.spring.sample.microservice.resource.manufacturer.entity.Manufacturer;

import javax.persistence.*;

@Table(name="sample_h_resource.brand")
@Entity
@Getter
@Setter
public class Brand {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private Integer active;

    @ManyToOne
    private Manufacturer manufacturer;
}