package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import net.minecraft.client.MinecraftClient;

public class DonutNoBlockInteract extends Module {
    public DonutNoBlockInteract() { super("DonutNoBlockInteract", "Blocks container GUI while holding pearl", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (mc.player.getMainHandStack().getItem() == net.minecraft.item.Items.ENDER_PEARL) {
            if (mc.currentScreen != null && mc.currentScreen.getTitle() != null) {
                String t = mc.currentScreen.getTitle().getString().toLowerCase();
                if (t.contains("chest") || t.contains("barrel") || t.contains("shulker"))
                    mc.setScreen(null);
            }
        }
    }
}
