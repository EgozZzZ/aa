package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.ModeSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class Chams extends Module {
    public final BooleanSetting players = add(new BooleanSetting("Players", true));
    public final BooleanSetting self = add(new BooleanSetting("Self", false));
    public final BooleanSetting mobs = add(new BooleanSetting("Mobs", false));
    public final ModeSetting mode = add(new ModeSetting("Mode", "Flat", "Flat", "Texture", "Glow", "Wireframe"));
    public final ModeSetting colorMode = add(new ModeSetting("Color", "Static", "Static", "Rainbow", "Health", "Team"));
    public final NumberSetting range = add(new NumberSetting("Range", 64.0, 8.0, 256.0, 8.0));
    public final NumberSetting alpha = add(new NumberSetting("Alpha", 0.6, 0.1, 1.0, 0.05));
    public final BooleanSetting throughWalls = add(new BooleanSetting("ThroughWalls", true));
    public Chams() { super("Chams", "Depth-tinted entity rendering", Category.RENDER); }
}
