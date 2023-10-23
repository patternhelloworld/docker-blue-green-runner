package com.runner.spring.sample.microservice.auth.user.entity;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.runner.spring.sample.microservice.auth.role.entity.Role;
import lombok.Getter;
import lombok.Setter;

import javax.persistence.*;

import javax.persistence.Entity;
import javax.persistence.Table;


@Getter
@Setter
@Entity
@Table(name ="spring_sample_h_auth.user_role")
public class UserRole {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id")
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    private User user;

    @ManyToOne
    @JoinColumn(name = "role_id")
    private Role role;

}
