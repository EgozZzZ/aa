package dev.archive.hackclient.setting;

public abstract class Setting<T> {
    public final String name;
    protected T value;
    public Setting(String name, T value) { this.name = name; this.value = value; }
    public T getRaw() { return value; }
    public void setRaw(T v) { this.value = v; }
    public abstract String display();
}
