package com.runner.spring.sample.config.security;

import com.runner.spring.sample.config.security.bean.AccessTokenUserInfo;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

@Aspect
@Component
public class AuthConfig {

    private static final Logger logger = LoggerFactory.getLogger(AuthConfig.class);

    @Around("@annotation(com.runner.spring.sample.config.security.bean.AccessTokenUserInfoValidator)")
    public Object checkAccessTokenUserInfoValidator(ProceedingJoinPoint joinPoint) throws Throwable {
        for (Object object : joinPoint.getArgs()) {
            if(object != null && object.getClass().equals(AccessTokenUserInfo.class)){
                 AccessTokenUserInfo accessTokenUserInfo = (AccessTokenUserInfo) object;
             //   if(accessTokenUserInfo.getOrganization().getId() == null){
//                    throw new AccessTokenUserInfoUnauthorizedException("organization_id 가 null 입니다. (해당 사용자의 조직이 설정되지 않았습니다.)");
            //    }
            }
        }
        return joinPoint.proceed();
    }
}