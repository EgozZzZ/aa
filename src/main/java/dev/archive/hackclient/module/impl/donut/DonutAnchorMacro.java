package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.item.Items;
import net.minecraft.util.Hand;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.Vec3d;

public class DonutAnchorMacro extends Module {
    private final NumberSetting range = add(new NumberSetting("Range", 4.5, 1.0, 6.0, 0.1));
    public DonutAnchorMacro() { super("DonutAnchorMacro", "Charges and detonates respawn anchors", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        int glowSlot = -1;
        for (int i = 0; i < 9; i++)
            if (mc.player.getInventory().getStack(i).getItem() == Items.GLOWSTONE) glowSlot = i;
        if (glowSlot == -1) return;
        BlockPos center = mc.player.getBlockPos();
        int r = (int) Math.ceil(range.get());
        for (int dx = -r; dx <= r; dx++)
        for (int dy = -2; dy <= 2; dy++)
        for (int dz = -r; dz <= r; dz++) {
            BlockPos p = center.add(dx, dy, dz);
            if (mc.world.getBlockState(p).isOf(net.minecraft.block.Blocks.RESPAWN_ANCHOR)) {
                if (mc.player.squaredDistanceTo(Vec3d.ofCenter(p)) > range.get() * range.get()) continue;
                int prev = mc.player.getInventory().selectedSlot;
                mc.player.getInventory().selectedSlot = glowSlot;
                mc.interactionManager.interactBlock(mc.player, Hand.MAIN_HAND,
                    new BlockHitResult(Vec3d.ofCenter(p), Direction.UP, p, false));
                mc.player.getInventory().selectedSlot = prev;
                mc.interactionManager.interactBlock(mc.player, Hand.MAIN_HAND,
                    new BlockHitResult(Vec3d.ofCenter(p), Direction.UP, p, false));
                return;
            }
        }
    }
}
