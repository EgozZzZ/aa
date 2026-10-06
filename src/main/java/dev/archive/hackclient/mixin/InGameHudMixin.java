package dev.archive.hackclient.mixin;

import dev.archive.hackclient.HackClient;
import dev.archive.hackclient.module.impl.render.Crosshair;
import net.minecraft.client.gui.hud.InGameHud;
import net.minecraft.client.gui.DrawContext;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(InGameHud.class)
public class InGameHudMixin {
    @Inject(method = "renderCrosshair", at = @At("HEAD"), cancellable = true)
    private void onRenderCrosshair(DrawContext ctx, CallbackInfo ci) {
        Crosshair cr = HackClient.MODULES.get(Crosshair.class);
        if (cr != null && cr.isEnabled()) ci.cancel();
    }
}
