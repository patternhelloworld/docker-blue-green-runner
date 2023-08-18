package net.inter.spring.sample.microservice.resource.manufacturer.entity;

import lombok.Getter;
import lombok.Setter;
import net.inter.spring.sample.microservice.resource.locationdetail.entity.LocationDetail;
import net.inter.spring.sample.microservice.resource.locationgroup.entity.LocationGroup;

import javax.persistence.*;

@Table(name="sample_h_resource.manufacturer")
@Entity
@Getter
@Setter
public class Manufacturer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private String stockLocation;
    private String stockCheckCode;
    private String releaseCheckCode;
    private String periodicCheckPeriod;
    private Integer active;
    private String imagePath;

    @ManyToOne
    private LocationGroup locationGroup;

    @ManyToOne
    private LocationDetail locationDetail;
}