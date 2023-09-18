package com.runner.spring.sample.config.security.bean;

import com.runner.spring.sample.microservice.auth.role.entity.Role;
import com.runner.spring.sample.util.CommonConstant;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import javax.validation.ConstraintValidator;
import javax.validation.ConstraintValidatorContext;
import java.util.Set;

@Component
@RequiredArgsConstructor
public class ForbiddenSuperAdminValidator implements ConstraintValidator<ForbiddenSuperAdmin, Set<Role>> {
    @Override
    public boolean isValid(Set<Role> userRoles, ConstraintValidatorContext context) {

        if(userRoles != null) {
            for (Role role : userRoles) {
                if (role.getName().equals(CommonConstant.SUPER_ADMIN_ROLE_NAME)) {
                    return false;
                }
            }
        }
        return true;
    }
}
