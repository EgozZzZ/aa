package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;

public class Tracers extends Module {
    public final BooleanSetting players = add(new BooleanSetting("Players", true));
    public final BooleanSetting mobs = add(new BooleanSetting("Mobs", false));
    public final BooleanSetting throughWalls = add(new BooleanSetting("ThroughWalls", true));
    public Tracers() { super("Tracers", "Lines to entities", Category.RENDER); }
}
