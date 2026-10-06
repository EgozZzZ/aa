package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.block.Blocks;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.util.math.BlockPos;

public class DonutSpawnerProtect extends Module {
    private final NumberSetting range = add(new NumberSetting("Range", 16.0, 4.0, 32.0, 1.0));
    private final BooleanSetting breakAndStore = add(new BooleanSetting("BreakStore", true));
    public DonutSpawnerProtect() { super("DonutSpawnerProtect", "Breaks spawner on player detection", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        boolean near = !mc.world.getEntitiesByClass(PlayerEntity.class,
            mc.player.getBoundingBox().expand(range.get()), e -> e != mc.player).isEmpty();
        if (!near || !breakAndStore.get()) return;
        BlockPos center = mc.player.getBlockPos();
        int r = (int) range.get();
        for (int dx = -r; dx <= r; dx++)
        for (int dy = -4; dy <= 4; dy++)
        for (int dz = -r; dz <= r; dz++) {
            BlockPos p = center.add(dx, dy, dz);
            if (mc.world.getBlockState(p).isOf(Blocks.SPAWNER)) {
                mc.interactionManager.updateBlockBreakingProgress(p, net.minecraft.util.math.Direction.UP);
                mc.player.swingHand(net.minecraft.util.Hand.MAIN_HAND);
                return;
            }
        }
    }
}
