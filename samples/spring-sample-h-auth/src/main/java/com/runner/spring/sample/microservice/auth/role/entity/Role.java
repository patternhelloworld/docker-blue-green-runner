package com.runner.spring.sample.microservice.auth.role.entity;

import lombok.*;

import javax.persistence.*;
import javax.validation.constraints.NotEmpty;

@Entity
@Getter
@Table(name = "spring_sample_h_auth.role")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Role  {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    @NotEmpty
    private String name;

    private String description;

    @Builder
    public Role(Long id, String name, String description) {
        this.id = id;
        this.name = name;
        this.description = description;
    }
}

