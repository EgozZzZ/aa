package dev.archive.hackclient.module.impl.misc;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;

public class AntiPacket extends Module {
    public final BooleanSetting cancelSetback = add(new BooleanSetting("CancelSetback", true));
    public final BooleanSetting cancelRotate = add(new BooleanSetting("CancelRotate", false));
    public AntiPacket() { super("AntiPacket", "Drop server correction packets", Category.MISC); }
}
