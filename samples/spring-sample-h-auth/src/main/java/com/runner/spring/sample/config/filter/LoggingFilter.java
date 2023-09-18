package com.runner.spring.sample.config.filter;


import com.runner.spring.sample.util.PathUtils;
import org.apache.commons.lang3.StringUtils;
import org.springframework.web.util.ContentCachingRequestWrapper;

import javax.servlet.*;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;

//@Component
public class LoggingFilter implements Filter {

    public static final String[] NONE_SECURE_URLs = {
            "/",
            "/resources/**",
            "/webjars/**",
            "/assets/**",
//            "/oauth/authorize",
//            "/oauth/token",
//            "/login/**",
            "/oauth/check_token",
            "/**/favicon.ico",
    };

    private static final List<String> EXCLUDE_URLs = Arrays.asList(NONE_SECURE_URLs);


    @Override
    public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain chain)
            throws IOException, ServletException {
        if (servletRequest instanceof HttpServletRequest && servletResponse instanceof HttpServletResponse) {
            HttpServletRequest request = (HttpServletRequest) servletRequest;
//            HttpServletResponse response = (HttpServletResponse) servletResponse;

            if (PathUtils.matches(EXCLUDE_URLs, ((HttpServletRequest) servletRequest).getRequestURI())) {
                chain.doFilter(servletRequest, servletResponse);
                return;
            }

            HttpServletRequest requestToCache = new ContentCachingRequestWrapper(request);
//            HttpServletResponse responseToCache = new ContentCachingResponseWrapper(response);

            if (StringUtils.equalsIgnoreCase("/oauth/token-endpoint", ((HttpServletRequest) servletRequest).getRequestURI())) {
              //  httpLogInterceptor.sendLog(requestToCache);
            }

            chain.doFilter(requestToCache, servletResponse);
        } else {
            chain.doFilter(servletRequest, servletResponse);
        }


    }
}
