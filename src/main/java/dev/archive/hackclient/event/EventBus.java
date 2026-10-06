package dev.archive.hackclient.event;

import java.util.*;
import java.util.function.Consumer;

public class EventBus {
    private final Map<Class<?>, List<Consumer<?>>> handlers = new HashMap<>();
    public <T> void subscribe(Class<T> type, Consumer<T> handler) {
        handlers.computeIfAbsent(type, k -> new ArrayList<>()).add(handler);
    }
    @SuppressWarnings("unchecked")
    public <T> void post(T event) {
        List<Consumer<?>> list = handlers.get(event.getClass());
        if (list == null) return;
        for (Consumer<?> c : list) ((Consumer<T>) c).accept(event);
    }
    public static class TickEvent {}
}
