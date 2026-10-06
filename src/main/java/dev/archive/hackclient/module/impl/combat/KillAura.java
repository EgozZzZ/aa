package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.*;
import dev.archive.hackclient.util.RotationUtil;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.Entity;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.util.Hand;
import java.util.Comparator;

public class KillAura extends Module {
    private final NumberSetting range = add(new NumberSetting("Range", 3.0, 1.0, 6.0, 0.1));
    private final NumberSetting cps = add(new NumberSetting("CPS", 12.0, 1.0, 20.0, 1.0));
    private final NumberSetting rotSpeed = add(new NumberSetting("RotSpeed", 40.0, 5.0, 180.0, 1.0));
    private final BooleanSetting players = add(new BooleanSetting("Players", true));
    private final BooleanSetting mobs = add(new BooleanSetting("Mobs", false));
    private final BooleanSetting throughWalls = add(new BooleanSetting("ThroughWalls", false));
    private final ModeSetting sort = add(new ModeSetting("Sort", "Distance", "Distance", "Health", "Angle"));
    private final BooleanSetting silent = add(new BooleanSetting("Silent", true));

    private long lastAttack;
    private Entity target;

    public KillAura() { super("KillAura", "Auto-attacks nearby entities", Category.COMBAT); }

    @Override
    public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        target = pick(mc);
        if (target == null) return;
        float[] rot = RotationUtil.lookAt(target);
        if (silent.get()) RotationUtil.apply(mc, rot[0], rot[1], rotSpeed.getFloat());
        else RotationUtil.snap(mc, rot[0], rot[1]);
        long now = System.currentTimeMillis();
        long delay = (long)(1000.0 / cps.get());
        if (now - lastAttack >= delay) {
            mc.interactionManager.attackEntity(mc.player, target);
            mc.player.swingHand(Hand.MAIN_HAND);
            lastAttack = now;
        }
    }
    private Entity pick(MinecraftClient mc) {
        return mc.world.getEntitiesByClass(LivingEntity.class,
                mc.player.getBoundingBox().expand(range.get()),
                e -> e != mc.player && e.isAlive() && filter(e))
            .stream()
            .filter(e -> throughWalls.get() || mc.player.canSee(e))
            .min(comparator(mc)).orElse(null);
    }
    private boolean filter(Entity e) {
        if (e instanceof PlayerEntity) return players.get();
        return mobs.get();
    }
    private Comparator<Entity> comparator(MinecraftClient mc) {
        return switch (sort.get()) {
            case "Health" -> Comparator.comparingDouble(e -> ((LivingEntity)e).getHealth());
            case "Angle" -> Comparator.comparingDouble(e -> {
                float[] r = RotationUtil.lookAt(e);
                return Math.abs(net.minecraft.util.math.MathHelper.wrapDegrees(r[0] - mc.player.getYaw()));
            });
            default -> Comparator.comparingDouble(e -> e.distanceTo(mc.player));
        };
    }
}
