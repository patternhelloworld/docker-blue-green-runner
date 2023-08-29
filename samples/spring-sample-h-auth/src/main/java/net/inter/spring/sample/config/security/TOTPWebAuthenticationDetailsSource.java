package net.inter.spring.sample.config.security;

import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;

import javax.servlet.http.HttpServletRequest;
// ID, Password 이외에도 추가로 파라미터를 전달 하여 인증 과정 속에서 활용하거나 인증 이후에 이 정보들을 참조하여 사용자가 서버에 접근할 수 있도록 만들고자 할때,
public class TOTPWebAuthenticationDetailsSource extends WebAuthenticationDetailsSource {
    @Override
    public TOTPWebAuthenticationDetails buildDetails(HttpServletRequest request) {
        return new TOTPWebAuthenticationDetails(request);
    }
}