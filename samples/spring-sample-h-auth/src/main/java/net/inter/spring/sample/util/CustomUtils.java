package net.inter.spring.sample.util;

import net.inter.spring.sample.config.logger.LogConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.security.SecureRandom;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.*;

public class CustomUtils {

    private static final Logger logger = LoggerFactory.getLogger(LogConfig.class);


    public static boolean isEmpty(Object obj) {
        if (obj == null) { return true; }
        if ((obj instanceof String) && (((String)obj).trim().length() == 0)) { return true; }
        if (obj instanceof Map) { return ((Map<?, ?>)obj).isEmpty(); }
        if (obj instanceof List) { return ((List<?>)obj).isEmpty(); }
        if (obj instanceof Object[]) { return (((Object[])obj).length == 0); }

        return false;
    }

    public static String createUUID(){
        return UUID.randomUUID().toString().replace("-", "");
    }

    public static String createSequentialUUIDStringReplaceHyphen(){
        return CustomUtils.createSequentialUUIDString().replace("-", "");
    }

    public static String createSequentialUUIDString(){
        byte[] randomBytes = new byte[10];
        SecureRandom secureRandom = new SecureRandom();

        secureRandom.nextBytes(randomBytes);

        long timestamp = Instant.now().getEpochSecond() / 10000L;

        byte[] timestampBytes = BitConverter.getBytes(timestamp);

        if(BitConverter.IsLittleEndian())
            Collections.reverse(Arrays.asList(timestampBytes));

        byte[] guidBytes = new byte[16];

        System.arraycopy(timestampBytes, 2, guidBytes, 0, 6);
        System.arraycopy(randomBytes, 0, guidBytes, 6, 10);

        if (BitConverter.IsLittleEndian()) {
            // 0-3 reverse
            Reverse(guidBytes, 0, 4);
            // 4-5 reverse
            Reverse(guidBytes, 4, 2);
        }

        return UUID.nameUUIDFromBytes(guidBytes).toString();
    }

    public static void Reverse(byte[] contents, int index, int length){
        byte temp;
        for(int idx = index; idx < index + length; idx++){
            temp = contents[idx];
            contents[idx] = contents[contents.length - idx - 1];
            contents[contents.length - idx - 1] = temp;
        }
    }


    public static <T> Optional<T> getAsOptional(List<T> list, int index) {
        try {
            return Optional.of(list.get(index));
        } catch (ArrayIndexOutOfBoundsException e) {
            return Optional.empty();
        }
    }

    public static void createNonStoppableErrorMessage(String message, Throwable ex){
        logger.error("[NON-STOPPABLE ERROR] : " + message + " / "+ ex.getMessage() + " / " + ex.getStackTrace()[0] + " / Thread ID = " + Thread.currentThread().getId());
    }

    public static String getAllCauses(Throwable e, String causes) {
        if (e.getCause() == null) return causes;
        causes += e.getCause() + " / ";
        return getAllCauses(e.getCause(), causes);
    }


    public static Timestamp getCurrentDateTime(){
        //오늘날짜 가져온다.
        Calendar cal = new GregorianCalendar();
        //timestamp로 변환
        Timestamp currentDateTime = new Timestamp(cal.getTimeInMillis());
        return currentDateTime;
    }

    /*
    *  EX) localhost:8200 -> localhost:8082
    * */
    public static String changeAuth2ResourceDomain(String authDomain){
        return authDomain.replaceAll("8200$", "8082");
    }
}
