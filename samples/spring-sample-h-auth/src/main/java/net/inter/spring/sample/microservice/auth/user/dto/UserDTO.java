package net.inter.spring.sample.microservice.auth.user.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import net.inter.spring.sample.microservice.auth.user.entity.Password;
import net.inter.spring.sample.microservice.auth.user.entity.User;
import net.inter.spring.sample.microservice.auth.role.entity.Role;

import javax.validation.Valid;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotEmpty;
import java.sql.Timestamp;
import java.util.Set;

public class UserDTO {

    @Getter
    @NoArgsConstructor(access = AccessLevel.PROTECTED)
    public static class UserCreateReq {

        @Valid
        private String email;
        @NotEmpty
        public String name;

        private String password;

        @Builder
        public UserCreateReq(String email, String name, String password) {
            this.email = email;
            this.name = name;
            this.password = password;
        }

        public User toEntity() {
            return User.builder()
                    .email(this.email)
                    .name(this.name)
                    .password(Password.builder().value(this.password).build())
                    .build();
        }

    }

    @Getter
    @NoArgsConstructor(access = AccessLevel.PROTECTED)
    public static class UserUpdateReq {

        //@Valid
        private String email;

        @NotBlank(message = "이름은 비어있으면 안됩니다.")
        public String name;

        private Set<Role> roles;
        private String active;


        @Builder
        public UserUpdateReq(String email, String name, Set<Role> roles, String active) {
            this.email = email;
            this.name = name;
            this.roles = roles;
            this.active = active;
        }

    }

    @Getter
    public static class Res {

        private Long id;
        private String email;
        private String name;
        @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
        private Timestamp createdAt;
        @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
        private Timestamp updatedAt;

        public Res(User user) {
            this.id = user.getId();
            this.email = user.getEmail();
            this.name = user.getName();
            this.createdAt = user.getCreatedAt();
            this.updatedAt = user.getUpdatedAt();
        }
    }
}
