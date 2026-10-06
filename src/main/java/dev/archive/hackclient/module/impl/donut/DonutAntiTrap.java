package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.Entity;
import net.minecraft.entity.EntityType;
import net.minecraft.network.packet.c2s.play.PlayerInteractEntityC2SPacket;
import net.minecraft.util.Hand;

public class DonutAntiTrap extends Module {
    public DonutAntiTrap() { super("DonutAntiTrap", "Escapes armor stand/minecart traps", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        for (Entity e : mc.world.getEntitiesByClass(Entity.class,
            mc.player.getBoundingBox().expand(2.0),
            en -> en.getType() == EntityType.ARMOR_STAND || en.getType() == EntityType.MINECART
                || en.getType() == EntityType.CHEST_MINECART || en.getType() == EntityType.HOPPER_MINECART)) {
            mc.getNetworkHandler().sendPacket(
                PlayerInteractEntityC2SPacket.attack(e, mc.player.isSneaking()));
            mc.player.swingHand(Hand.MAIN_HAND);
        }
    }
}
