package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class Trajectories extends Module {
    public final BooleanSetting bows = add(new BooleanSetting("Bows", true));
    public final BooleanSetting pearls = add(new BooleanSetting("Pearls", true));
    public final BooleanSetting potions = add(new BooleanSetting("Potions", true));
    public final NumberSetting maxSteps = add(new NumberSetting("MaxSteps", 240.0, 40.0, 800.0, 20.0));
    public Trajectories() { super("Trajectories", "Projectile path prediction", Category.RENDER); }
}
