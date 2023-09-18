package com.runner.spring.sample.util;

import com.runner.spring.sample.exception.ExceptionMessage;
import com.runner.spring.sample.exception.util.EncodingProcessException;
import org.apache.commons.lang3.StringUtils;

//import org.apache.commons.lang.StringUtils;

import java.io.UnsupportedEncodingException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;
import java.util.Date;
import java.util.Random;

public class HBEncUtil {
    public static String createOrganizationKey(){
        String sha256 = generateRandomSha256();

        return StringUtils.substring(sha256, 0, 8);
    }

    public static String generateRandomSha256() {
        Random random = new Random((new Date()).getTime());
        return generateRandomSha256(random);
    }

    public static String generateRandomSha256(Random random) {

        MessageDigest md;
        try {
            md = MessageDigest.getInstance("SHA-256");
        } catch (NoSuchAlgorithmException e) {
            throw new EncodingProcessException(ExceptionMessage.NO_SUCH_ALGORITHM);
        }
        String text = String.valueOf(random.nextLong());

        try {
            md.update(text.getBytes("UTF-8"));
        } catch (UnsupportedEncodingException e) {
            throw new EncodingProcessException(ExceptionMessage.UNSUPPORTED_ENCODINGE);
        }
        byte[] digest = md.digest();

        StringBuffer sb = new StringBuffer();
        for (int i = 0; i < digest.length; i++) {
            sb.append(Integer.toString((digest[i] & 0xff) + 0x100, 16).substring(1));
        }

        return sb.toString();
    }

    public static String createEncryptKey(String teamKey){
        MessageDigest md;
        try {
            md = MessageDigest.getInstance("MD5");

            byte[] inputBytes = teamKey.getBytes(StandardCharsets.US_ASCII);
            byte[] hash = md.digest(inputBytes);

            Swap(hash, 0, 10);
            Swap(hash, 0, 5);
            Swap(hash, 4, 13);
            Swap(hash, 8, 3);
            Swap(hash, 5, 9);
            Swap(hash, 15, 2);

            return Base64.getEncoder().encodeToString(hash);

        } catch (NoSuchAlgorithmException e) {
            return "";
        }
    }

    public static void Swap(byte[] array, int indexX, int indexY){
        array[indexX] ^= array[indexY] ^= array[indexX];
        array[indexY] ^= array[indexX];
    }
}
