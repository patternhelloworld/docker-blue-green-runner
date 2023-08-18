package net.inter.spring.sample.microservice.resource.model.entity;

import lombok.Getter;
import lombok.Setter;
import net.inter.spring.sample.microservice.resource.brand.entity.Brand;

import javax.persistence.*;

@Table(name="sample_h_resource.model")
@Entity
@Getter
@Setter
public class Model {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private Integer active;

    @ManyToOne
    private Brand brand;
}
