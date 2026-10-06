package dev.archive.hackclient.util;

import net.minecraft.entity.LivingEntity;
import net.minecraft.util.math.Vec3d;

public final class DamageCalc {
    private static final double CRYSTAL_POWER = 12.0;
    public static float crystalDamage(LivingEntity target, Vec3d crystalPos) {
        double dist = Math.sqrt(target.squaredDistanceTo(crystalPos));
        double exposure = 1.0 - Math.min(1.0, dist / 12.0);
        double raw = CRYSTAL_POWER * exposure * exposure;
        return Math.max((float) raw, 0f);
    }
    public static float selfDamage(Vec3d pos) {
        return crystalDamage(net.minecraft.client.MinecraftClient.getInstance().player, pos);
    }
}
