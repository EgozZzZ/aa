package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.item.Items;
import net.minecraft.util.Hand;

public class AutoExp extends Module {
    private final NumberSetting delay = add(new NumberSetting("Delay", 50.0, 0.0, 500.0, 10.0));
    private long last;
    public AutoExp() { super("AutoExp", "Throws XP to repair armor", Category.COMBAT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (System.currentTimeMillis() - last < delay.get()) return;
        boolean mending = false;
        for (var s : mc.player.getArmorItems()) if (s.hasEnchantments()) { mending = true; break; }
        if (!mending) return;
        int slot = -1;
        for (int i = 0; i < 9; i++) if (mc.player.getInventory().getStack(i).getItem() == Items.EXPERIENCE_BOTTLE) { slot = i; break; }
        if (slot == -1) return;
        int prev = mc.player.getInventory().selectedSlot;
        mc.player.getInventory().selectedSlot = slot;
        mc.interactionManager.interactItem(mc.player, Hand.MAIN_HAND);
        mc.player.swingHand(Hand.MAIN_HAND);
        mc.player.getInventory().selectedSlot = prev;
        last = System.currentTimeMillis();
    }
}
