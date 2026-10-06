package dev.archive.hackclient.sound;

public final class Tone {
    public static final float[] MODULE_ON  = Synth.sweep(660f, 990f, 0.08f, 0.35f, true);
    public static final float[] MODULE_OFF = Synth.sweep(660f, 330f, 0.08f, 0.35f, true);
    public static final float[] CLICK      = Synth.click(0.4f);
    public static final float[] HIT        = Synth.chord(new float[]{880f, 1320f}, 0.05f, 0.35f);
    public static final float[] KILL       = Synth.chord(new float[]{523.25f, 659.25f, 783.99f}, 0.18f, 0.4f);
    public static final float[] GUI_OPEN   = Synth.sweep(440f, 1760f, 0.12f, 0.35f, true);
    public static final float[] PEARL      = Synth.sweep(1200f, 400f, 0.15f, 0.3f, true);
}
