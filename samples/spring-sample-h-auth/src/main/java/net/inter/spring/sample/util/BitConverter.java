package net.inter.spring.sample.util;

import java.nio.ByteOrder;

public class BitConverter {
    public static byte[] getBytes(boolean x){
        return new byte[] {(byte) (x ? 1 : 0)};
    }

    public static byte[] getBytes(char c){
        return new byte[] {(byte) (c & 0xff), (byte)(c >> 8 & 0xff)};
    }

    public static byte[] getBytes(double x){
        return getBytes(Double.doubleToRawLongBits(x));
    }

    public static byte[] getBytes(short x){
        return new byte[]{(byte) (x >>> 8), (byte) x};
    }

    public static byte[] getBytes(int x){
        return new byte[]{(byte) (x >>> 24), (byte) (x >>> 16), (byte) (x >>> 8), (byte)x};
    }

    public static byte[] getBytes(long x){
        return new byte[]{(byte) (x >>> 56), (byte) (x >>> 48), (byte) (x >>> 40), (byte) (x >>> 32),
                (byte) (x >>> 24), (byte) (x >>> 16), (byte) (x >>> 8), (byte)x};
    }
    public static byte[] getBytes(float x){
        return getBytes(Float.floatToRawIntBits(x));
    }

    public static boolean IsLittleEndian(){
        return ByteOrder.nativeOrder().equals(ByteOrder.LITTLE_ENDIAN);
    }

}
