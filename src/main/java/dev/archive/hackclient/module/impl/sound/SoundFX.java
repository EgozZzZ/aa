package dev.archive.hackclient.module.impl.sound;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;

public class SoundFX extends Module {
    private final NumberSetting volume = add(new NumberSetting("Volume", 60.0, 0.0, 100.0, 5.0));
    public SoundFX() { super("SoundFX", "Master sound layer", Category.RENDER); }
    @Override public void onEnable() { dev.archive.hackclient.sound.SoundManager.setVolume(volume.getFloat() / 100f); }
    @Override public void onTick() { dev.archive.hackclient.sound.SoundManager.setVolume(volume.getFloat() / 100f); }
}
