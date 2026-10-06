package dev.archive.hackclient.module.impl.movement;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;

public class Speed extends Module {
    private final NumberSetting multiplier = add(new NumberSetting("Multiplier", 1.35, 1.0, 3.0, 0.05));
    public Speed() { super("Speed", "Movement speed modifier", Category.MOVEMENT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (mc.player.forwardSpeed > 0 && mc.player.isOnGround()) {
            double mx = mc.player.getVelocity().x * multiplier.get();
            double mz = mc.player.getVelocity().z * multiplier.get();
            mc.player.setVelocity(mx, mc.player.getVelocity().y, mz);
        }
    }
}
