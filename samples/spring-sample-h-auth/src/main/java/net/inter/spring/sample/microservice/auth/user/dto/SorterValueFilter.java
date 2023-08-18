package net.inter.spring.sample.microservice.auth.user.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class SorterValueFilter {
    private String column;
    private Boolean asc;
}
