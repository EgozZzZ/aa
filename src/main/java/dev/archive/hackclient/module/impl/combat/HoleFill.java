package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.*;
import dev.archive.hackclient.util.BlockUtil;
import net.minecraft.client.MinecraftClient;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.Vec3d;

public class HoleFill extends Module {
    private final NumberSetting range = add(new NumberSetting("Range", 4.0, 1.0, 6.0, 0.5));
    private final NumberSetting delay = add(new NumberSetting("Delay", 100.0, 0.0, 1000.0, 10.0));
    private long last;
    public HoleFill() { super("HoleFill", "Fills nearby holes", Category.COMBAT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        if (System.currentTimeMillis() - last < delay.get()) return;
        BlockPos center = mc.player.getBlockPos();
        int r = (int) Math.ceil(range.get());
        for (int dx = -r; dx <= r; dx++)
        for (int dy = -2; dy <= 2; dy++)
        for (int dz = -r; dz <= r; dz++) {
            BlockPos p = center.add(dx, dy, dz);
            if (!isHole(mc, p)) continue;
            if (mc.player.squaredDistanceTo(Vec3d.ofCenter(p)) > range.get() * range.get()) continue;
            if (BlockUtil.place(p, Direction.UP, Vec3d.ofCenter(p).add(0, 0.5, 0))) {
                last = System.currentTimeMillis();
                return;
            }
        }
    }
    private boolean isHole(MinecraftClient mc, BlockPos p) {
        if (!mc.world.getBlockState(p).isAir()) return false;
        if (!mc.world.getBlockState(p.up()).isAir()) return false;
        if (!mc.world.getBlockState(p.up(2)).isAir()) return false;
        for (Direction d : new Direction[]{Direction.NORTH, Direction.SOUTH, Direction.EAST, Direction.WEST, Direction.DOWN}) {
            BlockPos n = p.offset(d);
            var s = mc.world.getBlockState(n);
            if (!s.isSolidBlock(mc.world, n)) return false;
        }
        return true;
    }
}
