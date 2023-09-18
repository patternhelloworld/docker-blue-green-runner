package com.runner.spring.sample.microservice.auth.organization.entity;

import lombok.Getter;
import lombok.Setter;


import javax.persistence.*;

@Entity
@Table(name = "spring_sample_h_auth.organization")
@Getter
@Setter
public class Organization  {

    @Id
    @GeneratedValue(strategy= GenerationType.IDENTITY)
    private Long id;

    @Column(columnDefinition = "varchar(255)")
    private String name;

    @Column(columnDefinition = "char(1)")
    private String active;

}
