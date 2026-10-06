package dev.archive.hackclient.module.impl.player;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.block.BlockState;
import net.minecraft.util.math.BlockPos;

public class AutoTool extends Module {
    private final BooleanSetting swapBack = add(new BooleanSetting("SwapBack", false));
    private int prevSlot = -1;
    public AutoTool() { super("AutoTool", "Picks best tool for block", Category.PLAYER); }
    public void onBlockBreaking(BlockPos pos) {
        if (!isEnabled()) return;
        MinecraftClient mc = MinecraftClient.getInstance();
        BlockState state = mc.world.getBlockState(pos);
        int best = -1;
        float bestSpeed = 1.0f;
        for (int i = 0; i < 9; i++) {
            var stack = mc.player.getInventory().getStack(i);
            float s = stack.getMiningSpeedMultiplier(state);
            if (s > bestSpeed) { bestSpeed = s; best = i; }
        }
        if (best != -1) {
            if (prevSlot == -1) prevSlot = mc.player.getInventory().selectedSlot;
            mc.player.getInventory().selectedSlot = best;
        }
    }
    @Override public void onDisable() {
        if (swapBack.get() && prevSlot != -1) {
            MinecraftClient mc = MinecraftClient.getInstance();
            if (mc.player != null) mc.player.getInventory().selectedSlot = prevSlot;
        }
        prevSlot = -1;
    }
}
