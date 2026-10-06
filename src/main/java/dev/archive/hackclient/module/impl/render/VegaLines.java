package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class VegaLines extends Module {
    public final BooleanSetting players = add(new BooleanSetting("Players", true));
    public final BooleanSetting self = add(new BooleanSetting("Self", false));
    public final NumberSetting height = add(new NumberSetting("Height", 2.0, 0.5, 8.0, 0.1));
    public final NumberSetting width = add(new NumberSetting("Width", 0.15, 0.05, 0.5, 0.01));
    public final NumberSetting opacity = add(new NumberSetting("Opacity", 0.6, 0.1, 1.0, 0.05));
    public final NumberSetting range = add(new NumberSetting("Range", 64.0, 8.0, 256.0, 8.0));
    public VegaLines() { super("VegaLines", "Vertical rainbow beams under players", Category.RENDER); }
}
