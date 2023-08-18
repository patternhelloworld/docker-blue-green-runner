package net.inter.spring.sample.microservice.resource.department.entity;

import lombok.Getter;
import lombok.Setter;

import javax.persistence.*;

@Table(name="sample_h_resource.department")
@Entity
@Getter
@Setter
public class Department {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private Integer active;

}