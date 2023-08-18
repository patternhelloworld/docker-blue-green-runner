package net.inter.spring.sample.config.security.crypto;

import org.springframework.security.crypto.argon2.Argon2PasswordEncoder;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.DelegatingPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.crypto.password.Pbkdf2PasswordEncoder;
import org.springframework.security.crypto.scrypt.SCryptPasswordEncoder;

import java.util.HashMap;
import java.util.Map;
import java.util.regex.Pattern;


/*
 *   KISA 의 권고에 따라 Bcrypt 를 사용하지 않고 SHA-256 을 사용하기로 하였으며, 확장성을 위해 idForEncode 추후 SHA-256 말고 다른 알고리즘도 사용할 수 있게 함.
 *   다른 암호화 알고리즘을 사용할 경우 생성자에 다른 값을 넣으면 됨.
 * */
public class MultiplePasswordEncoder implements PasswordEncoder {

    private final IdForPasswordEncoder idForPasswordEncoder;
    private final Map<String, PasswordEncoder> encoders;

    public MultiplePasswordEncoder(IdForPasswordEncoder idForPasswordEncoder) {

        this.idForPasswordEncoder = idForPasswordEncoder;

        // org.springframework.security.crypto.factory.PasswordEncoderFactories 참조
        this.encoders = new HashMap<>();

        this.encoders.put(IdForPasswordEncoder.ldap.getId(), new org.springframework.security.crypto.password.LdapShaPasswordEncoder());
        this.encoders.put(IdForPasswordEncoder.MD4.getId(), new org.springframework.security.crypto.password.Md4PasswordEncoder());
        this.encoders.put(IdForPasswordEncoder.MD5.getId(), new org.springframework.security.crypto.password.MessageDigestPasswordEncoder(IdForPasswordEncoder.MD5.getId()));
        this.encoders.put(IdForPasswordEncoder.noop.getId(), org.springframework.security.crypto.password.NoOpPasswordEncoder.getInstance());
        this.encoders.put(IdForPasswordEncoder.pbkdf2.getId(), new Pbkdf2PasswordEncoder());
        this.encoders.put(IdForPasswordEncoder.scrypt.getId(), new SCryptPasswordEncoder());
        this.encoders.put(IdForPasswordEncoder.SHA1.getId(), new org.springframework.security.crypto.password.MessageDigestPasswordEncoder(IdForPasswordEncoder.SHA1.getId()));
        this.encoders.put(IdForPasswordEncoder.SHA256.getId(), new org.springframework.security.crypto.password.MessageDigestPasswordEncoder(IdForPasswordEncoder.SHA256.getId()));
        this.encoders.put(IdForPasswordEncoder.sha256.getId(), new org.springframework.security.crypto.password.StandardPasswordEncoder());
        this.encoders.put(IdForPasswordEncoder.argon2.getId(), new Argon2PasswordEncoder());
        this.encoders.put(IdForPasswordEncoder.bcrypt.getId(), new BCryptPasswordEncoder());

    }

    private PasswordEncoder createDelegatingPasswordEncoderForId(String idForEncode) {
        return new DelegatingPasswordEncoder(idForEncode, this.encoders);
    }


    /*
     *   패스워드 신규 생성 시 마다 호출되는 함수
     * */
    @Override
    public String encode(CharSequence rawPassword) {
        return createDelegatingPasswordEncoderForId(idForPasswordEncoder.getId()).encode(rawPassword);
    }

    /*
     *   로그인 시 마다 호출되는 함수 (라이브러리가 상기 encoders 에 해당하는 알고리즘들을 모두 대입해서 찾으므로 여러번 호출 됨)
     *   과거 Bcrypt 를 사용하였던 패스워드 또한 로그인 시 유효하여야 하며, 새로운 알고리즘인 SHA-256 으로 생성된 패스워드도 유효해야 한다.
     * */
    @Override
    public boolean matches(CharSequence rawPassword, String encodedPassword) {

        // org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder 를 가져다 씀. private 이라 접근 불가.
        Pattern BCRYPT_PATTERN = Pattern
                .compile("\\A\\$2(a|y|b)?\\$(\\d\\d)\\$[./0-9A-Za-z]{53}");
        String PREFIX = "{";
        String SUFFIX = "}";

        if (encodedPassword.startsWith(PREFIX + IdForPasswordEncoder.bcrypt.getId() + SUFFIX) || BCRYPT_PATTERN.matcher(encodedPassword).matches()) {
            return new BCryptPasswordEncoder().matches(rawPassword, encodedPassword);
        } else {
            for (Map.Entry<String, PasswordEncoder> entry : this.encoders.entrySet()) {
                if (encodedPassword.startsWith(PREFIX + entry.getKey() + SUFFIX)) {
                    return createDelegatingPasswordEncoderForId(entry.getKey()).matches(rawPassword, encodedPassword);
                }
            }
            throw new IllegalArgumentException("Invalid algorithm '" + idForPasswordEncoder.getId() + "'. (encodedPassword : " + encodedPassword + ")");
        }

    }


}