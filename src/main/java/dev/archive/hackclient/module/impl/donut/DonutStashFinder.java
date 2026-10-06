package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.block.Blocks;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.ChunkPos;
import java.util.*;

public class DonutStashFinder extends Module {
    private final NumberSetting range = add(new NumberSetting("Range", 32.0, 8.0, 128.0, 8.0));
    private final NumberSetting minContainers = add(new NumberSetting("MinContainers", 4.0, 1.0, 32.0, 1.0));
    private final BooleanSetting disconnect = add(new BooleanSetting("Disconnect", false));
    private final Map<ChunkPos, Integer> hits = new HashMap<>();

    public DonutStashFinder() { super("DonutStashFinder", "Scans for container clusters", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        int r = (int) Math.ceil(range.get());
        BlockPos center = mc.player.getBlockPos();
        for (int dx = -r; dx <= r; dx += 4)
        for (int dy = -32; dy <= 32; dy += 4)
        for (int dz = -r; dz <= r; dz += 4) {
            BlockPos p = center.add(dx, dy, dz);
            var block = mc.world.getBlockState(p).getBlock();
            if (block == Blocks.CHEST || block == Blocks.TRAPPED_CHEST || block == Blocks.BARREL
                || block == Blocks.SHULKER_BOX || block == Blocks.ENDER_CHEST) {
                ChunkPos cp = new ChunkPos(p);
                hits.merge(cp, 1, Integer::sum);
                if (hits.get(cp) >= minContainers.get()) {
                    if (disconnect.get())
                        mc.getNetworkHandler().getConnection().disconnect(
                            net.minecraft.text.Text.literal("Stash: " + cp.x + "," + cp.z));
                    hits.remove(cp);
                }
            }
        }
    }
    @Override public void onDisable() { hits.clear(); }
}
