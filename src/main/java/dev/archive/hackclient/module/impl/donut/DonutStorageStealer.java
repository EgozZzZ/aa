package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.util.math.BlockPos;
import net.minecraft.block.Blocks;

public class DonutStorageStealer extends Module {
    private final NumberSetting range = add(new NumberSetting("Range", 4.5, 1.0, 6.0, 0.1));
    public DonutStorageStealer() { super("DonutStorageStealer", "Auto-loots chests/shulkers", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        if (mc.currentScreen != null) return;
        BlockPos center = mc.player.getBlockPos();
        int r = (int) range.get();
        for (int dx = -r; dx <= r; dx++)
        for (int dy = -2; dy <= 2; dy++)
        for (int dz = -r; dz <= r; dz++) {
            BlockPos p = center.add(dx, dy, dz);
            var block = mc.world.getBlockState(p).getBlock();
            if (block == Blocks.CHEST || block == Blocks.BARREL || block == Blocks.SHULKER_BOX) {
                if (mc.player.squaredDistanceTo(net.minecraft.util.math.Vec3d.ofCenter(p)) > range.get() * range.get()) continue;
                var hit = new net.minecraft.util.hit.BlockHitResult(
                    net.minecraft.util.math.Vec3d.ofCenter(p), net.minecraft.util.math.Direction.UP, p, false);
                mc.interactionManager.interactBlock(mc.player, net.minecraft.util.Hand.MAIN_HAND, hit);
                return;
            }
        }
    }
}
