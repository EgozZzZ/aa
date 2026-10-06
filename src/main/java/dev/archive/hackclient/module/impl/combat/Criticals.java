package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.ModeSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.Entity;
import net.minecraft.entity.LivingEntity;
import net.minecraft.network.packet.c2s.play.PlayerMoveC2SPacket;

public class Criticals extends Module {
    private final ModeSetting mode = add(new ModeSetting("Mode", "Packet", "Packet", "Jump", "MiniJump"));
    public Criticals() { super("Criticals", "Always land critical hits", Category.COMBAT); }
    public void doCrit(Entity target) {
        if (!isEnabled() || !(target instanceof LivingEntity)) return;
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.getNetworkHandler() == null) return;
        if (mc.player.isOnGround() && !mc.player.isInLava() && !mc.player.isSubmergedInWater()) {
            switch (mode.get()) {
                case "Packet" -> {
                    double x = mc.player.getX(), y = mc.player.getY(), z = mc.player.getZ();
                    mc.getNetworkHandler().sendPacket(new PlayerMoveC2SPacket.PositionAndOnGround(x, y + 0.0625, z, false, mc.player.horizontalCollision));
                    mc.getNetworkHandler().sendPacket(new PlayerMoveC2SPacket.PositionAndOnGround(x, y, z, false, mc.player.horizontalCollision));
                }
                case "Jump" -> mc.player.jump();
                case "MiniJump" -> mc.player.setVelocity(mc.player.getVelocity().x, 0.1, mc.player.getVelocity().z);
            }
        }
    }
}
