package dev.archive.hackclient.sound;

import javax.sound.sampled.*;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public final class SoundManager {
    private static final ExecutorService POOL = Executors.newFixedThreadPool(2, r -> {
        Thread t = new Thread(r, "hackclient-sound");
        t.setDaemon(true);
        return t;
    });
    private static float volume = 0.6f;
    public static void setVolume(float v) { volume = Math.max(0f, Math.min(1f, v)); }
    public static float getVolume() { return volume; }
    public static void play(float[] samples, float sampleRate) {
        if (samples == null || samples.length == 0) return;
        POOL.submit(() -> {
            try {
                byte[] pcm = new byte[samples.length * 2];
                for (int i = 0; i < samples.length; i++) {
                    short s = (short)(Math.max(-1f, Math.min(1f, samples[i] * volume)) * Short.MAX_VALUE);
                    pcm[i * 2] = (byte)(s & 0xFF);
                    pcm[i * 2 + 1] = (byte)((s >> 8) & 0xFF);
                }
                AudioFormat fmt = new AudioFormat(sampleRate, 16, 1, true, false);
                DataLine.Info info = new DataLine.Info(SourceDataLine.class, fmt);
                SourceDataLine line = (SourceDataLine) AudioSystem.getLine(info);
                line.open(fmt, pcm.length);
                line.start();
                line.write(pcm, 0, pcm.length);
                line.drain();
                line.close();
            } catch (Exception ignored) {}
        });
    }
}
