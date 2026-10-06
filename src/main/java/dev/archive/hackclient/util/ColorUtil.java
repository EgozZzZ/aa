package dev.archive.hackclient.util;

import java.awt.Color;
public final class ColorUtil {
    public static int argb(int a, int r, int g, int b) { return (a << 24) | (r << 16) | (g << 8) | b; }
    public static int hsb(float hue, float sat, float bri, float alpha) {
        int rgb = Color.HSBtoRGB(hue, sat, bri);
        return ((int)(alpha * 255) << 24) | (rgb & 0xFFFFFF);
    }
    public static int rainbow(float speed, float alpha) {
        float hue = (System.currentTimeMillis() % (long)(1000 / speed)) / (float)(1000 / speed);
        return hsb(hue, 0.8f, 1.0f, alpha);
    }
}
