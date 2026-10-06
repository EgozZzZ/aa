package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class HoleESP extends Module {
    public final NumberSetting range = add(new NumberSetting("Range", 16.0, 4.0, 32.0, 1.0));
    public final NumberSetting opacity = add(new NumberSetting("Opacity", 0.5, 0.1, 1.0, 0.05));
    public final BooleanSetting bedrock = add(new BooleanSetting("Bedrock", true));
    public final BooleanSetting obsidian = add(new BooleanSetting("Obsidian", true));
    public final BooleanSetting mixed = add(new BooleanSetting("Mixed", false));
    public HoleESP() { super("HoleESP", "Highlights safe holes", Category.RENDER); }
}
