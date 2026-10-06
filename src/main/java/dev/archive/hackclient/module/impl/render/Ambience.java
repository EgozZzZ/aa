package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class Ambience extends Module {
    public final BooleanSetting skyOverride = add(new BooleanSetting("SkyOverride", false));
    public final NumberSetting hue = add(new NumberSetting("Hue", 0.6, 0.0, 1.0, 0.01));
    public final BooleanSetting fogReduce = add(new BooleanSetting("FogReduce", true));
    public final NumberSetting fogStart = add(new NumberSetting("FogStart", 100.0, 10.0, 1000.0, 10.0));
    public final BooleanSetting fullBright = add(new BooleanSetting("FullBright", true));
    public Ambience() { super("Ambience", "Sky and lighting overrides", Category.RENDER); }
}
