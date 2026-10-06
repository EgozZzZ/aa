package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class BlockHighlight extends Module {
    public final NumberSetting opacity = add(new NumberSetting("Opacity", 0.4, 0.1, 1.0, 0.05));
    public final BooleanSetting outline = add(new BooleanSetting("Outline", true));
    public final BooleanSetting fill = add(new BooleanSetting("Fill", true));
    public BlockHighlight() { super("BlockHighlight", "Highlights the block you look at", Category.RENDER); }
}
