package net.inter.spring.sample.config.security;

import net.inter.spring.sample.exception.auth.UnauthorizedException;
import net.inter.spring.sample.exception.data.NoDynamicTableFoundException;
import net.inter.spring.sample.microservice.auth.user.dao.UserRepository;
import net.inter.spring.sample.microservice.auth.user.entity.User;
import net.inter.spring.sample.config.security.bean.AccessTokenUserInfo;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.AfterThrowing;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.BadSqlGrammarException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Component;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Aspect
@Component
public class AuthConfig {

    @Autowired
    private UserRepository userRepository;

    private static final Logger logger = LoggerFactory.getLogger(AuthConfig.class);

    @AfterThrowing(pointcut = ("within(net.inter.spring.sample..*)"), throwing = "e")
    public void handleDynamicTableException(JoinPoint joinPoint, BadSqlGrammarException e) throws Throwable {

        String cause = e.getCause().toString();
        String tableNumber = null;

        Pattern p = Pattern.compile("'samplewave_resource\\..+_([0-9]+)' doesn't exist");
        Matcher m = p.matcher(cause);
        if(m.find()){
            tableNumber = m.group(1);
            throw new NoDynamicTableFoundException("tableNumber not found : " + tableNumber, e);
        }

        throw e;
    }

    @Around("@annotation(net.inter.spring.sample.config.security.bean.AccessTokenUserInfoValidator)")
    public Object checkAccessTokenUserInfoValidator(ProceedingJoinPoint joinPoint) throws Throwable {
        for (Object object : joinPoint.getArgs()) {
            if(object != null && object.getClass().equals(AccessTokenUserInfo.class)){
                 AccessTokenUserInfo accessTokenUserInfo = (AccessTokenUserInfo) object;
                if(accessTokenUserInfo.getOrganization_id() == null){
//                    throw new AccessTokenUserInfoUnauthorizedException("organization_id 가 null 입니다. (해당 사용자의 조직이 설정되지 않았습니다.)");
                }
            }
        }
        return joinPoint.proceed();
    }

    @Around("within(net.inter.spring.sample..*) && " +
            "args(authenticatedUser, ..)"
    )
    public Object withAuthenticatedUser(ProceedingJoinPoint joinPoint, User authenticatedUser) throws Throwable {
        // System.out.println(joinPoint + " -> " + authenticatedUser);

        User user = null;
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null) {
            user = userRepository.findByEmail(authentication.getName())
                    .orElseThrow(() -> new UsernameNotFoundException("Email : " + authentication.getName() + " not found"));
            if(user.getPassword() == null){
                throw new UsernameNotFoundException("no user password");
            }
        }else{
            throw new UnauthorizedException("인증된 사용자가 아닙니다.");
        }

        if(user == null){
            throw new UnauthorizedException("사용자 (" + authentication.getName() + ")를 persistence에서 찾을 수 없습니다.");
        }

        return joinPoint.proceed(new Object[]{user});
    }


}