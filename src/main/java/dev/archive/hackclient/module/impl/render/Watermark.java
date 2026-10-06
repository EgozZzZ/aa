package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.ModeSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class Watermark extends Module {
    public final ModeSetting position = add(new ModeSetting("Position", "TopLeft", "TopLeft", "TopRight", "BottomLeft", "BottomRight"));
    public final BooleanSetting rainbow = add(new BooleanSetting("Rainbow", true));
    public final BooleanSetting fps = add(new BooleanSetting("Fps", true));
    public final BooleanSetting ping = add(new BooleanSetting("Ping", true));
    public final BooleanSetting tps = add(new BooleanSetting("Tps", false));
    public final NumberSetting scale = add(new NumberSetting("Scale", 1.0, 0.5, 3.0, 0.1));
    public Watermark() { super("Watermark", "Client watermark HUD", Category.RENDER); }
}
