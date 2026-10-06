package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;

public class Reach extends Module {
    public final NumberSetting blockReach = add(new NumberSetting("BlockReach", 5.0, 3.0, 6.0, 0.1));
    public final NumberSetting entityReach = add(new NumberSetting("EntityReach", 3.0, 3.0, 6.0, 0.1));
    public Reach() { super("Reach", "Extends interaction range", Category.COMBAT); }
}
