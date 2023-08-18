package net.inter.spring.sample.microservice.resource.task.entity;

import lombok.Getter;
import lombok.Setter;
import net.inter.spring.sample.microservice.resource.pdiprocess.PdiProcess;

import javax.persistence.*;

@Table(name="sample_h_resource.task")
@Entity
@Getter
@Setter
public class Task {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private Integer active;
    private String imagePath;
    private Double hourlyRate;
    private Double hourlyGuaranteePrice;
    private Double laborExchangeRate;
    private Double partOutsideRate;

    @ManyToOne
    private PdiProcess pdiProcess;
}
