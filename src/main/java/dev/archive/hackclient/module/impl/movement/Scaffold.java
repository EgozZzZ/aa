package dev.archive.hackclient.module.impl.movement;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.util.BlockUtil;
import net.minecraft.client.MinecraftClient;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.Vec3d;

public class Scaffold extends Module {
    private final BooleanSetting tower = add(new BooleanSetting("Tower", true));
    private final BooleanSetting rotate = add(new BooleanSetting("Rotate", true));
    public Scaffold() { super("Scaffold", "Auto bridge", Category.MOVEMENT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        BlockPos below = mc.player.getBlockPos().down();
        if (BlockUtil.isReplaceable(below))
            BlockUtil.place(below, Direction.UP, Vec3d.ofCenter(below).add(0, 0.5, 0));
        if (tower.get() && mc.options.jumpKey.isPressed())
            mc.player.setVelocity(mc.player.getVelocity().x, 0.42, mc.player.getVelocity().z);
    }
}
