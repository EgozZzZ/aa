package dev.archive.hackclient.mixin;

import dev.archive.hackclient.HackClient;
import dev.archive.hackclient.module.impl.combat.Reach;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.Entity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(Entity.class)
public class EntityMixin {
    @Inject(method = "getTargetingMargin", at = @At("RETURN"), cancellable = true)
    private void onTargetingMargin(CallbackInfoReturnable<Float> cir) {
        Reach r = HackClient.MODULES.get(Reach.class);
        if (r != null && r.isEnabled() && (Object)this == MinecraftClient.getInstance().player)
            cir.setReturnValue(r.entityReach.getFloat() - 3.0f);
    }
}
