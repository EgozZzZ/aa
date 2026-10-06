package dev.archive.hackclient.util;

import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.Entity;
import net.minecraft.util.math.MathHelper;
import net.minecraft.util.math.Vec3d;

public final class RotationUtil {
    public static float[] lookAt(Vec3d from, Vec3d to) {
        double dx = to.x - from.x, dy = to.y - from.y, dz = to.z - from.z;
        double dist = Math.sqrt(dx * dx + dz * dz);
        float yaw = (float)(Math.toDegrees(Math.atan2(dz, dx)) - 90.0);
        float pitch = (float)(-Math.toDegrees(Math.atan2(dy, dist)));
        return new float[]{ yaw, pitch };
    }
    public static float[] lookAt(Entity target) {
        MinecraftClient mc = MinecraftClient.getInstance();
        Vec3d eyes = mc.player.getEyePos();
        Vec3d t = new Vec3d(target.getX(), target.getY() + target.getHeight() * 0.5, target.getZ());
        return lookAt(eyes, t);
    }
    public static void apply(MinecraftClient mc, float yaw, float pitch, float speed) {
        float dy = MathHelper.wrapDegrees(yaw - mc.player.getYaw());
        float dp = MathHelper.wrapDegrees(pitch - mc.player.getPitch());
        float cy = Math.min(Math.abs(dy), speed) * Math.signum(dy);
        float cp = Math.min(Math.abs(dp), speed) * Math.signum(dp);
        mc.player.setYaw(mc.player.getYaw() + cy);
        mc.player.setPitch(MathHelper.clamp(mc.player.getPitch() + cp, -90f, 90f));
    }
    public static void snap(MinecraftClient mc, float yaw, float pitch) {
        mc.player.setYaw(yaw);
        mc.player.setPitch(MathHelper.clamp(pitch, -90f, 90f));
    }
}
