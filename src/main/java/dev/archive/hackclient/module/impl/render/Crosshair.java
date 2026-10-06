package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.ModeSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class Crosshair extends Module {
    public final ModeSetting style = add(new ModeSetting("Style", "Plus", "Plus", "Dot", "Circle", "Cross"));
    public final NumberSetting size = add(new NumberSetting("Size", 8.0, 2.0, 30.0, 1.0));
    public final NumberSetting thickness = add(new NumberSetting("Thickness", 1.0, 1.0, 4.0, 1.0));
    public final BooleanSetting rainbow = add(new BooleanSetting("Rainbow", true));
    public Crosshair() { super("Crosshair", "Custom crosshair", Category.RENDER); }
}
