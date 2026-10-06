package dev.archive.hackclient.mixin;

import dev.archive.hackclient.HackClient;
import dev.archive.hackclient.module.impl.combat.Criticals;
import dev.archive.hackclient.module.impl.render.TargetHud;
import dev.archive.hackclient.module.impl.sound.HitSound;
import net.minecraft.entity.Entity;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.player.PlayerEntity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(PlayerEntity.class)
public class PlayerEntityMixin {
    @Inject(method = "attack", at = @At("HEAD"))
    private void onAttack(Entity target, CallbackInfo ci) {
        Criticals c = HackClient.MODULES.get(Criticals.class);
        if (c != null) c.doCrit(target);
        if (target instanceof LivingEntity le) {
            TargetHud th = HackClient.MODULES.get(TargetHud.class);
            if (th != null) th.setTarget(le);
            HitSound hs = HackClient.MODULES.get(HitSound.class);
            if (hs != null && hs.isEnabled()) hs.onHit(le);
        }
    }
}
