package dev.archive.hackclient.mixin;

import dev.archive.hackclient.HackClient;
import net.minecraft.client.Keyboard;
import net.minecraft.client.MinecraftClient;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(Keyboard.class)
public class KeyboardMixin {
    @Inject(method = "onKey", at = @At("HEAD"))
    private void onKey(long window, int key, int scancode, int action, int mods, CallbackInfo ci) {
        if (action != 1) return;
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.currentScreen != null) return;
        HackClient.MODULES.onKey(key);
    }
}
