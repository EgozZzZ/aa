package dev.archive.hackclient.module.impl.movement;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;

public class Step extends Module {
    public final NumberSetting height = add(new NumberSetting("Height", 1.5, 0.5, 2.5, 0.1));
    public Step() { super("Step", "Step up blocks", Category.MOVEMENT); }
}
