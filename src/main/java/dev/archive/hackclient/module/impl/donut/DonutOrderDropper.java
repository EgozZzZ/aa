package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import net.minecraft.client.MinecraftClient;

public class DonutOrderDropper extends Module {
    public DonutOrderDropper() { super("DonutOrderDropper", "Runs /order for held item", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (mc.options.useKey.isPressed()) {
            var held = mc.player.getMainHandStack();
            if (!held.isEmpty()) {
                String name = held.getItem().toString().toLowerCase().replace("item.", "").replace("_", "");
                mc.player.networkHandler.sendChatCommand("order " + name);
            }
        }
    }
}
