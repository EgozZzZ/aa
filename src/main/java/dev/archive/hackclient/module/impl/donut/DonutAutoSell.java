package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;

public class DonutAutoSell extends Module {
    private final NumberSetting delay = add(new NumberSetting("Delay", 500.0, 100.0, 2000.0, 50.0));
    private long last;
    public DonutAutoSell() { super("DonutAutoSell", "Runs /sell hand on hotbar", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (System.currentTimeMillis() - last < delay.get()) return;
        if (mc.player.getMainHandStack().isEmpty()) return;
        mc.player.networkHandler.sendChatCommand("sell hand");
        last = System.currentTimeMillis();
    }
}
