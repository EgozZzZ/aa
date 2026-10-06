package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;

public class DonutAHSell extends Module {
    private final NumberSetting price = add(new NumberSetting("Price", 100.0, 1.0, 100000.0, 100.0));
    private final NumberSetting delay = add(new NumberSetting("Delay", 1000.0, 200.0, 5000.0, 100.0));
    private long last;
    public DonutAHSell() { super("DonutAHSell", "Lists held item on AH", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (System.currentTimeMillis() - last < delay.get()) return;
        if (mc.player.getMainHandStack().isEmpty()) return;
        mc.player.networkHandler.sendChatCommand("ah sell " + (int) price.get());
        last = System.currentTimeMillis();
    }
}
