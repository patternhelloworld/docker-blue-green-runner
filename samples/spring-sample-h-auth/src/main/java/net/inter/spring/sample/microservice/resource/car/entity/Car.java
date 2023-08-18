package net.inter.spring.sample.microservice.resource.car.entity;

import lombok.Getter;
import lombok.Setter;
import net.inter.spring.sample.microservice.resource.model.entity.Model;
import net.inter.spring.sample.microservice.resource.task.entity.Task;

import javax.persistence.*;
import java.util.Date;

@Table(name="sample_h_resource.car")
@Entity
@Getter
@Setter
public class Car {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String chassisNumber;
    private String commissionNumber;
    private String exteriorColor;
    private String interiorColor;
    private Date arrivalDate;

    @ManyToOne
    private Model model;

    @ManyToOne
    private Task task;
}

