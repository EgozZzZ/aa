package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.util.math.Vec3d;
import java.util.*;

public class Breadcrumbs extends Module {
    public final NumberSetting length = add(new NumberSetting("Length", 200.0, 20.0, 1000.0, 10.0));
    public final NumberSetting opacity = add(new NumberSetting("Opacity", 0.7, 0.1, 1.0, 0.05));
    public final Deque<Vec3d> points = new ArrayDeque<>();

    public Breadcrumbs() { super("Breadcrumbs", "Dotted path behind player", Category.RENDER); }
    @Override public void onTick() {
        var mc = net.minecraft.client.MinecraftClient.getInstance();
        if (mc.player == null) return;
        points.addLast(mc.player.getPos());
        while (points.size() > length.getInt()) points.removeFirst();
    }
    @Override public void onDisable() { points.clear(); }
}
