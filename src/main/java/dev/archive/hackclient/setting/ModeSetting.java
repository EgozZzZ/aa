package dev.archive.hackclient.setting;

import java.util.List;
public class ModeSetting extends Setting<String> {
    public final List<String> modes;
    public ModeSetting(String name, String value, String... modes) {
        super(name, value); this.modes = List.of(modes);
    }
    public String get() { return value; }
    public void cycle() {
        int i = modes.indexOf(value);
        value = modes.get((i + 1) % modes.size());
    }
    public boolean is(String m) { return value.equalsIgnoreCase(m); }
    @Override public String display() { return value; }
}
