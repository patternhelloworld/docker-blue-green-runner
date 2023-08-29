package net.inter.spring.sample.microservice.auth.user.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateActiveStatus {

    private Long[] userIds;
    private String active;
    private Boolean isFullFix;

}
