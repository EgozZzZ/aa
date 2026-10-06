package dev.archive.hackclient.util;

import net.minecraft.client.MinecraftClient;
import net.minecraft.network.packet.Packet;

public final class PacketUtil {
    public static void send(Packet<?> packet) {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.getNetworkHandler() != null) mc.getNetworkHandler().sendPacket(packet);
    }
}
