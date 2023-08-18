package net.inter.spring.sample.microservice.auth.user.dto;

public class Email {

    @javax.validation.constraints.Email
    private String toAddress;

    public String getToAddress() {
        return toAddress;
    }

    public void setToAddress(String toAddress) {
        this.toAddress = toAddress;
    }
}
