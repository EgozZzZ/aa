package dev.archive.hackclient.mixin;

import dev.archive.hackclient.HackClient;
import dev.archive.hackclient.module.impl.render.Ambience;
import net.minecraft.client.render.LightmapTextureManager;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.ModifyVariable;

@Mixin(LightmapTextureManager.class)
public class LightmapTextureManagerMixin {
    @ModifyVariable(method = "update", at = @At("HEAD"), argsOnly = true, index = 1)
    private float modifyGamma(float gamma) {
        Ambience a = HackClient.MODULES.get(Ambience.class);
        if (a != null && a.isEnabled() && a.fullBright.get()) return 10.0f;
        return gamma;
    }
}
