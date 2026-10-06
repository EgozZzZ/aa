package dev.archive.hackclient.module.impl.sound;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.entity.LivingEntity;

public class KillSound extends Module {
    private final NumberSetting volume = add(new NumberSetting("Volume", 0.6, 0.1, 1.0, 0.05));
    private final NumberSetting pitch = add(new NumberSetting("Pitch", 1.0, 0.5, 2.0, 0.05));
    public KillSound() { super("KillSound", "Tone on entity death", Category.RENDER); }
    public void onKill(LivingEntity e) {
        dev.archive.hackclient.sound.SoundManager.play(
            dev.archive.hackclient.sound.Tone.KILL,
            dev.archive.hackclient.sound.Synth.SR * pitch.getFloat());
    }
}
