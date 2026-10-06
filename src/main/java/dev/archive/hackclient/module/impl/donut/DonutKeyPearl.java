package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import net.minecraft.client.MinecraftClient;
import net.minecraft.item.Items;
import net.minecraft.util.Hand;

public class DonutKeyPearl extends Module {
    public DonutKeyPearl() { super("DonutKeyPearl", "Bind-triggered pearl throw", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (!mc.options.useKey.isPressed()) return;
        int pearlSlot = -1;
        for (int i = 0; i < 9; i++)
            if (mc.player.getInventory().getStack(i).getItem() == Items.ENDER_PEARL) { pearlSlot = i; break; }
        if (pearlSlot == -1) return;
        int prev = mc.player.getInventory().selectedSlot;
        mc.player.getInventory().selectedSlot = pearlSlot;
        mc.interactionManager.interactItem(mc.player, Hand.MAIN_HAND);
        mc.player.swingHand(Hand.MAIN_HAND);
        mc.player.getInventory().selectedSlot = prev;
    }
}
