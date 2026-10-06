package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.Entity;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.player.PlayerEntity;

public class ESP extends Module {
    public final BooleanSetting players = add(new BooleanSetting("Players", true));
    public final BooleanSetting mobs = add(new BooleanSetting("Mobs", false));
    public final NumberSetting range = add(new NumberSetting("Range", 64.0, 8.0, 256.0, 8.0));
    public ESP() { super("ESP", "Outline entities", Category.RENDER); }
    public boolean shouldRender(Entity e) {
        if (!isEnabled() || e == MinecraftClient.getInstance().player) return false;
        double r = range.get();
        if (MinecraftClient.getInstance().player.squaredDistanceTo(e) > r * r) return false;
        if (e instanceof PlayerEntity) return players.get();
        if (e instanceof LivingEntity) return mobs.get();
        return false;
    }
}
