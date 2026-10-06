package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.item.Items;
import net.minecraft.screen.slot.SlotActionType;

public class AutoTotem extends Module {
    private final NumberSetting delay = add(new NumberSetting("Delay", 2.0, 0.0, 20.0, 1.0));
    private long last;
    public AutoTotem() { super("AutoTotem", "Refills offhand with totems", Category.COMBAT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (mc.player.getOffHandStack().getItem() == Items.TOTEM_OF_UNDYING) return;
        if (System.currentTimeMillis() - last < delay.get() * 50.0) return;
        for (int i = 0; i < 36; i++) {
            if (mc.player.getInventory().getStack(i).getItem() == Items.TOTEM_OF_UNDYING) {
                int slot = i < 9 ? i + 36 : i;
                mc.interactionManager.clickSlot(mc.player.playerScreenHandler.syncId, slot, 0, SlotActionType.PICKUP, mc.player);
                mc.interactionManager.clickSlot(mc.player.playerScreenHandler.syncId, 45, 0, SlotActionType.PICKUP, mc.player);
                mc.interactionManager.clickSlot(mc.player.playerScreenHandler.syncId, slot, 0, SlotActionType.PICKUP, mc.player);
                last = System.currentTimeMillis();
                return;
            }
        }
    }
}
