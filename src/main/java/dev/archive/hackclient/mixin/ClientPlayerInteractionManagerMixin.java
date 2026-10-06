package dev.archive.hackclient.mixin;

import dev.archive.hackclient.HackClient;
import dev.archive.hackclient.module.impl.combat.Reach;
import net.minecraft.client.network.ClientPlayerInteractionManager;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(ClientPlayerInteractionManager.class)
public class ClientPlayerInteractionManagerMixin {
    @Inject(method = "getReachDistance", at = @At("RETURN"), cancellable = true)
    private void onGetReach(CallbackInfoReturnable<Float> cir) {
        Reach r = HackClient.MODULES.get(Reach.class);
        if (r != null && r.isEnabled()) cir.setReturnValue(r.blockReach.getFloat());
    }
}
