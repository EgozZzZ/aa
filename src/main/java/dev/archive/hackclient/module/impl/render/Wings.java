package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.ModeSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class Wings extends Module {
    public final ModeSetting style = add(new ModeSetting("Style", "Angel", "Angel", "Demon", "Crystal", "Feather"));
    public final ModeSetting colorMode = add(new ModeSetting("Color", "Rainbow", "Static", "Rainbow", "Gradient"));
    public final NumberSetting scale = add(new NumberSetting("Scale", 1.0, 0.3, 3.0, 0.1));
    public final NumberSetting flapSpeed = add(new NumberSetting("FlapSpeed", 1.5, 0.1, 5.0, 0.1));
    public final NumberSetting opacity = add(new NumberSetting("Opacity", 0.85, 0.1, 1.0, 0.05));
    public Wings() { super("Wings", "Cosmetic wings on player", Category.RENDER); }
}
