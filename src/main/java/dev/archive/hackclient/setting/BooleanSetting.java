package dev.archive.hackclient.setting;

public class BooleanSetting extends Setting<Boolean> {
    public BooleanSetting(String name, boolean value) { super(name, value); }
    public boolean get() { return value; }
    public void toggle() { value = !value; }
    @Override public String display() { return value ? "on" : "off"; }
}
