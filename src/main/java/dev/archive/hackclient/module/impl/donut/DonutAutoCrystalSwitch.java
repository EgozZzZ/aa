package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import net.minecraft.client.MinecraftClient;
import net.minecraft.item.Items;

public class DonutAutoCrystalSwitch extends Module {
    public DonutAutoCrystalSwitch() { super("DonutAutoCrystalSwitch", "Switches to crystal after obsidian", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        int obsSlot = -1, crystalSlot = -1;
        for (int i = 0; i < 9; i++) {
            var s = mc.player.getInventory().getStack(i);
            if (s.getItem() == Items.OBSIDIAN) obsSlot = i;
            if (s.getItem() == Items.END_CRYSTAL) crystalSlot = i;
        }
        if (obsSlot != -1 && crystalSlot != -1 && mc.player.getInventory().selectedSlot == obsSlot)
            mc.player.getInventory().selectedSlot = crystalSlot;
    }
}
