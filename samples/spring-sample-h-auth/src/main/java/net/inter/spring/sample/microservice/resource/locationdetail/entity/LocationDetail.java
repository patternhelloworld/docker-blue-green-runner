package net.inter.spring.sample.microservice.resource.locationdetail.entity;

import lombok.Getter;
import lombok.Setter;
import net.inter.spring.sample.microservice.resource.locationgroup.entity.LocationGroup;

import javax.persistence.*;

@Table(name="sample_h_resource.location_deatil")
@Entity
@Getter
@Setter
public class LocationDetail {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private Integer storageCount;
    private Integer padding;
    private Integer autoSort;
    private Integer sortMethod;
    private Integer visible;

    @ManyToOne
    private LocationGroup locationGroup;
}