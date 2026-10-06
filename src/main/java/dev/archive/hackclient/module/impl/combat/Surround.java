package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.*;
import dev.archive.hackclient.util.BlockUtil;
import net.minecraft.client.MinecraftClient;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.Vec3d;

public class Surround extends Module {
    private final NumberSetting delay = add(new NumberSetting("Delay", 50.0, 0.0, 500.0, 10.0));
    private final BooleanSetting center = add(new BooleanSetting("Center", true));
    private long last;
    public Surround() { super("Surround", "Places obsidian around feet", Category.COMBAT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        if (System.currentTimeMillis() - last < delay.get()) return;
        BlockPos p = mc.player.getBlockPos();
        Direction[] dirs = { Direction.NORTH, Direction.SOUTH, Direction.EAST, Direction.WEST };
        for (Direction d : dirs) {
            BlockPos target = p.offset(d);
            if (!BlockUtil.isReplaceable(target)) continue;
            BlockPos support = target.down();
            if (!mc.world.getBlockState(support).isSolidBlock(mc.world, support)) {
                if (!BlockUtil.place(support, Direction.UP, Vec3d.ofCenter(support).add(0, 0.5, 0))) continue;
            }
            BlockUtil.place(target, d.getOpposite(),
                Vec3d.ofCenter(target).add(0.5 * d.getOpposite().getOffsetX(), 0.5, 0.5 * d.getOpposite().getOffsetZ()));
        }
        last = System.currentTimeMillis();
    }
}
