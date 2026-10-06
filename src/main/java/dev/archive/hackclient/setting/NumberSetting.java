package dev.archive.hackclient.setting;

public class NumberSetting extends Setting<Double> {
    public final double min, max, step;
    public NumberSetting(String name, double value, double min, double max, double step) {
        super(name, value); this.min = min; this.max = max; this.step = step;
    }
    public double get() { return value; }
    public float getFloat() { return value.floatValue(); }
    public int getInt() { return (int) Math.round(value); }
    public void set(double v) { this.value = Math.max(min, Math.min(max, v)); }
    @Override public String display() { return String.format("%.2f", value); }
}
