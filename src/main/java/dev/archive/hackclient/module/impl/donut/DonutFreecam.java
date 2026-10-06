package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.util.math.Vec3d;

public class DonutFreecam extends Module {
    private final NumberSetting speed = add(new NumberSetting("Speed", 1.0, 0.1, 5.0, 0.1));
    private Vec3d pos;
    public DonutFreecam() { super("DonutFreecam", "Detached camera", Category.DONUT); }
    @Override public void onEnable() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player != null) pos = mc.player.getPos();
    }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || pos == null) return;
        Vec3d fwd = Vec3d.fromPolar(0, mc.player.getYaw()).multiply(speed.get() * 0.1);
        if (mc.options.forwardKey.isPressed()) pos = pos.add(fwd);
        if (mc.options.backKey.isPressed()) pos = pos.subtract(fwd);
        if (mc.options.jumpKey.isPressed()) pos = pos.add(0, speed.get() * 0.1, 0);
        if (mc.options.sneakKey.isPressed()) pos = pos.subtract(0, speed.get() * 0.1, 0);
    }
    @Override public void onDisable() { pos = null; }
    public Vec3d getCamPos() { return pos; }
}
