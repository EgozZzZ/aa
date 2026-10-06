package dev.archive.hackclient.module.impl.movement;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import net.minecraft.client.MinecraftClient;

public class Sprint extends Module {
    public Sprint() { super("Sprint", "Permanent sprint", Category.MOVEMENT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (mc.player.forwardSpeed > 0 && !mc.player.isSneaking()) mc.player.setSprinting(true);
    }
}
