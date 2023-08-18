package net.inter.spring.sample.microservice.resource.locationgroup.entity;

import lombok.Getter;
import lombok.Setter;

import javax.persistence.*;

@Table(name="sample_h_resource.location_group")
@Entity
@Getter
@Setter
public class LocationGroup {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private Integer active;
}
