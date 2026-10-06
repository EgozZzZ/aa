package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.player.PlayerEntity;

public class DonutEmergencyDisconnect extends Module {
    private final NumberSetting range = add(new NumberSetting("Range", 20.0, 4.0, 64.0, 1.0));
    public DonutEmergencyDisconnect() { super("DonutEmergencyDisconnect", "Disconnect on player proximity", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        boolean near = !mc.world.getEntitiesByClass(PlayerEntity.class,
            mc.player.getBoundingBox().expand(range.get()), e -> e != mc.player).isEmpty();
        if (near) mc.getNetworkHandler().getConnection().disconnect(net.minecraft.text.Text.literal("Emergency"));
    }
}
