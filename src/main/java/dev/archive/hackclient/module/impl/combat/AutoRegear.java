package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import dev.archive.hackclient.util.InventoryUtil;
import net.minecraft.client.MinecraftClient;
import net.minecraft.item.Items;

public class AutoRegear extends Module {
    private final NumberSetting delay = add(new NumberSetting("Delay", 200.0, 0.0, 1000.0, 10.0));
    private long last;
    public AutoRegear() { super("AutoRegear", "Refills hotbar from inventory", Category.COMBAT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (System.currentTimeMillis() - last < delay.get()) return;
        if (refill(mc, Items.END_CRYSTAL, 0)) return;
        if (refill(mc, Items.OBSIDIAN, 1)) return;
        if (refill(mc, Items.TOTEM_OF_UNDYING, 2)) return;
        if (refill(mc, Items.GOLDEN_APPLE, 3)) return;
        if (refill(mc, Items.EXPERIENCE_BOTTLE, 4)) return;
    }
    private boolean refill(MinecraftClient mc, net.minecraft.item.Item item, int hotbarSlot) {
        if (InventoryUtil.findSlotHotbar(item) != -1) return false;
        int src = InventoryUtil.findSlot(item);
        if (src == -1) return false;
        InventoryUtil.moveToHotbar(src, hotbarSlot);
        last = System.currentTimeMillis();
        return true;
    }
}
