package net.inter.spring.sample.config.security.crypto;

public enum IdForPasswordEncoder {

    bcrypt("bcrypt"),
    ldap("ldap"),
    MD4("MD4"),
    MD5("MD5"),
    noop("noop"),
    pbkdf2("pbkdf2"),
    scrypt("scrypt"),
    SHA1("SHA-1"),
    SHA256("SHA-256"),
    sha256("sha256"),
    argon2("argon2");

    private final String id;

    public String getId() {
        return id;
    }

    IdForPasswordEncoder(String id) {
        this.id = id;
    }
}
