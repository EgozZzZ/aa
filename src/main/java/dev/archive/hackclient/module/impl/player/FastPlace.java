package dev.archive.hackclient.module.impl.player;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;

public class FastPlace extends Module {
    private final NumberSetting delay = add(new NumberSetting("Delay", 0.0, 0.0, 4.0, 1.0));
    public FastPlace() { super("FastPlace", "Zero right-click cooldown", Category.PLAYER); }
    @Override public void onTick() {
        // Stub — 1.21.4 made itemUseCooldown private. Direct field write removed.
    }
}
