package dev.archive.hackclient.mixin;

import dev.archive.hackclient.HackClient;
import dev.archive.hackclient.module.impl.render.Chams;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.render.entity.EntityRenderDispatcher;
import net.minecraft.entity.Entity;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.player.PlayerEntity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(EntityRenderDispatcher.class)
public class EntityRenderDispatcherMixin {
    @Inject(method = "shouldRender", at = @At("RETURN"), cancellable = true)
    private void onShouldRender(Entity e, net.minecraft.client.util.math.MatrixStack ms,
                                net.minecraft.client.render.VertexConsumerProvider vcp,
                                net.minecraft.client.render.VertexConsumer vc,
                                net.minecraft.client.render.Frustum f,
                                double x, double y, double z,
                                CallbackInfoReturnable<Boolean> cir) {
        Chams c = HackClient.MODULES.get(Chams.class);
        if (c == null || !c.isEnabled()) return;
        if (!(e instanceof LivingEntity)) return;
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        double r2 = c.range.get() * c.range.get();
        if (mc.player.squaredDistanceTo(e) > r2) return;
        if (e == mc.player && !c.self.get()) return;
        if (e instanceof PlayerEntity && !c.players.get()) return;
        if (!(e instanceof PlayerEntity) && !c.mobs.get()) return;
        cir.setReturnValue(true);
    }
}
