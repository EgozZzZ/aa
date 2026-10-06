package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class ChinaHat extends Module {
    public final BooleanSetting self = add(new BooleanSetting("Self", true));
    public final NumberSetting radius = add(new NumberSetting("Radius", 0.6, 0.3, 1.5, 0.05));
    public final NumberSetting height = add(new NumberSetting("Height", 0.5, 0.1, 2.0, 0.1));
    public final NumberSetting segments = add(new NumberSetting("Segments", 32.0, 8.0, 64.0, 1.0));
    public ChinaHat() { super("ChinaHat", "Cone hat on head", Category.RENDER); }
}
