package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.*;
import dev.archive.hackclient.util.*;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.decoration.EndCrystalEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Vec3d;
import java.util.Comparator;

public class CrystalAura extends Module {
    private final NumberSetting placeRange = add(new NumberSetting("PlaceRange", 4.5, 1.0, 6.0, 0.1));
    private final NumberSetting breakRange = add(new NumberSetting("BreakRange", 4.5, 1.0, 6.0, 0.1));
    private final NumberSetting targetRange = add(new NumberSetting("TargetRange", 10.0, 3.0, 16.0, 0.5));
    private final NumberSetting placeDelay = add(new NumberSetting("PlaceDelay", 50.0, 0.0, 500.0, 10.0));
    private final NumberSetting breakDelay = add(new NumberSetting("BreakDelay", 50.0, 0.0, 500.0, 10.0));
    private final NumberSetting minDamage = add(new NumberSetting("MinDamage", 6.0, 0.0, 20.0, 0.5));
    private final NumberSetting maxSelfDamage = add(new NumberSetting("MaxSelfDamage", 8.0, 0.0, 20.0, 0.5));
    private final BooleanSetting antiSuicide = add(new BooleanSetting("AntiSuicide", true));
    private final BooleanSetting rotate = add(new BooleanSetting("Rotate", true));
    private final BooleanSetting autoSwitch = add(new BooleanSetting("AutoSwitch", true));
    private final BooleanSetting autoObsidian = add(new BooleanSetting("AutoObsidian", true));
    private final NumberSetting obsidianRange = add(new NumberSetting("ObsidianRange", 4.5, 1.0, 6.0, 0.1));
    private final ModeSetting targetSort = add(new ModeSetting("TargetSort", "Damage", "Damage", "Distance", "Health"));

    private long lastPlace, lastBreak;
    private LivingEntity target;

    public CrystalAura() { super("CrystalAura", "End crystal PvP", Category.COMBAT); }

    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        target = selectTarget(mc);
        if (target == null) return;

        if (autoObsidian.get()) {
            boolean hasBase = false;
            for (int dx = -2; dx <= 2; dx++)
            for (int dz = -2; dz <= 2; dz++) {
                BlockPos b = target.getBlockPos().add(dx, 0, dz);
                if (mc.world.getBlockState(b).isOf(net.minecraft.block.Blocks.OBSIDIAN)
                    && mc.world.getBlockState(b.up()).isAir()) { hasBase = true; break; }
            }
            if (!hasBase) {
                BlockPos spot = findObsidianSpot(mc, target);
                if (spot != null) {
                    int obsSlot = -1;
                    for (int i = 0; i < 9; i++)
                        if (mc.player.getInventory().getStack(i).getItem() == net.minecraft.item.Items.OBSIDIAN) { obsSlot = i; break; }
                    if (obsSlot != -1) {
                        int prev = mc.player.getInventory().selectedSlot;
                        mc.player.getInventory().selectedSlot = obsSlot;
                        BlockUtil.place(spot, net.minecraft.util.math.Direction.UP,
                            Vec3d.ofCenter(spot.down()).add(0, 0.5, 0));
                        mc.player.getInventory().selectedSlot = prev;
                    }
                }
            }
        }

        if (System.currentTimeMillis() - lastBreak >= breakDelay.get()) {
            EndCrystalEntity c = findBestCrystal(mc);
            if (c != null) {
                if (rotate.get()) {
                    float[] r = RotationUtil.lookAt(c);
                    RotationUtil.apply(mc, r[0], r[1], 60f);
                }
                if (CrystalUtil.breakCrystal(c)) lastBreak = System.currentTimeMillis();
            }
        }

        if (System.currentTimeMillis() - lastPlace >= placeDelay.get()) {
            BlockPos base = findBestBase(mc);
            if (base != null) {
                if (rotate.get()) {
                    float[] r = RotationUtil.lookAt(mc.player.getEyePos(),
                        new Vec3d(base.getX() + 0.5, base.getY() + 1.0, base.getZ() + 0.5));
                    RotationUtil.apply(mc, r[0], r[1], 60f);
                }
                if (CrystalUtil.placeCrystal(base)) lastPlace = System.currentTimeMillis();
            }
        }
    }
    private LivingEntity selectTarget(MinecraftClient mc) {
        return mc.world.getEntitiesByClass(LivingEntity.class,
                mc.player.getBoundingBox().expand(targetRange.get()),
                e -> e != mc.player && e.isAlive() && e instanceof PlayerEntity)
            .stream().min(targetComparator(mc)).orElse(null);
    }
    private Comparator<LivingEntity> targetComparator(MinecraftClient mc) {
        return switch (targetSort.get()) {
            case "Health" -> Comparator.comparingDouble(LivingEntity::getHealth);
            case "Distance" -> Comparator.comparingDouble(e -> e.distanceTo(mc.player));
            default -> Comparator.comparingDouble(e -> -DamageCalc.crystalDamage(e, e.getPos().add(0, 0.5, 0)));
        };
    }
    private BlockPos findObsidianSpot(MinecraftClient mc, LivingEntity target) {
        BlockPos tPos = target.getBlockPos();
        if (mc.world.getBlockState(tPos).isAir()
            && mc.world.getBlockState(tPos.down()).isSolidBlock(mc.world, tPos.down())) {
            if (mc.player.squaredDistanceTo(Vec3d.ofCenter(tPos)) <= obsidianRange.get() * obsidianRange.get())
                return tPos;
        }
        for (net.minecraft.util.math.Direction d : new net.minecraft.util.math.Direction[]{
                net.minecraft.util.math.Direction.NORTH, net.minecraft.util.math.Direction.SOUTH,
                net.minecraft.util.math.Direction.EAST, net.minecraft.util.math.Direction.WEST}) {
            BlockPos p = tPos.offset(d);
            if (!mc.world.getBlockState(p).isAir()) continue;
            if (!mc.world.getBlockState(p.down()).isSolidBlock(mc.world, p.down())) continue;
            if (mc.player.squaredDistanceTo(Vec3d.ofCenter(p)) > obsidianRange.get() * obsidianRange.get()) continue;
            return p;
        }
        return null;
    }
    private BlockPos findBestBase(MinecraftClient mc) {
        BlockPos playerPos = mc.player.getBlockPos();
        BlockPos best = null;
        double bestScore = -Double.MAX_VALUE;
        int r = (int) Math.ceil(placeRange.get());
        for (int dx = -r; dx <= r; dx++)
        for (int dy = -2; dy <= 2; dy++)
        for (int dz = -r; dz <= r; dz++) {
            BlockPos p = playerPos.add(dx, dy, dz);
            if (!mc.world.getBlockState(p).isOf(net.minecraft.block.Blocks.OBSIDIAN)
             && !mc.world.getBlockState(p).isOf(net.minecraft.block.Blocks.BEDROCK)) continue;
            if (!mc.world.getBlockState(p.up()).isAir()) continue;
            if (!mc.world.getBlockState(p.up(2)).isAir()) continue;
            if (mc.player.squaredDistanceTo(Vec3d.ofCenter(p)) > placeRange.get() * placeRange.get()) continue;
            Vec3d crystal = new Vec3d(p.getX() + 0.5, p.getY() + 1.0, p.getZ() + 0.5);
            float dmg = DamageCalc.crystalDamage(target, crystal);
            float self = DamageCalc.selfDamage(crystal);
            if (dmg < minDamage.get()) continue;
            if (self > maxSelfDamage.get()) continue;
            if (antiSuicide.get() && self >= mc.player.getHealth() - 1f) continue;
            double score = dmg - self * 0.5;
            if (score > bestScore) { bestScore = score; best = p; }
        }
        return best;
    }
    private EndCrystalEntity findBestCrystal(MinecraftClient mc) {
        return mc.world.getEntitiesByClass(EndCrystalEntity.class,
                mc.player.getBoundingBox().expand(breakRange.get()), e -> true)
            .stream().min(Comparator.comparingDouble(e -> {
                float dmg = DamageCalc.crystalDamage(target, e.getPos());
                float self = DamageCalc.crystalDamage(mc.player, e.getPos());
                if (self > maxSelfDamage.get()) return Double.MAX_VALUE;
                return -(dmg - self * 0.5);
            })).orElse(null);
    }
}
