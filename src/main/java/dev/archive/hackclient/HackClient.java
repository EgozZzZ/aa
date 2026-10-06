package dev.archive.hackclient;

import dev.archive.hackclient.event.EventBus;
import dev.archive.hackclient.module.ModuleManager;
import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;

public class HackClient implements ClientModInitializer {
    public static final String NAME = "HackClient";
    public static final String VERSION = "3.0.0";
    public static HackClient INSTANCE;
    public static ModuleManager MODULES;
    public static EventBus EVENTS;

    @Override
    public void onInitializeClient() {
        INSTANCE = this;
        EVENTS = new EventBus();
        MODULES = new ModuleManager();
        MODULES.init();
        ClientTickEvents.END_CLIENT_TICK.register(c -> MODULES.onTick());
        System.out.println("[HackClient] loaded " + MODULES.all().size() + " modules");
    }
}
