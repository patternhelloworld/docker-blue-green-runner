package net.inter.spring.sample.microservice.auth.user.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UserSearchFilter {

    private String email;
    private String name;
    @JsonProperty("customGroup.groupName")
    private String CustomGroupName;
    @JsonProperty("organization.name")
    private String organizationName;
    private Long organizationId;

}
