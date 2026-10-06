package dev.archive.hackclient.module;

import dev.archive.hackclient.setting.Setting;
import java.util.ArrayList;
import java.util.List;

public abstract class Module {
    public final String name;
    public final String description;
    public final Category category;
    public final List<Setting<?>> settings = new ArrayList<>();
    public int keybind = -1;
    private boolean enabled;

    public Module(String name, String description, Category category) {
        this.name = name; this.description = description; this.category = category;
    }
    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean e) {
        if (this.enabled == e) return;
        this.enabled = e;
        try {
            var es = HackClientBridge.get(dev.archive.hackclient.module.impl.sound.EnableSound.class);
            if (es != null && es.isEnabled()) {
                dev.archive.hackclient.sound.SoundManager.play(
                    e ? dev.archive.hackclient.sound.Tone.MODULE_ON
                      : dev.archive.hackclient.sound.Tone.MODULE_OFF,
                    dev.archive.hackclient.sound.Synth.SR);
            }
        } catch (Throwable ignored) {}
        if (e) onEnable(); else onDisable();
    }
    public void toggle() { setEnabled(!enabled); }
    public void onEnable() {}
    public void onDisable() {}
    public void onTick() {}
    protected <T extends Setting<?>> T add(T s) { settings.add(s); return s; }
}
