package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.*;
import dev.archive.hackclient.util.InventoryUtil;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.item.Items;
import net.minecraft.util.Hand;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.Vec3d;
import java.util.Comparator;

public class BedAura extends Module {
    private final NumberSetting range = add(new NumberSetting("Range", 4.5, 1.0, 6.0, 0.1));
    private final NumberSetting delay = add(new NumberSetting("Delay", 100.0, 0.0, 500.0, 10.0));
    private final NumberSetting minDamage = add(new NumberSetting("MinDamage", 6.0, 0.0, 20.0, 0.5));
    private final NumberSetting maxSelfDamage = add(new NumberSetting("MaxSelfDamage", 10.0, 0.0, 20.0, 0.5));
    private long last;

    public BedAura() { super("BedAura", "Auto bed bombing", Category.COMBAT); }

    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        if (mc.world.getRegistryKey().getValue().getPath().equals("overworld")) return;
        if (System.currentTimeMillis() - last < delay.get()) return;
        LivingEntity target = mc.world.getEntitiesByClass(LivingEntity.class,
                mc.player.getBoundingBox().expand(range.get()),
                e -> e != mc.player && e.isAlive() && e instanceof PlayerEntity)
            .stream().min(Comparator.comparingDouble(e -> e.distanceTo(mc.player))).orElse(null);
        if (target == null) return;
        int bedSlot = InventoryUtil.findSlotHotbar(Items.RED_BED);
        if (bedSlot == -1) return;
        BlockPos tPos = target.getBlockPos();
        for (Direction d : Direction.values()) {
            if (d.getAxis().isVertical()) continue;
            BlockPos place = tPos.offset(d);
            BlockPos support = place.down();
            if (!mc.world.getBlockState(support).isSolidBlock(mc.world, support)) continue;
            if (!mc.world.getBlockState(place).isAir()) continue;
            if (mc.player.squaredDistanceTo(Vec3d.ofCenter(place)) > range.get() * range.get()) continue;
            int prev = mc.player.getInventory().selectedSlot;
            mc.player.getInventory().selectedSlot = bedSlot;
            mc.interactionManager.interactBlock(mc.player, Hand.MAIN_HAND,
                new BlockHitResult(Vec3d.ofCenter(support).add(0, 0.5, 0), Direction.UP, support, false));
            mc.player.swingHand(Hand.MAIN_HAND);
            mc.player.getInventory().selectedSlot = prev;
            mc.interactionManager.interactBlock(mc.player, Hand.MAIN_HAND,
                new BlockHitResult(Vec3d.ofCenter(place), Direction.UP, place, false));
            last = System.currentTimeMillis();
            return;
        }
    }
}
