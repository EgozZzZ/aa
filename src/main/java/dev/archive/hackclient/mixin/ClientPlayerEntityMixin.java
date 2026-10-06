package dev.archive.hackclient.mixin;

import dev.archive.hackclient.HackClient;
import dev.archive.hackclient.module.impl.combat.Velocity;
import net.minecraft.client.network.ClientPlayerEntity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(ClientPlayerEntity.class)
public class ClientPlayerEntityMixin {
    @Inject(method = "setVelocityClient", at = @At("HEAD"), cancellable = true)
    private void onVelocity(double x, double y, double z, CallbackInfo ci) {
        Velocity v = HackClient.MODULES.get(Velocity.class);
        if (v != null && v.isEnabled()) {
            ClientPlayerEntity self = (ClientPlayerEntity)(Object)this;
            self.setVelocity(x * v.horizontal.get() / 100.0, y * v.vertical.get() / 100.0, z * v.horizontal.get() / 100.0);
            ci.cancel();
        }
    }
}
