package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import dev.archive.hackclient.util.BlockUtil;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.Vec3d;
import java.util.Comparator;

public class AutoTrap extends Module {
    private final NumberSetting delay = add(new NumberSetting("Delay", 100.0, 0.0, 1000.0, 10.0));
    private long last;
    public AutoTrap() { super("AutoTrap", "Traps nearby players", Category.COMBAT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        if (System.currentTimeMillis() - last < delay.get()) return;
        PlayerEntity target = mc.world.getEntitiesByClass(PlayerEntity.class,
                mc.player.getBoundingBox().expand(5.0), e -> e != mc.player && e.isAlive())
            .stream().min(Comparator.comparingDouble(e -> e.distanceTo(mc.player))).orElse(null);
        if (target == null) return;
        BlockPos p = target.getBlockPos();
        for (Direction d : new Direction[]{Direction.NORTH, Direction.SOUTH, Direction.EAST, Direction.WEST}) {
            BlockPos b = p.offset(d);
            if (BlockUtil.isReplaceable(b))
                BlockUtil.place(b, d.getOpposite(), Vec3d.ofCenter(b).add(0.5 * d.getOpposite().getOffsetX(), 0.5, 0.5 * d.getOpposite().getOffsetZ()));
        }
        for (Direction d : new Direction[]{Direction.NORTH, Direction.SOUTH, Direction.EAST, Direction.WEST}) {
            BlockPos b = p.up(2).offset(d);
            if (BlockUtil.isReplaceable(b))
                BlockUtil.place(b, d.getOpposite(), Vec3d.ofCenter(b));
        }
        if (BlockUtil.isReplaceable(p.up(3))) BlockUtil.place(p.up(3), Direction.UP, Vec3d.ofCenter(p.up(3)).add(0, 0.5, 0));
        last = System.currentTimeMillis();
    }
}
