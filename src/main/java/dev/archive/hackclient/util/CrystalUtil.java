package dev.archive.hackclient.util;

import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.decoration.EndCrystalEntity;
import net.minecraft.item.Items;
import net.minecraft.util.Hand;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Box;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.Vec3d;

public final class CrystalUtil {
    public static int crystalSlot() {
        MinecraftClient mc = MinecraftClient.getInstance();
        for (int i = 0; i < 9; i++) if (mc.player.getInventory().getStack(i).getItem() == Items.END_CRYSTAL) return i;
        return -1;
    }
    public static boolean placeCrystal(BlockPos base) {
        MinecraftClient mc = MinecraftClient.getInstance();
        int slot = crystalSlot();
        if (slot == -1) return false;
        BlockPos above = base.up();
        if (!mc.world.getBlockState(above).isAir()) return false;
        int prev = mc.player.getInventory().selectedSlot;
        mc.player.getInventory().selectedSlot = slot;
        mc.interactionManager.interactBlock(mc.player, Hand.MAIN_HAND,
            new BlockHitResult(new Vec3d(above.getX() + 0.5, above.getY(), above.getZ() + 0.5),
                Direction.UP, base, false));
        mc.player.swingHand(Hand.MAIN_HAND);
        mc.player.getInventory().selectedSlot = prev;
        return true;
    }
    public static EndCrystalEntity findCrystal(BlockPos base, double range) {
        MinecraftClient mc = MinecraftClient.getInstance();
        Box box = new Box(base.up()).expand(range);
        return mc.world.getEntitiesByClass(EndCrystalEntity.class, box, e -> true)
            .stream().findFirst().orElse(null);
    }
    public static boolean breakCrystal(EndCrystalEntity c) {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player.distanceTo(c) > 6.0) return false;
        mc.interactionManager.attackEntity(mc.player, c);
        mc.player.swingHand(Hand.MAIN_HAND);
        return true;
    }
}
