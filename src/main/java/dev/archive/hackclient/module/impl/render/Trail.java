package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.util.math.Vec3d;
import java.util.*;

public class Trail extends Module {
    public final BooleanSetting self = add(new BooleanSetting("Self", true));
    public final BooleanSetting players = add(new BooleanSetting("Players", false));
    public final NumberSetting length = add(new NumberSetting("Length", 24.0, 4.0, 100.0, 1.0));
    public final NumberSetting opacity = add(new NumberSetting("Opacity", 0.5, 0.1, 1.0, 0.05));
    public final Map<UUID, Deque<Vec3d>> trails = new HashMap<>();

    public Trail() { super("Trail", "Motion trails behind entities", Category.RENDER); }
    public void push(UUID id, Vec3d pos) {
        Deque<Vec3d> d = trails.computeIfAbsent(id, k -> new ArrayDeque<>());
        d.addLast(pos);
        while (d.size() > length.getInt()) d.removeFirst();
    }
    @Override public void onDisable() { trails.clear(); }
}
