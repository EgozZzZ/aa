package dev.archive.hackclient.module;

public final class HackClientBridge {
    public static <T extends Module> T get(Class<T> c) {
        if (dev.archive.hackclient.HackClient.MODULES == null) return null;
        return dev.archive.hackclient.HackClient.MODULES.get(c);
    }
}
