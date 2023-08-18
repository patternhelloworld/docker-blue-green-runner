package net.inter.spring.sample.config.interceptor;

import net.inter.spring.sample.config.logger.LogConfig;
import net.inter.spring.sample.exception.CustomExceptionUtils;
import net.inter.spring.sample.config.security.bean.AccessTokenUserInfo;
import net.inter.spring.sample.util.CommonConstant;
import org.hibernate.EmptyInterceptor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestAttributes;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.Optional;

@Component
public class HibernateInterceptor extends EmptyInterceptor {

    private static final Logger logger = LoggerFactory.getLogger(LogConfig.class);

    @Override
    public String onPrepareStatement(String sql) {

        Authentication authentication = Optional.ofNullable(SecurityContextHolder.getContext().getAuthentication()).orElse(null);
        if(authentication != null){

            try {

                ServletRequestAttributes servletRequestAttributes = (ServletRequestAttributes)RequestContextHolder.getRequestAttributes();

                if(servletRequestAttributes != null) {

                    // 해당 REQUEST에서 지정한 organization_id를 확인 (이는 슈퍼 어드민과 조직 어드민이 공통으로 사용하는 API로 인해 발생)
                    Long tableNum = Optional.ofNullable((Long) servletRequestAttributes
                            .getAttribute(CommonConstant.DYNAMIC_TABLE_NUM_SYMBOL, RequestAttributes.SCOPE_REQUEST)).orElse(null);
                    if (tableNum == null) {

                        // 없다면 현재의 access_token에 해당하는 사용자의 조직으로 진행
                        if (authentication.getPrincipal() != null && authentication.getPrincipal() instanceof AccessTokenUserInfo) {
                            AccessTokenUserInfo accessTokenUserInfo = (AccessTokenUserInfo) authentication.getPrincipal();
                            tableNum = accessTokenUserInfo.getOrganization_id();
                        }
                    }

                    if (tableNum != null) {
                        // unsafe
                        sql = sql.replaceAll("(?i)samplewave_resource.workspaces", "samplewave_resource.workspaces_" + tableNum);
                        sql = sql.replaceAll("(?i)samplewave_resource.user_workspace", "samplewave_resource.user_workspace_" + tableNum);
                        sql = sql.replaceAll("(?i)samplewave_resource.binders", "samplewave_resource.binders_" + tableNum);
                        sql = sql.replaceAll("(?i)samplewave_resource.user_binder", "samplewave_resource.user_binder_" + tableNum);
                   //     sql = sql.replaceAll("(?i)sample_h_auth.users", "sample_h_auth.users_" + tableNum);
                    }

                }

            }catch (Exception ex){
                 CustomExceptionUtils.createNonStoppableErrorMessage(ex.getMessage(), ex);
            }
        }

        return sql;
    }

}
