package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.ModeSetting;
import net.minecraft.entity.LivingEntity;

public class TargetHud extends Module {
    public final ModeSetting style = add(new ModeSetting("Style", "Glass", "Glass", "Mio", "Vega", "Minimal"));
    public final BooleanSetting health = add(new BooleanSetting("Health", true));
    public final BooleanSetting armor = add(new BooleanSetting("Armor", true));
    public final BooleanSetting ping = add(new BooleanSetting("Ping", true));
    public final BooleanSetting animation = add(new BooleanSetting("Animation", true));
    public LivingEntity lastTarget;
    public TargetHud() { super("TargetHud", "Info panel on last attack target", Category.RENDER); }
    public void setTarget(LivingEntity t) { this.lastTarget = t; }
}
