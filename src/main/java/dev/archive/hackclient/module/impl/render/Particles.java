package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.ModeSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class Particles extends Module {
    public final ModeSetting mode = add(new ModeSetting("Mode", "Aura", "Aura", "Hit", "Trail", "Death"));
    public final NumberSetting count = add(new NumberSetting("Count", 8.0, 1.0, 50.0, 1.0));
    public final NumberSetting lifetime = add(new NumberSetting("Lifetime", 20.0, 5.0, 100.0, 1.0));
    public Particles() { super("Particles", "Cosmetic particle effects", Category.RENDER); }
}
