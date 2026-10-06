package dev.archive.hackclient.module.impl.movement;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.ModeSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.network.packet.c2s.play.PlayerMoveC2SPacket;

public class NoFall extends Module {
    private final ModeSetting mode = add(new ModeSetting("Mode", "Packet", "Packet", "Ground"));
    public NoFall() { super("NoFall", "Prevents fall damage", Category.MOVEMENT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.getNetworkHandler() == null) return;
        if (mc.player.fallDistance > 2.5f) {
            if (mode.is("Packet"))
                mc.getNetworkHandler().sendPacket(new PlayerMoveC2SPacket.OnGroundOnly(true, mc.player.horizontalCollision));
            else if (mode.is("Ground"))
                mc.player.setOnGround(true);
        }
    }
}
