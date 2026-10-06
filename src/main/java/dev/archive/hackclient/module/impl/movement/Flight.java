package dev.archive.hackclient.module.impl.movement;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;

public class Flight extends Module {
    private final NumberSetting speed = add(new NumberSetting("Speed", 1.0, 0.1, 5.0, 0.1));
    public Flight() { super("Flight", "Creative-style flight", Category.MOVEMENT); }
    @Override public void onEnable() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player != null) mc.player.getAbilities().allowFlying = true;
    }
    @Override public void onDisable() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player != null && !mc.player.isCreative()) {
            mc.player.getAbilities().allowFlying = false;
            mc.player.getAbilities().flying = false;
        }
    }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        mc.player.getAbilities().setFlySpeed(speed.getFloat() * 0.05f);
        mc.player.getAbilities().allowFlying = true;
        if (!mc.player.getAbilities().flying && mc.options.jumpKey.isPressed()) mc.player.getAbilities().flying = true;
    }
}
