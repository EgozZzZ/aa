package dev.archive.hackclient.module.impl.movement;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.ModeSetting;

public class NoSlow extends Module {
    public final ModeSetting mode = add(new ModeSetting("Mode", "Vanilla", "Vanilla", "NCP", "Strict"));
    public NoSlow() { super("NoSlow", "No slowdown while using items", Category.MOVEMENT); }
}
