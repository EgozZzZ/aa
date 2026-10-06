package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.player.PlayerEntity;

public class AutoLogout extends Module {
    private final NumberSetting health = add(new NumberSetting("Health", 6.0, 1.0, 20.0, 0.5));
    private final BooleanSetting playerNear = add(new BooleanSetting("PlayerNear", true));
    private final NumberSetting range = add(new NumberSetting("Range", 12.0, 4.0, 32.0, 1.0));
    public AutoLogout() { super("AutoLogout", "Disconnect on low HP / nearby player", Category.COMBAT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        if (mc.player.getHealth() <= health.get()) {
            mc.getNetworkHandler().getConnection().disconnect(net.minecraft.text.Text.literal("AutoLogout"));
            return;
        }
        if (playerNear.get()) {
            boolean near = !mc.world.getEntitiesByClass(PlayerEntity.class,
                mc.player.getBoundingBox().expand(range.get()), e -> e != mc.player).isEmpty();
            if (near) mc.getNetworkHandler().getConnection().disconnect(net.minecraft.text.Text.literal("AutoLogout"));
        }
    }
}
