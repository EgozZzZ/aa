#!/usr/bin/env bash
# HackClient 3.0.0 — chunk 1/4. Appends chunks 2-4 before running.
set -euo pipefail
ROOT="${ROOT:-$HOME/hackclient}"
echo "[chunk1] root=$ROOT"
rm -rf "$ROOT"; mkdir -p "$ROOT"; cd "$ROOT"

# ---------- .gitignore ----------
cat > .gitignore <<'EOF'
.gradle/
build/
out/
run/
*.iml
.idea/
.vscode/
*.log
EOF

# ---------- GitHub Actions ----------
mkdir -p .github/workflows
cat > .github/workflows/build.yml <<'EOF'
name: Build HackClient
on:
  push: { branches: [ main ] }
  pull_request: { branches: [ main ] }
  workflow_dispatch:
jobs:
  build:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - uses: gradle/actions/wrapper-validation@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '21'
          distribution: 'microsoft'
      - uses: gradle/actions/setup-gradle@v4
      - run: chmod +x gradlew
      - run: ./gradlew clean build --no-daemon --stacktrace
      - uses: actions/upload-artifact@v4
        with:
          name: hackclient-jar
          path: build/libs/*.jar
          if-no-files-found: error
EOF

# ---------- gradle wrapper ----------
mkdir -p gradle/wrapper
cat > gradle/wrapper/gradle-wrapper.properties <<'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.10.2-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
if [ ! -f gradle/wrapper/gradle-wrapper.jar ]; then
  echo "[chunk1] fetching gradle-wrapper.jar"
  curl -fsSL -o gradle/wrapper/gradle-wrapper.jar \
    https://raw.githubusercontent.com/gradle/gradle/v8.10.2/gradle/wrapper/gradle-wrapper.jar
fi
cat > gradlew <<'EOF'
#!/usr/bin/env sh
DIR="$(cd "$(dirname "$0")" && pwd)"
exec java -classpath "$DIR/gradle/wrapper/gradle-wrapper.jar" org.gradle.wrapper.GradleWrapperMain "$@"
EOF
chmod +x gradlew
cat > gradlew.bat <<'EOF'
@echo off
java -classpath "%~dp0gradle\wrapper\gradle-wrapper.jar" org.gradle.wrapper.GradleWrapperMain %*
EOF

# ---------- gradle config ----------
cat > gradle.properties <<'EOF'
org.gradle.jvmargs=-Xmx2G
minecraft_version=1.21.4
yarn_mappings=1.21.4+build.8
loader_version=0.16.10
fabric_version=0.119.2+1.21.4
mod_version=3.0.0
maven_group=dev.archive
archives_base_name=hackclient
EOF
cat > settings.gradle <<'EOF'
pluginManagement {
    repositories {
        maven { name = 'Fabric'; url = 'https://maven.fabricmc.net/' }
        gradlePluginPortal()
    }
}
rootProject.name = 'hackclient'
EOF
cat > build.gradle <<'EOF'
plugins {
    id 'fabric-loom' version '1.9-SNAPSHOT'
    id 'maven-publish'
}
version = project.mod_version
group = project.maven_group
base { archivesName = project.archives_base_name }
repositories {
    maven { name = 'Fabric'; url = 'https://maven.fabricmc.net/' }
}
dependencies {
    minecraft "com.mojang:minecraft:${project.minecraft_version}"
    mappings "net.fabricmc:yarn:${project.yarn_mappings}:v2"
    modImplementation "net.fabricmc:fabric-loader:${project.loader_version}"
    modImplementation "net.fabricmc.fabric-api:fabric-api:${project.fabric_version}"
}
processResources {
    inputs.property "version", project.version
    filesMatching("fabric.mod.json") { expand "version": project.version }
}
tasks.withType(JavaCompile).configureEach { it.options.release = 21 }
java {
    withSourcesJar()
    sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
}
EOF

# ---------- resources ----------
mkdir -p src/main/resources
cat > src/main/resources/fabric.mod.json <<'EOF'
{
  "schemaVersion": 1,
  "id": "hackclient",
  "version": "${version}",
  "name": "HackClient",
  "environment": "client",
  "entrypoints": { "client": ["dev.archive.hackclient.HackClient"] },
  "mixins": ["hackclient.mixins.json"],
  "depends": { "fabricloader": ">=0.16.0", "fabric-api": "*", "minecraft": "1.21.4" }
}
EOF
cat > src/main/resources/hackclient.mixins.json <<'EOF'
{
  "required": true,
  "package": "dev.archive.hackclient.mixin",
  "compatibilityLevel": "JAVA_21",
  "client": [
    "KeyboardMixin",
    "ClientPlayerEntityMixin",
    "PlayerEntityMixin",
    "ClientPlayerInteractionManagerMixin",
    "EntityMixin",
    "EntityRenderDispatcherMixin",
    "InGameHudMixin",
    "LightmapTextureManagerMixin"
  ],
  "injectors": { "defaultRequire": 1 }
}
EOF

# ---------- dirs ----------
B=src/main/java/dev/archive/hackclient
mkdir -p "$B"/{event,module/impl/{combat,movement,render,player,misc,donut,sound},setting,gui,util,sound,mixin}

# ---------- core ----------
cat > "$B/HackClient.java" <<'EOF'
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
EOF

cat > "$B/event/EventBus.java" <<'EOF'
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
EOF

cat > "$B/module/Category.java" <<'EOF'
package dev.archive.hackclient.module;

public enum Category {
    COMBAT, MOVEMENT, RENDER, PLAYER, MISC, DONUT
}
EOF

cat > "$B/module/Module.java" <<'EOF'
package dev.archive.hackclient.module;

import dev.archive.hackclient.setting.Setting;
import java.util.ArrayList;
import java.util.List;

public abstract class Module {
    public final String name;
    public final String description;
    public final Category category;
    public final List<Setting<?>> settings = new ArrayList<>();
    public int keybind = -1;
    private boolean enabled;

    public Module(String name, String description, Category category) {
        this.name = name; this.description = description; this.category = category;
    }
    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean e) {
        if (this.enabled == e) return;
        this.enabled = e;
        try {
            var es = HackClientBridge.get(dev.archive.hackclient.module.impl.sound.EnableSound.class);
            if (es != null && es.isEnabled()) {
                dev.archive.hackclient.sound.SoundManager.play(
                    e ? dev.archive.hackclient.sound.Tone.MODULE_ON
                      : dev.archive.hackclient.sound.Tone.MODULE_OFF,
                    dev.archive.hackclient.sound.Synth.SR);
            }
        } catch (Throwable ignored) {}
        if (e) onEnable(); else onDisable();
    }
    public void toggle() { setEnabled(!enabled); }
    public void onEnable() {}
    public void onDisable() {}
    public void onTick() {}
    protected <T extends Setting<?>> T add(T s) { settings.add(s); return s; }
}
EOF

cat > "$B/module/HackClientBridge.java" <<'EOF'
package dev.archive.hackclient.module;

public final class HackClientBridge {
    public static <T extends Module> T get(Class<T> c) {
        if (dev.archive.hackclient.HackClient.MODULES == null) return null;
        return dev.archive.hackclient.HackClient.MODULES.get(c);
    }
}
EOF

cat > "$B/module/ModuleManager.java" <<'EOF'
package dev.archive.hackclient.module;

import dev.archive.hackclient.module.impl.combat.*;
import dev.archive.hackclient.module.impl.movement.*;
import dev.archive.hackclient.module.impl.player.*;
import dev.archive.hackclient.module.impl.render.*;
import dev.archive.hackclient.module.impl.misc.*;
import dev.archive.hackclient.module.impl.donut.*;
import dev.archive.hackclient.module.impl.sound.*;
import net.minecraft.client.MinecraftClient;
import java.util.*;

public class ModuleManager {
    private final List<Module> modules = new ArrayList<>();
    private final Map<Class<?>, Module> byClass = new HashMap<>();
    private final Set<Integer> killTracked = new HashSet<>();

    public void init() {
        reg(new KillAura()); reg(new Criticals()); reg(new AutoTotem()); reg(new Velocity());
        reg(new CrystalAura()); reg(new BedAura()); reg(new Surround()); reg(new HoleFill());
        reg(new AutoArmor()); reg(new AutoRegear()); reg(new AutoTrap()); reg(new AutoExp());
        reg(new Reach()); reg(new AutoLogout()); reg(new AntiPhase());

        reg(new Sprint()); reg(new NoSlow()); reg(new Flight()); reg(new Speed());
        reg(new Phase()); reg(new NoFall()); reg(new Step()); reg(new Scaffold());

        reg(new ESP()); reg(new Tracers()); reg(new Nametags());
        reg(new Wings()); reg(new Chams()); reg(new VegaLines()); reg(new ChinaHat());
        reg(new Trail()); reg(new TargetHud()); reg(new Breadcrumbs()); reg(new Particles());
        reg(new Crosshair()); reg(new Watermark()); reg(new Ambience());
        reg(new BlockHighlight()); reg(new StorageESP()); reg(new HoleESP()); reg(new Trajectories());

        reg(new AutoTool()); reg(new FastPlace());
        reg(new AntiPacket());

        reg(new DonutStashFinder()); reg(new DonutSpawnerProtect()); reg(new DonutSpawnerSell());
        reg(new DonutAutoSell()); reg(new DonutAHSell()); reg(new DonutOrderDropper());
        reg(new DonutEmergencyDisconnect()); reg(new DonutStorageStealer()); reg(new DonutAdminDetector());
        reg(new DonutAntiTrap()); reg(new DonutFreecam()); reg(new DonutNoBlockInteract());
        reg(new DonutAutoPearlChain()); reg(new DonutAnchorMacro()); reg(new DonutKeyPearl());

        reg(new SoundFX()); reg(new EnableSound()); reg(new ClickSound());
        reg(new HitSound()); reg(new KillSound());
    }
    private void reg(Module m) { modules.add(m); byClass.put(m.getClass(), m); }
    public List<Module> all() { return modules; }
    public List<Module> byCategory(Category c) {
        List<Module> out = new ArrayList<>();
        for (Module m : modules) if (m.category == c) out.add(m);
        return out;
    }
    @SuppressWarnings("unchecked")
    public <T extends Module> T get(Class<T> c) { return (T) byClass.get(c); }

    public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        for (Module m : modules) if (m.isEnabled()) m.onTick();

        Trail trail = get(Trail.class);
        if (trail != null && trail.isEnabled()) {
            if (trail.self.get()) trail.push(mc.player.getUuid(), mc.player.getPos());
            if (trail.players.get())
                for (var p : mc.world.getPlayers()) if (p != mc.player) trail.push(p.getUuid(), p.getPos());
        }
        KillSound kill = get(KillSound.class);
        if (kill != null && kill.isEnabled()) {
            for (var e : mc.world.getEntities()) {
                if (!(e instanceof net.minecraft.entity.LivingEntity le)) continue;
                if (le.isAlive()) killTracked.add(le.getId());
                else if (killTracked.remove(le.getId())) kill.onKill(le);
            }
        }
    }
    public void onKey(int key) {
        if (key == 344) {
            var es = get(EnableSound.class);
            if (es != null && es.isEnabled())
                dev.archive.hackclient.sound.SoundManager.play(
                    dev.archive.hackclient.sound.Tone.GUI_OPEN,
                    dev.archive.hackclient.sound.Synth.SR);
            MinecraftClient.getInstance().setScreen(dev.archive.hackclient.gui.ClickGui.INSTANCE);
            return;
        }
        for (Module m : modules) if (m.keybind == key) m.toggle();
    }
}
EOF

# ---------- settings ----------
cat > "$B/setting/Setting.java" <<'EOF'
package dev.archive.hackclient.setting;

public abstract class Setting<T> {
    public final String name;
    protected T value;
    public Setting(String name, T value) { this.name = name; this.value = value; }
    public T get() { return value; }
    public void set(T v) { this.value = v; }
    public abstract String display();
}
EOF
cat > "$B/setting/BooleanSetting.java" <<'EOF'
package dev.archive.hackclient.setting;

public class BooleanSetting extends Setting<Boolean> {
    public BooleanSetting(String name, boolean value) { super(name, value); }
    public boolean get() { return value; }
    public void toggle() { value = !value; }
    @Override public String display() { return value ? "on" : "off"; }
}
EOF
cat > "$B/setting/NumberSetting.java" <<'EOF'
package dev.archive.hackclient.setting;

public class NumberSetting extends Setting<Double> {
    public final double min, max, step;
    public NumberSetting(String name, double value, double min, double max, double step) {
        super(name, value); this.min = min; this.max = max; this.step = step;
    }
    public double get() { return value; }
    public float getFloat() { return value.floatValue(); }
    public int getInt() { return (int) Math.round(value); }
    public void set(double v) { this.value = Math.max(min, Math.min(max, v)); }
    @Override public String display() { return String.format("%.2f", value); }
}
EOF
cat > "$B/setting/ModeSetting.java" <<'EOF'
package dev.archive.hackclient.setting;

import java.util.List;
public class ModeSetting extends Setting<String> {
    public final List<String> modes;
    public ModeSetting(String name, String value, String... modes) {
        super(name, value); this.modes = List.of(modes);
    }
    public void cycle() {
        int i = modes.indexOf(value);
        value = modes.get((i + 1) % modes.size());
    }
    public boolean is(String m) { return value.equalsIgnoreCase(m); }
    @Override public String display() { return value; }
}
EOF

# ---------- util ----------
cat > "$B/util/RotationUtil.java" <<'EOF'
package dev.archive.hackclient.util;

import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.Entity;
import net.minecraft.util.math.MathHelper;
import net.minecraft.util.math.Vec3d;

public final class RotationUtil {
    public static float[] lookAt(Vec3d from, Vec3d to) {
        double dx = to.x - from.x, dy = to.y - from.y, dz = to.z - from.z;
        double dist = Math.sqrt(dx * dx + dz * dz);
        float yaw = (float)(Math.toDegrees(Math.atan2(dz, dx)) - 90.0);
        float pitch = (float)(-Math.toDegrees(Math.atan2(dy, dist)));
        return new float[]{ yaw, pitch };
    }
    public static float[] lookAt(Entity target) {
        MinecraftClient mc = MinecraftClient.getInstance();
        Vec3d eyes = mc.player.getEyePos();
        Vec3d t = new Vec3d(target.getX(), target.getY() + target.getHeight() * 0.5, target.getZ());
        return lookAt(eyes, t);
    }
    public static void apply(MinecraftClient mc, float yaw, float pitch, float speed) {
        float dy = MathHelper.wrapDegrees(yaw - mc.player.getYaw());
        float dp = MathHelper.wrapDegrees(pitch - mc.player.getPitch());
        float cy = Math.min(Math.abs(dy), speed) * Math.signum(dy);
        float cp = Math.min(Math.abs(dp), speed) * Math.signum(dp);
        mc.player.setYaw(mc.player.getYaw() + cy);
        mc.player.setPitch(MathHelper.clamp(mc.player.getPitch() + cp, -90f, 90f));
    }
    public static void snap(MinecraftClient mc, float yaw, float pitch) {
        mc.player.setYaw(yaw);
        mc.player.setPitch(MathHelper.clamp(pitch, -90f, 90f));
    }
}
EOF
cat > "$B/util/PacketUtil.java" <<'EOF'
package dev.archive.hackclient.util;

import net.minecraft.client.MinecraftClient;
import net.minecraft.network.packet.Packet;

public final class PacketUtil {
    public static void send(Packet<?> packet) {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.getNetworkHandler() != null) mc.getNetworkHandler().sendPacket(packet);
    }
}
EOF
cat > "$B/util/RenderUtil.java" <<'EOF'
package dev.archive.hackclient.util;

import net.minecraft.client.MinecraftClient;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.render.*;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.util.math.Box;
import net.minecraft.util.math.Vec3d;

public final class RenderUtil {
    public static void boxOutline(MatrixStack ms, Box box, Vec3d cam, float r, float g, float b, float a) {
        VertexConsumer buf = MinecraftClient.getInstance().getBufferBuilders()
            .getEntityVertexConsumers().getBuffer(RenderLayer.getLines());
        WorldRenderer.drawBox(ms, buf, box.offset(-cam.x, -cam.y, -cam.z), r, g, b, a);
    }
    public static void glassRect(DrawContext ctx, int x, int y, int w, int h, int bg, int border) {
        ctx.fill(x, y, x + w, y + h, bg);
        ctx.fill(x, y, x + w, y + 1, border);
        ctx.fill(x, y + h - 1, x + w, y + h, border);
        ctx.fill(x, y, x + 1, y + h, border);
        ctx.fill(x + w - 1, y, x + w, y + h, border);
    }
}
EOF
cat > "$B/util/ColorUtil.java" <<'EOF'
package dev.archive.hackclient.util;

import java.awt.Color;
public final class ColorUtil {
    public static int argb(int a, int r, int g, int b) { return (a << 24) | (r << 16) | (g << 8) | b; }
    public static int hsb(float hue, float sat, float bri, float alpha) {
        int rgb = Color.HSBtoRGB(hue, sat, bri);
        return ((int)(alpha * 255) << 24) | (rgb & 0xFFFFFF);
    }
    public static int rainbow(float speed, float alpha) {
        float hue = (System.currentTimeMillis() % (long)(1000 / speed)) / (float)(1000 / speed);
        return hsb(hue, 0.8f, 1.0f, alpha);
    }
}
EOF
cat > "$B/util/BlockUtil.java" <<'EOF'
package dev.archive.hackclient.util;

import net.minecraft.block.BlockState;
import net.minecraft.block.Blocks;
import net.minecraft.client.MinecraftClient;
import net.minecraft.item.BlockItem;
import net.minecraft.util.Hand;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.Vec3d;

public final class BlockUtil {
    public static boolean isAir(BlockPos p) { return MinecraftClient.getInstance().world.getBlockState(p).isAir(); }
    public static boolean isReplaceable(BlockPos p) {
        BlockState s = MinecraftClient.getInstance().world.getBlockState(p);
        return s.isReplaceable() && !s.isOf(Blocks.BEDROCK);
    }
    public static int findBlockSlot() {
        MinecraftClient mc = MinecraftClient.getInstance();
        for (int i = 0; i < 9; i++) if (mc.player.getInventory().getStack(i).getItem() instanceof BlockItem) return i;
        return -1;
    }
    public static boolean place(BlockPos pos, Direction side, Vec3d hitVec) {
        MinecraftClient mc = MinecraftClient.getInstance();
        int slot = findBlockSlot();
        if (slot == -1) return false;
        int prev = mc.player.getInventory().selectedSlot;
        mc.player.getInventory().selectedSlot = slot;
        mc.interactionManager.interactBlock(mc.player, Hand.MAIN_HAND,
            new BlockHitResult(hitVec, side, pos, false));
        mc.player.swingHand(Hand.MAIN_HAND);
        mc.player.getInventory().selectedSlot = prev;
        return true;
    }
}
EOF
cat > "$B/util/CrystalUtil.java" <<'EOF'
package dev.archive.hackclient.util;

import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.decoration.EndCrystalEntity;
import net.minecraft.item.Items;
import net.minecraft.util.Hand;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Box;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.Vec3d;

public final class CrystalUtil {
    public static int crystalSlot() {
        MinecraftClient mc = MinecraftClient.getInstance();
        for (int i = 0; i < 9; i++) if (mc.player.getInventory().getStack(i).getItem() == Items.END_CRYSTAL) return i;
        return -1;
    }
    public static boolean placeCrystal(BlockPos base) {
        MinecraftClient mc = MinecraftClient.getInstance();
        int slot = crystalSlot();
        if (slot == -1) return false;
        BlockPos above = base.up();
        if (!mc.world.getBlockState(above).isAir()) return false;
        int prev = mc.player.getInventory().selectedSlot;
        mc.player.getInventory().selectedSlot = slot;
        mc.interactionManager.interactBlock(mc.player, Hand.MAIN_HAND,
            new BlockHitResult(new Vec3d(above.getX() + 0.5, above.getY(), above.getZ() + 0.5),
                Direction.UP, base, false));
        mc.player.swingHand(Hand.MAIN_HAND);
        mc.player.getInventory().selectedSlot = prev;
        return true;
    }
    public static EndCrystalEntity findCrystal(BlockPos base, double range) {
        MinecraftClient mc = MinecraftClient.getInstance();
        Box box = new Box(base.up()).expand(range);
        return mc.world.getEntitiesByClass(EndCrystalEntity.class, box, e -> true)
            .stream().findFirst().orElse(null);
    }
    public static boolean breakCrystal(EndCrystalEntity c) {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player.distanceTo(c) > 6.0) return false;
        mc.interactionManager.attackEntity(mc.player, c);
        mc.player.swingHand(Hand.MAIN_HAND);
        return true;
    }
}
EOF
cat > "$B/util/DamageCalc.java" <<'EOF'
package dev.archive.hackclient.util;

import net.minecraft.entity.LivingEntity;
import net.minecraft.item.ArmorItem;
import net.minecraft.item.ItemStack;
import net.minecraft.util.math.Vec3d;

public final class DamageCalc {
    private static final double CRYSTAL_POWER = 12.0;
    public static float crystalDamage(LivingEntity target, Vec3d crystalPos) {
        double dist = Math.sqrt(target.squaredDistanceTo(crystalPos));
        double exposure = 1.0 - Math.min(1.0, dist / 12.0);
        double raw = CRYSTAL_POWER * exposure * exposure;
        return applyReductions(target, (float) raw);
    }
    public static float applyReductions(LivingEntity target, float dmg) {
        float armor = 0f, toughness = 0f;
        for (ItemStack s : target.getArmorItems())
            if (s.getItem() instanceof ArmorItem a) { armor += a.getProtection(); toughness += a.getToughness(); }
        float f = 2f + toughness / 4f;
        float g = Math.min(20f, Math.max(armor / 5f, armor - dmg / f));
        dmg *= (1f - g / 25f);
        return Math.max(dmg, 0f);
    }
    public static float selfDamage(Vec3d pos) {
        return crystalDamage(net.minecraft.client.MinecraftClient.getInstance().player, pos);
    }
}
EOF
cat > "$B/util/InventoryUtil.java" <<'EOF'
package dev.archive.hackclient.util;

import net.minecraft.client.MinecraftClient;
import net.minecraft.item.Item;
import net.minecraft.screen.slot.SlotActionType;

public final class InventoryUtil {
    public static int findSlot(Item item) {
        MinecraftClient mc = MinecraftClient.getInstance();
        for (int i = 0; i < 36; i++) if (mc.player.getInventory().getStack(i).getItem() == item) return i;
        return -1;
    }
    public static int findSlotHotbar(Item item) {
        MinecraftClient mc = MinecraftClient.getInstance();
        for (int i = 0; i < 9; i++) if (mc.player.getInventory().getStack(i).getItem() == item) return i;
        return -1;
    }
    public static void moveToHotbar(int invSlot, int hotbarSlot) {
        MinecraftClient mc = MinecraftClient.getInstance();
        int src = invSlot < 9 ? invSlot + 36 : invSlot;
        mc.interactionManager.clickSlot(mc.player.playerScreenHandler.syncId, src, hotbarSlot, SlotActionType.SWAP, mc.player);
    }
    public static void swapToOffhand(int invSlot) {
        MinecraftClient mc = MinecraftClient.getInstance();
        int src = invSlot < 9 ? invSlot + 36 : invSlot;
        mc.interactionManager.clickSlot(mc.player.playerScreenHandler.syncId, src, 40, SlotActionType.SWAP, mc.player);
    }
}
EOF

# ---------- gui ----------
cat > "$B/gui/ClickGui.java" <<'EOF'
package dev.archive.hackclient.gui;

import dev.archive.hackclient.module.Category;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.gui.screen.Screen;
import net.minecraft.text.Text;

public class ClickGui extends Screen {
    public static final ClickGui INSTANCE = new ClickGui();
    private final GlassPanel[] panels = new GlassPanel[Category.values().length];
    private int dragX, dragY;
    private GlassPanel dragging;

    public ClickGui() { super(Text.literal("HackClient")); }

    @Override
    protected void init() {
        int x = 20;
        for (Category c : Category.values()) {
            panels[c.ordinal()] = new GlassPanel(c, x, 40);
            x += 130;
        }
    }
    @Override
    public void render(DrawContext ctx, int mx, int my, float delta) {
        ctx.fill(0, 0, width, height, 0x66000000);
        for (GlassPanel p : panels) if (p != null) p.render(ctx, mx, my, textRenderer);
        super.render(ctx, mx, my, delta);
    }
    @Override
    public boolean mouseClicked(double mx, double my, int button) {
        for (GlassPanel p : panels) {
            if (p == null) continue;
            if (p.mouseClicked(mx, my, button)) {
                if (button == 0 && p.isHeaderHit(mx, my)) { dragging = p; dragX = (int)mx - p.x; dragY = (int)my - p.y; }
                return true;
            }
        }
        return super.mouseClicked(mx, my, button);
    }
    @Override
    public boolean mouseDragged(double mx, double my, int button, double dx, double dy) {
        if (dragging != null) { dragging.x = (int)mx - dragX; dragging.y = (int)my - dragY; return true; }
        return super.mouseDragged(mx, my, button, dx, dy);
    }
    @Override
    public boolean mouseReleased(double mx, double my, int button) {
        dragging = null;
        return super.mouseReleased(mx, my, button);
    }
    @Override
    public boolean shouldPause() { return false; }
}
EOF
cat > "$B/gui/GlassPanel.java" <<'EOF'
package dev.archive.hackclient.gui;

import dev.archive.hackclient.HackClient;
import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.util.RenderUtil;
import net.minecraft.client.font.TextRenderer;
import net.minecraft.client.gui.DrawContext;
import java.util.List;

public class GlassPanel {
    public final Category category;
    public int x, y;
    public final int width = 120;
    private final int headerH = 18;
    private final int rowH = 14;

    public GlassPanel(Category c, int x, int y) { this.category = c; this.x = x; this.y = y; }
    public List<Module> modules() { return HackClient.MODULES.byCategory(category); }
    public void render(DrawContext ctx, int mx, int my, TextRenderer tr) {
        List<Module> mods = modules();
        int h = headerH + mods.size() * rowH + 4;
        RenderUtil.glassRect(ctx, x, y, width, h, 0x88202A33, 0x66FFFFFF);
        ctx.fill(x + 1, y + 1, x + width - 1, y + headerH, 0x55FFFFFF);
        ctx.drawText(tr, category.name(), x + 6, y + 5, 0xFFFFFFFF, true);
        int cy = y + headerH + 2;
        for (Module m : mods) {
            boolean hover = mx >= x && mx <= x + width && my >= cy && my <= cy + rowH;
            int bg = m.isEnabled() ? 0x55A0D8FF : (hover ? 0x44FFFFFF : 0x00000000);
            if (bg != 0) ctx.fill(x + 1, cy, x + width - 1, cy + rowH, bg);
            int col = m.isEnabled() ? 0xFFA0D8FF : 0xFFE0E0E0;
            ctx.drawText(tr, m.name, x + 6, cy + 3, col, true);
            cy += rowH;
        }
    }
    public boolean isHeaderHit(double mx, double my) {
        return mx >= x && mx <= x + width && my >= y && my <= y + headerH;
    }
    public boolean mouseClicked(double mx, double my, int button) {
        if (mx < x || mx > x + width) return false;
        int cy = y + headerH + 2;
        for (Module m : modules()) {
            if (my >= cy && my <= cy + rowH) {
                if (button == 0) m.toggle();
                else if (button == 1) m.setEnabled(false);
                try {
                    var cs = HackClient.MODULES.get(dev.archive.hackclient.module.impl.sound.ClickSound.class);
                    if (cs != null && cs.isEnabled())
                        dev.archive.hackclient.sound.SoundManager.play(
                            dev.archive.hackclient.sound.Tone.CLICK,
                            dev.archive.hackclient.sound.Synth.SR);
                } catch (Throwable ignored) {}
                return true;
            }
            cy += rowH;
        }
        return my >= y && my <= y + headerH;
    }
}
EOF
cat > "$B/gui/GlassButton.java" <<'EOF'
package dev.archive.hackclient.gui;

import dev.archive.hackclient.util.RenderUtil;
import net.minecraft.client.font.TextRenderer;
import net.minecraft.client.gui.DrawContext;

public class GlassButton {
    public int x, y, w, h;
    public String label;
    public boolean toggled;
    public GlassButton(int x, int y, int w, int h, String label) {
        this.x = x; this.y = y; this.w = w; this.h = h; this.label = label;
    }
    public void render(DrawContext ctx, int mx, int my, TextRenderer tr) {
        boolean hover = mx >= x && mx <= x + w && my >= y && my <= y + h;
        int bg = toggled ? 0x66A0D8FF : (hover ? 0x44FFFFFF : 0x22FFFFFF);
        RenderUtil.glassRect(ctx, x, y, w, h, bg, 0x66FFFFFF);
        ctx.drawText(tr, label, x + 4, y + (h - 8) / 2, 0xFFFFFFFF, true);
    }
    public boolean hit(double mx, double my) {
        return mx >= x && mx <= x + w && my >= y && my <= y + h;
    }
}
EOF

# ---------- sound base ----------
cat > "$B/sound/SoundManager.java" <<'EOF'
package dev.archive.hackclient.sound;

import javax.sound.sampled.*;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public final class SoundManager {
    private static final ExecutorService POOL = Executors.newFixedThreadPool(2, r -> {
        Thread t = new Thread(r, "hackclient-sound");
        t.setDaemon(true);
        return t;
    });
    private static float volume = 0.6f;
    public static void setVolume(float v) { volume = Math.max(0f, Math.min(1f, v)); }
    public static float getVolume() { return volume; }
    public static void play(float[] samples, float sampleRate) {
        if (samples == null || samples.length == 0) return;
        POOL.submit(() -> {
            try {
                byte[] pcm = new byte[samples.length * 2];
                for (int i = 0; i < samples.length; i++) {
                    short s = (short)(Math.max(-1f, Math.min(1f, samples[i] * volume)) * Short.MAX_VALUE);
                    pcm[i * 2] = (byte)(s & 0xFF);
                    pcm[i * 2 + 1] = (byte)((s >> 8) & 0xFF);
                }
                AudioFormat fmt = new AudioFormat(sampleRate, 16, 1, true, false);
                DataLine.Info info = new DataLine.Info(SourceDataLine.class, fmt);
                SourceDataLine line = (SourceDataLine) AudioSystem.getLine(info);
                line.open(fmt, pcm.length);
                line.start();
                line.write(pcm, 0, pcm.length);
                line.drain();
                line.close();
            } catch (Exception ignored) {}
        });
    }
}
EOF
cat > "$B/sound/Synth.java" <<'EOF'
package dev.archive.hackclient.sound;

public final class Synth {
    public static final float SR = 44100f;
    public static float[] sine(float freq, float durSec, float amp) {
        int n = (int)(SR * durSec);
        float[] out = new float[n];
        for (int i = 0; i < n; i++) {
            float t = i / SR;
            out[i] = (float) Math.sin(2 * Math.PI * freq * t) * amp * envelope(i, n, 0.005f, 0.05f);
        }
        return out;
    }
    public static float[] sweep(float f0, float f1, float durSec, float amp, boolean exp) {
        int n = (int)(SR * durSec);
        float[] out = new float[n];
        double phase = 0;
        for (int i = 0; i < n; i++) {
            float t = i / (float) n;
            float f = exp ? (float)(f0 * Math.pow(f1 / f0, t)) : f0 + (f1 - f0) * t;
            phase += 2 * Math.PI * f / SR;
            out[i] = (float) Math.sin(phase) * amp * envelope(i, n, 0.003f, 0.08f);
        }
        return out;
    }
    public static float[] chord(float[] freqs, float durSec, float amp) {
        int n = (int)(SR * durSec);
        float[] out = new float[n];
        for (int i = 0; i < n; i++) {
            float t = i / SR;
            float s = 0;
            for (float f : freqs) s += (float) Math.sin(2 * Math.PI * f * t);
            out[i] = s / freqs.length * amp * envelope(i, n, 0.005f, 0.1f);
        }
        return out;
    }
    public static float[] click(float amp) {
        int n = (int)(SR * 0.02f);
        float[] out = new float[n];
        for (int i = 0; i < n; i++) {
            float t = i / SR;
            float env = (float) Math.exp(-t * 80);
            out[i] = (float)(Math.random() * 2 - 1) * amp * env * 0.5f
                   + (float) Math.sin(2 * Math.PI * 1800 * t) * amp * env * 0.5f;
        }
        return out;
    }
    private static float envelope(int i, int n, float attack, float release) {
        float t = i / SR;
        float total = n / SR;
        float a = Math.min(1f, t / attack);
        float r = Math.min(1f, (total - t) / release);
        return a * r;
    }
}
EOF
cat > "$B/sound/Tone.java" <<'EOF'
package dev.archive.hackclient.sound;

public final class Tone {
    public static final float[] MODULE_ON  = Synth.sweep(660f, 990f, 0.08f, 0.35f, true);
    public static final float[] MODULE_OFF = Synth.sweep(660f, 330f, 0.08f, 0.35f, true);
    public static final float[] CLICK      = Synth.click(0.4f);
    public static final float[] HIT        = Synth.chord(new float[]{880f, 1320f}, 0.05f, 0.35f);
    public static final float[] KILL       = Synth.chord(new float[]{523.25f, 659.25f, 783.99f}, 0.18f, 0.4f);
    public static final float[] GUI_OPEN   = Synth.sweep(440f, 1760f, 0.12f, 0.35f, true);
    public static final float[] PEARL      = Synth.sweep(1200f, 400f, 0.15f, 0.3f, true);
}
EOF

echo "[chunk1] done. Append chunks 2-4 with >> before running."