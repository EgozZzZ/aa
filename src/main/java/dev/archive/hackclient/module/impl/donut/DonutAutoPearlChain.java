package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.item.Items;
import net.minecraft.util.Hand;

public class DonutAutoPearlChain extends Module {
    private final NumberSetting delay = add(new NumberSetting("Delay", 200.0, 50.0, 1000.0, 10.0));
    private long last;
    public DonutAutoPearlChain() { super("DonutAutoPearlChain", "Chains pearls after teleport", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (System.currentTimeMillis() - last < delay.get()) return;
        if (mc.player.getMainHandStack().getItem() != Items.ENDER_PEARL) return;
        if (!mc.player.isOnGround()) {
            mc.interactionManager.interactItem(mc.player, Hand.MAIN_HAND);
            mc.player.swingHand(Hand.MAIN_HAND);
            last = System.currentTimeMillis();
        }
    }
}
