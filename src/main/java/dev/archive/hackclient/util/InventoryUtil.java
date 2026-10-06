package dev.archive.hackclient.util;

import net.minecraft.client.MinecraftClient;
import net.minecraft.item.Item;
import net.minecraft.screen.slot.SlotActionType;

public final class InventoryUtil {
    public static int findSlot(Item item) {
        MinecraftClient mc = MinecraftClient.getInstance();
        for (int i = 0; i < 36; i++) if (mc.player.getInventory().getStack(i).getItem() == item) return i;
        return -1;
    }
    public static int findSlotHotbar(Item item) {
        MinecraftClient mc = MinecraftClient.getInstance();
        for (int i = 0; i < 9; i++) if (mc.player.getInventory().getStack(i).getItem() == item) return i;
        return -1;
    }
    public static void moveToHotbar(int invSlot, int hotbarSlot) {
        MinecraftClient mc = MinecraftClient.getInstance();
        int src = invSlot < 9 ? invSlot + 36 : invSlot;
        mc.interactionManager.clickSlot(mc.player.playerScreenHandler.syncId, src, hotbarSlot, SlotActionType.SWAP, mc.player);
    }
    public static void swapToOffhand(int invSlot) {
        MinecraftClient mc = MinecraftClient.getInstance();
        int src = invSlot < 9 ? invSlot + 36 : invSlot;
        mc.interactionManager.clickSlot(mc.player.playerScreenHandler.syncId, src, 40, SlotActionType.SWAP, mc.player);
    }
}
