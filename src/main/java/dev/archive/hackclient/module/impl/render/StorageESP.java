package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class StorageESP extends Module {
    public final BooleanSetting chests = add(new BooleanSetting("Chests", true));
    public final BooleanSetting shulkers = add(new BooleanSetting("Shulkers", true));
    public final BooleanSetting barrels = add(new BooleanSetting("Barrels", true));
    public final BooleanSetting enderChests = add(new BooleanSetting("EnderChests", false));
    public final BooleanSetting spawners = add(new BooleanSetting("Spawners", true));
    public final BooleanSetting throughWalls = add(new BooleanSetting("ThroughWalls", true));
    public final NumberSetting range = add(new NumberSetting("Range", 32.0, 8.0, 128.0, 8.0));
    public StorageESP() { super("StorageESP", "Outlines containers and spawners", Category.RENDER); }
}
