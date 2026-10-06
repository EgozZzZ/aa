package dev.archive.hackclient.module.impl.movement;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.ModeSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.network.packet.c2s.play.PlayerMoveC2SPacket;

public class Phase extends Module {
    private final ModeSetting mode = add(new ModeSetting("Mode", "Packet", "Packet", "Sand", "Minecart"));
    public Phase() { super("Phase", "Clip through blocks", Category.MOVEMENT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.getNetworkHandler() == null) return;
        if (!mode.is("Packet")) return;
        if (!mc.player.horizontalCollision) return;
        double x = mc.player.getX(), y = mc.player.getY(), z = mc.player.getZ();
        mc.getNetworkHandler().sendPacket(new PlayerMoveC2SPacket.PositionAndOnGround(x, y - 0.0001, z, true, mc.player.horizontalCollision));
        mc.player.setPosition(x, y - 0.0001, z);
    }
}
