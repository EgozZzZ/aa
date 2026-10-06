package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.network.PlayerListEntry;

public class DonutAdminDetector extends Module {
    private final BooleanSetting disconnect = add(new BooleanSetting("Disconnect", true));
    public DonutAdminDetector() { super("DonutAdminDetector", "Disconnects when staff in tab", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.getNetworkHandler() == null) return;
        for (PlayerListEntry e : mc.getNetworkHandler().getPlayerList()) {
            if (e.getDisplayName() != null) {
                String dn = e.getDisplayName().getString().toLowerCase();
                if (dn.contains("admin") || dn.contains("mod") || dn.contains("owner")
                    || dn.contains("[staff]") || dn.contains("[admin]")) {
                    if (disconnect.get())
                        mc.getNetworkHandler().getConnection().disconnect(
                            net.minecraft.text.Text.literal("Admin: " + e.getProfile().getName()));
                }
            }
        }
    }
}
