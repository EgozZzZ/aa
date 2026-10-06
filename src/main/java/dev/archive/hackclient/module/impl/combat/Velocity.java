package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;

public class Velocity extends Module {
    public final NumberSetting horizontal = add(new NumberSetting("Horizontal", 0.0, 0.0, 100.0, 1.0));
    public final NumberSetting vertical = add(new NumberSetting("Vertical", 0.0, 0.0, 100.0, 1.0));
    public Velocity() { super("Velocity", "Reduce knockback", Category.COMBAT); }
}
