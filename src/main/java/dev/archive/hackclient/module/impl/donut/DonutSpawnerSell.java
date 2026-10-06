package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.item.Items;

public class DonutSpawnerSell extends Module {
    private final BooleanSetting bones = add(new BooleanSetting("Bones", true));
    public DonutSpawnerSell() { super("DonutSpawnerSell", "Drops spawner loot", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        for (int i = 9; i < 36; i++) {
            var s = mc.player.getInventory().getStack(i);
            if (bones.get() && s.getItem() == Items.BONE) mc.player.dropSelectedItem(false);
        }
    }
}
