package net.inter.spring.sample.util;

import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import javax.servlet.http.HttpServletRequest;
import java.math.BigInteger;
import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.UnknownHostException;

public class IPUtils {
    public static String getIP() {
        HttpServletRequest httpServletRequest =
                ((ServletRequestAttributes) RequestContextHolder.currentRequestAttributes())
                        .getRequest();
        String ip = httpServletRequest.getHeader("X-FORWARDED-FOR");
        if (ip == null)
            ip = httpServletRequest.getRemoteAddr();

        return ip;
    }

    public static String getIP(HttpServletRequest httpServletRequest) {
        String ip = httpServletRequest.getHeader("X-FORWARDED-FOR");
        if (ip == null)
            ip = httpServletRequest.getRemoteAddr();

        return ip;
    }

    public static String numberToIpv4(int ipNumber) {
        return ((ipNumber >> 24) & 0xFF) + "." +
                ((ipNumber >> 16) & 0xFF) + "." +
                ((ipNumber >> 8) & 0xFF) + "." +
                (ipNumber & 0xFF);
    }

    public static Long ipv4ToNumber(String addr) {
        String[] addrArray = addr.split("\\.");
        long num = 0;
        for (int i = 0; i < addrArray.length; i++) {
            int power = 3 - i;

            num += ((Integer.parseInt(addrArray[i]) % 256 * Math.pow(256, power)));
        }

        return num;
    }

    public static String numberToIPv6(BigInteger ipNumber) {
        String ipString = "";
        BigInteger a = new BigInteger("FFFF", 16);

        for (int i = 0; i < 8; i++) {
            ipString = ipNumber.and(a).toString(16) + ":" + ipString;

            ipNumber = ipNumber.shiftRight(16);
        }

        return ipString.substring(0, ipString.length() - 1);
    }

    public static BigInteger ipv6ToNumber(String addr) {
        int startIndex = addr.indexOf("::");

        if (startIndex != -1) {
            String firstStr = addr.substring(0, startIndex);
            String secondStr = addr.substring(startIndex + 2, addr.length());

            BigInteger first = ipv6ToNumber(firstStr);

            int x = countChar(addr, ':');

            first = first.shiftLeft(16 * (7 - x)).add(ipv6ToNumber(secondStr));

            return first;
        }

        String[] strArr = addr.split(":");
        BigInteger retValue = BigInteger.valueOf(0);

        for (String s : strArr) {
            BigInteger bi = new BigInteger(s, 16);
            retValue = retValue.shiftLeft(16).add(bi);
        }

        return retValue;
    }

    public static int countChar(String str, char reg) {
        char[] ch = str.toCharArray();
        int count = 0;
        for (int i = 0; i < ch.length; ++i) {
            if (ch[i] == reg) {
                if (ch[i + 1] == reg) {
                    ++i;
                    continue;
                }
                ++count;
            }
        }
        return count;
    }

    public static boolean isIpAddressV4(String addr) {
        boolean result = false;
        try {
            InetAddress address = InetAddress.getByName(addr);

            if (address instanceof Inet4Address) {
                result = true;
            }

        } catch (UnknownHostException e) {
            return false;
        }

        return result;
    }
}
