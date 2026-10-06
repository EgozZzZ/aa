package dev.archive.hackclient.util;

import net.minecraft.block.BlockState;
import net.minecraft.block.Blocks;
import net.minecraft.client.MinecraftClient;
import net.minecraft.item.BlockItem;
import net.minecraft.util.Hand;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.Vec3d;

public final class BlockUtil {
    public static boolean isAir(BlockPos p) { return MinecraftClient.getInstance().world.getBlockState(p).isAir(); }
    public static boolean isReplaceable(BlockPos p) {
        BlockState s = MinecraftClient.getInstance().world.getBlockState(p);
        return s.isReplaceable() && !s.isOf(Blocks.BEDROCK);
    }
    public static int findBlockSlot() {
        MinecraftClient mc = MinecraftClient.getInstance();
        for (int i = 0; i < 9; i++) if (mc.player.getInventory().getStack(i).getItem() instanceof BlockItem) return i;
        return -1;
    }
    public static boolean place(BlockPos pos, Direction side, Vec3d hitVec) {
        MinecraftClient mc = MinecraftClient.getInstance();
        int slot = findBlockSlot();
        if (slot == -1) return false;
        int prev = mc.player.getInventory().selectedSlot;
        mc.player.getInventory().selectedSlot = slot;
        mc.interactionManager.interactBlock(mc.player, Hand.MAIN_HAND,
            new BlockHitResult(hitVec, side, pos, false));
        mc.player.swingHand(Hand.MAIN_HAND);
        mc.player.getInventory().selectedSlot = prev;
        return true;
    }
}
