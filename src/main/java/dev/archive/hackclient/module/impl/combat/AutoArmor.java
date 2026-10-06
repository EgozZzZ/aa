package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.item.ArmorItem;
import net.minecraft.item.ItemStack;
import net.minecraft.screen.slot.SlotActionType;

public class AutoArmor extends Module {
    private final NumberSetting delay = add(new NumberSetting("Delay", 100.0, 0.0, 1000.0, 10.0));
    private long last;

    // armor inventory indices in the player inventory: 36=feet, 37=legs, 38=chest, 39=head
    private static final int[] ARMOR_SLOTS = { 39, 38, 37, 36 };

    public AutoArmor() { super("AutoArmor", "Equips armor into empty slots", Category.COMBAT); }

    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (System.currentTimeMillis() - last < delay.get()) return;

        for (int armorSlot : ARMOR_SLOTS) {
            ItemStack cur = mc.player.getInventory().getStack(armorSlot);
            if (!cur.isEmpty()) continue;

            for (int i = 0; i < 36; i++) {
                ItemStack candidate = mc.player.getInventory().getStack(i);
                if (!(candidate.getItem() instanceof ArmorItem)) continue;
                if (!isCorrectSlot(candidate, armorSlot)) continue;

                int src = i < 9 ? i + 36 : i;
                mc.interactionManager.clickSlot(mc.player.playerScreenHandler.syncId, src, 0, SlotActionType.PICKUP, mc.player);
                mc.interactionManager.clickSlot(mc.player.playerScreenHandler.syncId, armorSlot, 0, SlotActionType.PICKUP, mc.player);
                mc.interactionManager.clickSlot(mc.player.playerScreenHandler.syncId, src, 0, SlotActionType.PICKUP, mc.player);
                last = System.currentTimeMillis();
                return;
            }
        }
    }

    private boolean isCorrectSlot(ItemStack s, int armorInvIndex) {
        String name = s.getItem().toString().toLowerCase();
        return switch (armorInvIndex) {
            case 39 -> name.contains("helmet") || name.contains("cap") || name.contains("turtle");
            case 38 -> name.contains("chestplate") || name.contains("tunic") || name.contains("elytra");
            case 37 -> name.contains("leggings") || name.contains("pants");
            case 36 -> name.contains("boots");
            default -> false;
        };
    }
}
