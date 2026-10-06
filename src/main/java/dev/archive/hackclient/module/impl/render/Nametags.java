package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class Nametags extends Module {
    public final BooleanSetting health = add(new BooleanSetting("Health", true));
    public final BooleanSetting ping = add(new BooleanSetting("Ping", true));
    public final NumberSetting scale = add(new NumberSetting("Scale", 1.0, 0.5, 3.0, 0.1));
    public Nametags() { super("Nametags", "Enhanced player nametags", Category.RENDER); }
}
