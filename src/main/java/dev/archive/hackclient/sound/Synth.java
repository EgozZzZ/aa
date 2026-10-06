package dev.archive.hackclient.sound;

public final class Synth {
    public static final float SR = 44100f;
    public static float[] sine(float freq, float durSec, float amp) {
        int n = (int)(SR * durSec);
        float[] out = new float[n];
        for (int i = 0; i < n; i++) {
            float t = i / SR;
            out[i] = (float) Math.sin(2 * Math.PI * freq * t) * amp * envelope(i, n, 0.005f, 0.05f);
        }
        return out;
    }
    public static float[] sweep(float f0, float f1, float durSec, float amp, boolean exp) {
        int n = (int)(SR * durSec);
        float[] out = new float[n];
        double phase = 0;
        for (int i = 0; i < n; i++) {
            float t = i / (float) n;
            float f = exp ? (float)(f0 * Math.pow(f1 / f0, t)) : f0 + (f1 - f0) * t;
            phase += 2 * Math.PI * f / SR;
            out[i] = (float) Math.sin(phase) * amp * envelope(i, n, 0.003f, 0.08f);
        }
        return out;
    }
    public static float[] chord(float[] freqs, float durSec, float amp) {
        int n = (int)(SR * durSec);
        float[] out = new float[n];
        for (int i = 0; i < n; i++) {
            float t = i / SR;
            float s = 0;
            for (float f : freqs) s += (float) Math.sin(2 * Math.PI * f * t);
            out[i] = s / freqs.length * amp * envelope(i, n, 0.005f, 0.1f);
        }
        return out;
    }
    public static float[] click(float amp) {
        int n = (int)(SR * 0.02f);
        float[] out = new float[n];
        for (int i = 0; i < n; i++) {
            float t = i / SR;
            float env = (float) Math.exp(-t * 80);
            out[i] = (float)(Math.random() * 2 - 1) * amp * env * 0.5f
                   + (float) Math.sin(2 * Math.PI * 1800 * t) * amp * env * 0.5f;
        }
        return out;
    }
    private static float envelope(int i, int n, float attack, float release) {
        float t = i / SR;
        float total = n / SR;
        float a = Math.min(1f, t / attack);
        float r = Math.min(1f, (total - t) / release);
        return a * r;
    }
}
