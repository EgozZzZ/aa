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
# =========================================================================
# CHUNK 2/4 — COMBAT + MOVEMENT
# =========================================================================
B=src/main/java/dev/archive/hackclient

# ---------- combat ----------
cat > "$B/module/impl/combat/KillAura.java" <<'EOF'
package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.*;
import dev.archive.hackclient.util.RotationUtil;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.Entity;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.util.Hand;
import java.util.Comparator;

public class KillAura extends Module {
    private final NumberSetting range = add(new NumberSetting("Range", 3.0, 1.0, 6.0, 0.1));
    private final NumberSetting cps = add(new NumberSetting("CPS", 12.0, 1.0, 20.0, 1.0));
    private final NumberSetting rotSpeed = add(new NumberSetting("RotSpeed", 40.0, 5.0, 180.0, 1.0));
    private final BooleanSetting players = add(new BooleanSetting("Players", true));
    private final BooleanSetting mobs = add(new BooleanSetting("Mobs", false));
    private final BooleanSetting throughWalls = add(new BooleanSetting("ThroughWalls", false));
    private final ModeSetting sort = add(new ModeSetting("Sort", "Distance", "Distance", "Health", "Angle"));
    private final BooleanSetting silent = add(new BooleanSetting("Silent", true));

    private long lastAttack;
    private Entity target;

    public KillAura() { super("KillAura", "Auto-attacks nearby entities", Category.COMBAT); }

    @Override
    public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        target = pick(mc);
        if (target == null) return;
        float[] rot = RotationUtil.lookAt(target);
        if (silent.get()) RotationUtil.apply(mc, rot[0], rot[1], rotSpeed.getFloat());
        else RotationUtil.snap(mc, rot[0], rot[1]);
        long now = System.currentTimeMillis();
        long delay = (long)(1000.0 / cps.get());
        if (now - lastAttack >= delay) {
            mc.interactionManager.attackEntity(mc.player, target);
            mc.player.swingHand(Hand.MAIN_HAND);
            lastAttack = now;
        }
    }
    private Entity pick(MinecraftClient mc) {
        return mc.world.getEntitiesByClass(LivingEntity.class,
                mc.player.getBoundingBox().expand(range.get()),
                e -> e != mc.player && e.isAlive() && filter(e))
            .stream()
            .filter(e -> throughWalls.get() || mc.player.canSee(e))
            .min(comparator(mc)).orElse(null);
    }
    private boolean filter(Entity e) {
        if (e instanceof PlayerEntity) return players.get();
        return mobs.get();
    }
    private Comparator<Entity> comparator(MinecraftClient mc) {
        return switch (sort.get()) {
            case "Health" -> Comparator.comparingDouble(e -> ((LivingEntity)e).getHealth());
            case "Angle" -> Comparator.comparingDouble(e -> {
                float[] r = RotationUtil.lookAt(e);
                return Math.abs(net.minecraft.util.math.MathHelper.wrapDegrees(r[0] - mc.player.getYaw()));
            });
            default -> Comparator.comparingDouble(e -> e.distanceTo(mc.player));
        };
    }
}
EOF

cat > "$B/module/impl/combat/Criticals.java" <<'EOF'
package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.ModeSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.Entity;
import net.minecraft.entity.LivingEntity;
import net.minecraft.network.packet.c2s.play.PlayerMoveC2SPacket;

public class Criticals extends Module {
    private final ModeSetting mode = add(new ModeSetting("Mode", "Packet", "Packet", "Jump", "MiniJump"));
    public Criticals() { super("Criticals", "Always land critical hits", Category.COMBAT); }
    public void doCrit(Entity target) {
        if (!isEnabled() || !(target instanceof LivingEntity)) return;
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.getNetworkHandler() == null) return;
        if (mc.player.isOnGround() && !mc.player.isInLava() && !mc.player.isSubmergedInWater()) {
            switch (mode.get()) {
                case "Packet" -> {
                    double x = mc.player.getX(), y = mc.player.getY(), z = mc.player.getZ();
                    mc.getNetworkHandler().sendPacket(new PlayerMoveC2SPacket.PositionAndOnGround(x, y + 0.0625, z, false, mc.player.horizontalCollision));
                    mc.getNetworkHandler().sendPacket(new PlayerMoveC2SPacket.PositionAndOnGround(x, y, z, false, mc.player.horizontalCollision));
                }
                case "Jump" -> mc.player.jump();
                case "MiniJump" -> mc.player.setVelocity(mc.player.getVelocity().x, 0.1, mc.player.getVelocity().z);
            }
        }
    }
}
EOF

cat > "$B/module/impl/combat/AutoTotem.java" <<'EOF'
package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.item.Items;
import net.minecraft.screen.slot.SlotActionType;

public class AutoTotem extends Module {
    private final NumberSetting delay = add(new NumberSetting("Delay", 2.0, 0.0, 20.0, 1.0));
    private long last;
    public AutoTotem() { super("AutoTotem", "Refills offhand with totems", Category.COMBAT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (mc.player.getOffHandStack().getItem() == Items.TOTEM_OF_UNDYING) return;
        if (System.currentTimeMillis() - last < delay.get() * 50.0) return;
        for (int i = 0; i < 36; i++) {
            if (mc.player.getInventory().getStack(i).getItem() == Items.TOTEM_OF_UNDYING) {
                int slot = i < 9 ? i + 36 : i;
                mc.interactionManager.clickSlot(mc.player.playerScreenHandler.syncId, slot, 0, SlotActionType.PICKUP, mc.player);
                mc.interactionManager.clickSlot(mc.player.playerScreenHandler.syncId, 45, 0, SlotActionType.PICKUP, mc.player);
                mc.interactionManager.clickSlot(mc.player.playerScreenHandler.syncId, slot, 0, SlotActionType.PICKUP, mc.player);
                last = System.currentTimeMillis();
                return;
            }
        }
    }
}
EOF

cat > "$B/module/impl/combat/Velocity.java" <<'EOF'
package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;

public class Velocity extends Module {
    public final NumberSetting horizontal = add(new NumberSetting("Horizontal", 0.0, 0.0, 100.0, 1.0));
    public final NumberSetting vertical = add(new NumberSetting("Vertical", 0.0, 0.0, 100.0, 1.0));
    public Velocity() { super("Velocity", "Reduce knockback", Category.COMBAT); }
}
EOF

cat > "$B/module/impl/combat/CrystalAura.java" <<'EOF'
package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.*;
import dev.archive.hackclient.util.*;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.decoration.EndCrystalEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Vec3d;
import java.util.Comparator;

public class CrystalAura extends Module {
    private final NumberSetting placeRange = add(new NumberSetting("PlaceRange", 4.5, 1.0, 6.0, 0.1));
    private final NumberSetting breakRange = add(new NumberSetting("BreakRange", 4.5, 1.0, 6.0, 0.1));
    private final NumberSetting targetRange = add(new NumberSetting("TargetRange", 10.0, 3.0, 16.0, 0.5));
    private final NumberSetting placeDelay = add(new NumberSetting("PlaceDelay", 50.0, 0.0, 500.0, 10.0));
    private final NumberSetting breakDelay = add(new NumberSetting("BreakDelay", 50.0, 0.0, 500.0, 10.0));
    private final NumberSetting minDamage = add(new NumberSetting("MinDamage", 6.0, 0.0, 20.0, 0.5));
    private final NumberSetting maxSelfDamage = add(new NumberSetting("MaxSelfDamage", 8.0, 0.0, 20.0, 0.5));
    private final BooleanSetting antiSuicide = add(new BooleanSetting("AntiSuicide", true));
    private final BooleanSetting rotate = add(new BooleanSetting("Rotate", true));
    private final BooleanSetting autoSwitch = add(new BooleanSetting("AutoSwitch", true));
    private final BooleanSetting autoObsidian = add(new BooleanSetting("AutoObsidian", true));
    private final NumberSetting obsidianRange = add(new NumberSetting("ObsidianRange", 4.5, 1.0, 6.0, 0.1));
    private final ModeSetting targetSort = add(new ModeSetting("TargetSort", "Damage", "Damage", "Distance", "Health"));

    private long lastPlace, lastBreak;
    private LivingEntity target;

    public CrystalAura() { super("CrystalAura", "End crystal PvP", Category.COMBAT); }

    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        target = selectTarget(mc);
        if (target == null) return;

        if (autoObsidian.get()) {
            boolean hasBase = false;
            for (int dx = -2; dx <= 2; dx++)
            for (int dz = -2; dz <= 2; dz++) {
                BlockPos b = target.getBlockPos().add(dx, 0, dz);
                if (mc.world.getBlockState(b).isOf(net.minecraft.block.Blocks.OBSIDIAN)
                    && mc.world.getBlockState(b.up()).isAir()) { hasBase = true; break; }
            }
            if (!hasBase) {
                BlockPos spot = findObsidianSpot(mc, target);
                if (spot != null) {
                    int obsSlot = -1;
                    for (int i = 0; i < 9; i++)
                        if (mc.player.getInventory().getStack(i).getItem() == net.minecraft.item.Items.OBSIDIAN) { obsSlot = i; break; }
                    if (obsSlot != -1) {
                        int prev = mc.player.getInventory().selectedSlot;
                        mc.player.getInventory().selectedSlot = obsSlot;
                        BlockUtil.place(spot, net.minecraft.util.math.Direction.UP,
                            Vec3d.ofCenter(spot.down()).add(0, 0.5, 0));
                        mc.player.getInventory().selectedSlot = prev;
                    }
                }
            }
        }

        if (System.currentTimeMillis() - lastBreak >= breakDelay.get()) {
            EndCrystalEntity c = findBestCrystal(mc);
            if (c != null) {
                if (rotate.get()) {
                    float[] r = RotationUtil.lookAt(c);
                    RotationUtil.apply(mc, r[0], r[1], 60f);
                }
                if (CrystalUtil.breakCrystal(c)) lastBreak = System.currentTimeMillis();
            }
        }

        if (System.currentTimeMillis() - lastPlace >= placeDelay.get()) {
            BlockPos base = findBestBase(mc);
            if (base != null) {
                if (rotate.get()) {
                    float[] r = RotationUtil.lookAt(mc.player.getEyePos(),
                        new Vec3d(base.getX() + 0.5, base.getY() + 1.0, base.getZ() + 0.5));
                    RotationUtil.apply(mc, r[0], r[1], 60f);
                }
                if (CrystalUtil.placeCrystal(base)) lastPlace = System.currentTimeMillis();
            }
        }
    }
    private LivingEntity selectTarget(MinecraftClient mc) {
        return mc.world.getEntitiesByClass(LivingEntity.class,
                mc.player.getBoundingBox().expand(targetRange.get()),
                e -> e != mc.player && e.isAlive() && e instanceof PlayerEntity)
            .stream().min(targetComparator(mc)).orElse(null);
    }
    private Comparator<LivingEntity> targetComparator(MinecraftClient mc) {
        return switch (targetSort.get()) {
            case "Health" -> Comparator.comparingDouble(LivingEntity::getHealth);
            case "Distance" -> Comparator.comparingDouble(e -> e.distanceTo(mc.player));
            default -> Comparator.comparingDouble(e -> -DamageCalc.crystalDamage(e, e.getPos().add(0, 0.5, 0)));
        };
    }
    private BlockPos findObsidianSpot(MinecraftClient mc, LivingEntity target) {
        BlockPos tPos = target.getBlockPos();
        if (mc.world.getBlockState(tPos).isAir()
            && mc.world.getBlockState(tPos.down()).isSolidBlock(mc.world, tPos.down())) {
            if (mc.player.squaredDistanceTo(Vec3d.ofCenter(tPos)) <= obsidianRange.get() * obsidianRange.get())
                return tPos;
        }
        for (net.minecraft.util.math.Direction d : new net.minecraft.util.math.Direction[]{
                net.minecraft.util.math.Direction.NORTH, net.minecraft.util.math.Direction.SOUTH,
                net.minecraft.util.math.Direction.EAST, net.minecraft.util.math.Direction.WEST}) {
            BlockPos p = tPos.offset(d);
            if (!mc.world.getBlockState(p).isAir()) continue;
            if (!mc.world.getBlockState(p.down()).isSolidBlock(mc.world, p.down())) continue;
            if (mc.player.squaredDistanceTo(Vec3d.ofCenter(p)) > obsidianRange.get() * obsidianRange.get()) continue;
            return p;
        }
        return null;
    }
    private BlockPos findBestBase(MinecraftClient mc) {
        BlockPos playerPos = mc.player.getBlockPos();
        BlockPos best = null;
        double bestScore = -Double.MAX_VALUE;
        int r = (int) Math.ceil(placeRange.get());
        for (int dx = -r; dx <= r; dx++)
        for (int dy = -2; dy <= 2; dy++)
        for (int dz = -r; dz <= r; dz++) {
            BlockPos p = playerPos.add(dx, dy, dz);
            if (!mc.world.getBlockState(p).isOf(net.minecraft.block.Blocks.OBSIDIAN)
             && !mc.world.getBlockState(p).isOf(net.minecraft.block.Blocks.BEDROCK)) continue;
            if (!mc.world.getBlockState(p.up()).isAir()) continue;
            if (!mc.world.getBlockState(p.up(2)).isAir()) continue;
            if (mc.player.squaredDistanceTo(Vec3d.ofCenter(p)) > placeRange.get() * placeRange.get()) continue;
            Vec3d crystal = new Vec3d(p.getX() + 0.5, p.getY() + 1.0, p.getZ() + 0.5);
            float dmg = DamageCalc.crystalDamage(target, crystal);
            float self = DamageCalc.selfDamage(crystal);
            if (dmg < minDamage.get()) continue;
            if (self > maxSelfDamage.get()) continue;
            if (antiSuicide.get() && self >= mc.player.getHealth() - 1f) continue;
            double score = dmg - self * 0.5;
            if (score > bestScore) { bestScore = score; best = p; }
        }
        return best;
    }
    private EndCrystalEntity findBestCrystal(MinecraftClient mc) {
        return mc.world.getEntitiesByClass(EndCrystalEntity.class,
                mc.player.getBoundingBox().expand(breakRange.get()), e -> true)
            .stream().min(Comparator.comparingDouble(e -> {
                float dmg = DamageCalc.crystalDamage(target, e.getPos());
                float self = DamageCalc.crystalDamage(mc.player, e.getPos());
                if (self > maxSelfDamage.get()) return Double.MAX_VALUE;
                return -(dmg - self * 0.5);
            })).orElse(null);
    }
}
EOF

cat > "$B/module/impl/combat/BedAura.java" <<'EOF'
package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.*;
import dev.archive.hackclient.util.InventoryUtil;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.item.Items;
import net.minecraft.util.Hand;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.Vec3d;
import java.util.Comparator;

public class BedAura extends Module {
    private final NumberSetting range = add(new NumberSetting("Range", 4.5, 1.0, 6.0, 0.1));
    private final NumberSetting delay = add(new NumberSetting("Delay", 100.0, 0.0, 500.0, 10.0));
    private final NumberSetting minDamage = add(new NumberSetting("MinDamage", 6.0, 0.0, 20.0, 0.5));
    private final NumberSetting maxSelfDamage = add(new NumberSetting("MaxSelfDamage", 10.0, 0.0, 20.0, 0.5));
    private long last;

    public BedAura() { super("BedAura", "Auto bed bombing", Category.COMBAT); }

    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        if (mc.world.getRegistryKey().getValue().getPath().equals("overworld")) return;
        if (System.currentTimeMillis() - last < delay.get()) return;
        LivingEntity target = mc.world.getEntitiesByClass(LivingEntity.class,
                mc.player.getBoundingBox().expand(range.get()),
                e -> e != mc.player && e.isAlive() && e instanceof PlayerEntity)
            .stream().min(Comparator.comparingDouble(e -> e.distanceTo(mc.player))).orElse(null);
        if (target == null) return;
        int bedSlot = InventoryUtil.findSlotHotbar(Items.RED_BED);
        if (bedSlot == -1) return;
        BlockPos tPos = target.getBlockPos();
        for (Direction d : Direction.values()) {
            if (d.getAxis().isVertical()) continue;
            BlockPos place = tPos.offset(d);
            BlockPos support = place.down();
            if (!mc.world.getBlockState(support).isSolidBlock(mc.world, support)) continue;
            if (!mc.world.getBlockState(place).isAir()) continue;
            if (mc.player.squaredDistanceTo(Vec3d.ofCenter(place)) > range.get() * range.get()) continue;
            int prev = mc.player.getInventory().selectedSlot;
            mc.player.getInventory().selectedSlot = bedSlot;
            mc.interactionManager.interactBlock(mc.player, Hand.MAIN_HAND,
                new BlockHitResult(Vec3d.ofCenter(support).add(0, 0.5, 0), Direction.UP, support, false));
            mc.player.swingHand(Hand.MAIN_HAND);
            mc.player.getInventory().selectedSlot = prev;
            mc.interactionManager.interactBlock(mc.player, Hand.MAIN_HAND,
                new BlockHitResult(Vec3d.ofCenter(place), Direction.UP, place, false));
            last = System.currentTimeMillis();
            return;
        }
    }
}
EOF

cat > "$B/module/impl/combat/Surround.java" <<'EOF'
package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.*;
import dev.archive.hackclient.util.BlockUtil;
import net.minecraft.client.MinecraftClient;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.Vec3d;

public class Surround extends Module {
    private final NumberSetting delay = add(new NumberSetting("Delay", 50.0, 0.0, 500.0, 10.0));
    private final BooleanSetting center = add(new BooleanSetting("Center", true));
    private long last;
    public Surround() { super("Surround", "Places obsidian around feet", Category.COMBAT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        if (System.currentTimeMillis() - last < delay.get()) return;
        BlockPos p = mc.player.getBlockPos();
        Direction[] dirs = { Direction.NORTH, Direction.SOUTH, Direction.EAST, Direction.WEST };
        for (Direction d : dirs) {
            BlockPos target = p.offset(d);
            if (!BlockUtil.isReplaceable(target)) continue;
            BlockPos support = target.down();
            if (!mc.world.getBlockState(support).isSolidBlock(mc.world, support)) {
                if (!BlockUtil.place(support, Direction.UP, Vec3d.ofCenter(support).add(0, 0.5, 0))) continue;
            }
            BlockUtil.place(target, d.getOpposite(),
                Vec3d.ofCenter(target).add(0.5 * d.getOpposite().getOffsetX(), 0.5, 0.5 * d.getOpposite().getOffsetZ()));
        }
        last = System.currentTimeMillis();
    }
}
EOF

cat > "$B/module/impl/combat/HoleFill.java" <<'EOF'
package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.*;
import dev.archive.hackclient.util.BlockUtil;
import net.minecraft.client.MinecraftClient;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.Vec3d;

public class HoleFill extends Module {
    private final NumberSetting range = add(new NumberSetting("Range", 4.0, 1.0, 6.0, 0.5));
    private final NumberSetting delay = add(new NumberSetting("Delay", 100.0, 0.0, 1000.0, 10.0));
    private long last;
    public HoleFill() { super("HoleFill", "Fills nearby holes", Category.COMBAT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        if (System.currentTimeMillis() - last < delay.get()) return;
        BlockPos center = mc.player.getBlockPos();
        int r = (int) Math.ceil(range.get());
        for (int dx = -r; dx <= r; dx++)
        for (int dy = -2; dy <= 2; dy++)
        for (int dz = -r; dz <= r; dz++) {
            BlockPos p = center.add(dx, dy, dz);
            if (!isHole(mc, p)) continue;
            if (mc.player.squaredDistanceTo(Vec3d.ofCenter(p)) > range.get() * range.get()) continue;
            if (BlockUtil.place(p, Direction.UP, Vec3d.ofCenter(p).add(0, 0.5, 0))) {
                last = System.currentTimeMillis();
                return;
            }
        }
    }
    private boolean isHole(MinecraftClient mc, BlockPos p) {
        if (!mc.world.getBlockState(p).isAir()) return false;
        if (!mc.world.getBlockState(p.up()).isAir()) return false;
        if (!mc.world.getBlockState(p.up(2)).isAir()) return false;
        for (Direction d : new Direction[]{Direction.NORTH, Direction.SOUTH, Direction.EAST, Direction.WEST, Direction.DOWN}) {
            BlockPos n = p.offset(d);
            var s = mc.world.getBlockState(n);
            if (!s.isSolidBlock(mc.world, n)) return false;
        }
        return true;
    }
}
EOF

cat > "$B/module/impl/combat/AutoArmor.java" <<'EOF'
package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.item.ArmorItem;
import net.minecraft.item.ItemStack;
import net.minecraft.screen.slot.SlotActionType;

public class AutoArmor extends Module {
    private final NumberSetting delay = add(new NumberSetting("Delay", 100.0, 0.0, 1000.0, 10.0));
    private long last;
    public AutoArmor() { super("AutoArmor", "Equips best armor", Category.COMBAT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (System.currentTimeMillis() - last < delay.get()) return;
        for (int i = 0; i < 36; i++) {
            ItemStack s = mc.player.getInventory().getStack(i);
            if (!(s.getItem() instanceof ArmorItem a)) continue;
            int armorSlot = a.getSlotType().getEntitySlotId();
            int invArmor = 36 + (3 - armorSlot);
            ItemStack cur = mc.player.getInventory().getStack(invArmor);
            if (cur.isEmpty() || score(s) > score(cur)) {
                int src = i < 9 ? i + 36 : i;
                mc.interactionManager.clickSlot(mc.player.playerScreenHandler.syncId, src, 0, SlotActionType.PICKUP, mc.player);
                mc.interactionManager.clickSlot(mc.player.playerScreenHandler.syncId, invArmor, 0, SlotActionType.PICKUP, mc.player);
                mc.interactionManager.clickSlot(mc.player.playerScreenHandler.syncId, src, 0, SlotActionType.PICKUP, mc.player);
                last = System.currentTimeMillis();
                return;
            }
        }
    }
    private float score(ItemStack s) {
        if (s.isEmpty()) return 0;
        if (!(s.getItem() instanceof ArmorItem a)) return 0;
        return a.getProtection() * 4f + a.getToughness();
    }
}
EOF

cat > "$B/module/impl/combat/AutoRegear.java" <<'EOF'
package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import dev.archive.hackclient.util.InventoryUtil;
import net.minecraft.client.MinecraftClient;
import net.minecraft.item.Items;

public class AutoRegear extends Module {
    private final NumberSetting delay = add(new NumberSetting("Delay", 200.0, 0.0, 1000.0, 10.0));
    private long last;
    public AutoRegear() { super("AutoRegear", "Refills hotbar from inventory", Category.COMBAT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (System.currentTimeMillis() - last < delay.get()) return;
        if (refill(mc, Items.END_CRYSTAL, 0)) return;
        if (refill(mc, Items.OBSIDIAN, 1)) return;
        if (refill(mc, Items.TOTEM_OF_UNDYING, 2)) return;
        if (refill(mc, Items.GOLDEN_APPLE, 3)) return;
        if (refill(mc, Items.EXPERIENCE_BOTTLE, 4)) return;
    }
    private boolean refill(MinecraftClient mc, net.minecraft.item.Item item, int hotbarSlot) {
        if (InventoryUtil.findSlotHotbar(item) != -1) return false;
        int src = InventoryUtil.findSlot(item);
        if (src == -1) return false;
        InventoryUtil.moveToHotbar(src, hotbarSlot);
        last = System.currentTimeMillis();
        return true;
    }
}
EOF

cat > "$B/module/impl/combat/AutoTrap.java" <<'EOF'
package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import dev.archive.hackclient.util.BlockUtil;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.Vec3d;
import java.util.Comparator;

public class AutoTrap extends Module {
    private final NumberSetting delay = add(new NumberSetting("Delay", 100.0, 0.0, 1000.0, 10.0));
    private long last;
    public AutoTrap() { super("AutoTrap", "Traps nearby players", Category.COMBAT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        if (System.currentTimeMillis() - last < delay.get()) return;
        PlayerEntity target = mc.world.getEntitiesByClass(PlayerEntity.class,
                mc.player.getBoundingBox().expand(5.0), e -> e != mc.player && e.isAlive())
            .stream().min(Comparator.comparingDouble(e -> e.distanceTo(mc.player))).orElse(null);
        if (target == null) return;
        BlockPos p = target.getBlockPos();
        for (Direction d : new Direction[]{Direction.NORTH, Direction.SOUTH, Direction.EAST, Direction.WEST}) {
            BlockPos b = p.offset(d);
            if (BlockUtil.isReplaceable(b))
                BlockUtil.place(b, d.getOpposite(), Vec3d.ofCenter(b).add(0.5 * d.getOpposite().getOffsetX(), 0.5, 0.5 * d.getOpposite().getOffsetZ()));
        }
        for (Direction d : new Direction[]{Direction.NORTH, Direction.SOUTH, Direction.EAST, Direction.WEST}) {
            BlockPos b = p.up(2).offset(d);
            if (BlockUtil.isReplaceable(b))
                BlockUtil.place(b, d.getOpposite(), Vec3d.ofCenter(b));
        }
        if (BlockUtil.isReplaceable(p.up(3))) BlockUtil.place(p.up(3), Direction.UP, Vec3d.ofCenter(p.up(3)).add(0, 0.5, 0));
        last = System.currentTimeMillis();
    }
}
EOF

cat > "$B/module/impl/combat/AutoExp.java" <<'EOF'
package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.item.Items;
import net.minecraft.util.Hand;

public class AutoExp extends Module {
    private final NumberSetting delay = add(new NumberSetting("Delay", 50.0, 0.0, 500.0, 10.0));
    private long last;
    public AutoExp() { super("AutoExp", "Throws XP to repair armor", Category.COMBAT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (System.currentTimeMillis() - last < delay.get()) return;
        boolean mending = false;
        for (var s : mc.player.getArmorItems()) if (s.hasEnchantments()) { mending = true; break; }
        if (!mending) return;
        int slot = -1;
        for (int i = 0; i < 9; i++) if (mc.player.getInventory().getStack(i).getItem() == Items.EXPERIENCE_BOTTLE) { slot = i; break; }
        if (slot == -1) return;
        int prev = mc.player.getInventory().selectedSlot;
        mc.player.getInventory().selectedSlot = slot;
        mc.interactionManager.interactItem(mc.player, Hand.MAIN_HAND);
        mc.player.swingHand(Hand.MAIN_HAND);
        mc.player.getInventory().selectedSlot = prev;
        last = System.currentTimeMillis();
    }
}
EOF

cat > "$B/module/impl/combat/Reach.java" <<'EOF'
package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;

public class Reach extends Module {
    public final NumberSetting blockReach = add(new NumberSetting("BlockReach", 5.0, 3.0, 6.0, 0.1));
    public final NumberSetting entityReach = add(new NumberSetting("EntityReach", 3.0, 3.0, 6.0, 0.1));
    public Reach() { super("Reach", "Extends interaction range", Category.COMBAT); }
}
EOF

cat > "$B/module/impl/combat/AutoLogout.java" <<'EOF'
package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.player.PlayerEntity;

public class AutoLogout extends Module {
    private final NumberSetting health = add(new NumberSetting("Health", 6.0, 1.0, 20.0, 0.5));
    private final BooleanSetting playerNear = add(new BooleanSetting("PlayerNear", true));
    private final NumberSetting range = add(new NumberSetting("Range", 12.0, 4.0, 32.0, 1.0));
    public AutoLogout() { super("AutoLogout", "Disconnect on low HP / nearby player", Category.COMBAT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        if (mc.player.getHealth() <= health.get()) {
            mc.getNetworkHandler().getConnection().disconnect(net.minecraft.text.Text.literal("AutoLogout"));
            return;
        }
        if (playerNear.get()) {
            boolean near = !mc.world.getEntitiesByClass(PlayerEntity.class,
                mc.player.getBoundingBox().expand(range.get()), e -> e != mc.player).isEmpty();
            if (near) mc.getNetworkHandler().getConnection().disconnect(net.minecraft.text.Text.literal("AutoLogout"));
        }
    }
}
EOF

cat > "$B/module/impl/combat/AntiPhase.java" <<'EOF'
package dev.archive.hackclient.module.impl.combat;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;

public class AntiPhase extends Module {
    public AntiPhase() { super("AntiPhase", "Anti-phase mitigation stub", Category.COMBAT); }
}
EOF

# ---------- movement ----------
cat > "$B/module/impl/movement/Sprint.java" <<'EOF'
package dev.archive.hackclient.module.impl.movement;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import net.minecraft.client.MinecraftClient;

public class Sprint extends Module {
    public Sprint() { super("Sprint", "Permanent sprint", Category.MOVEMENT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (mc.player.forwardSpeed > 0 && !mc.player.isSneaking()) mc.player.setSprinting(true);
    }
}
EOF

cat > "$B/module/impl/movement/NoSlow.java" <<'EOF'
package dev.archive.hackclient.module.impl.movement;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.ModeSetting;

public class NoSlow extends Module {
    public final ModeSetting mode = add(new ModeSetting("Mode", "Vanilla", "Vanilla", "NCP", "Strict"));
    public NoSlow() { super("NoSlow", "No slowdown while using items", Category.MOVEMENT); }
}
EOF

cat > "$B/module/impl/movement/Flight.java" <<'EOF'
package dev.archive.hackclient.module.impl.movement;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;

public class Flight extends Module {
    private final NumberSetting speed = add(new NumberSetting("Speed", 1.0, 0.1, 5.0, 0.1));
    public Flight() { super("Flight", "Creative-style flight", Category.MOVEMENT); }
    @Override public void onEnable() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player != null) mc.player.getAbilities().allowFlying = true;
    }
    @Override public void onDisable() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player != null && !mc.player.isCreative()) {
            mc.player.getAbilities().allowFlying = false;
            mc.player.getAbilities().flying = false;
        }
    }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        mc.player.getAbilities().setFlySpeed(speed.getFloat() * 0.05f);
        mc.player.getAbilities().allowFlying = true;
        if (!mc.player.getAbilities().flying && mc.options.jumpKey.isPressed()) mc.player.getAbilities().flying = true;
    }
}
EOF

cat > "$B/module/impl/movement/Speed.java" <<'EOF'
package dev.archive.hackclient.module.impl.movement;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;

public class Speed extends Module {
    private final NumberSetting multiplier = add(new NumberSetting("Multiplier", 1.35, 1.0, 3.0, 0.05));
    public Speed() { super("Speed", "Movement speed modifier", Category.MOVEMENT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (mc.player.forwardSpeed > 0 && mc.player.isOnGround()) {
            double mx = mc.player.getVelocity().x * multiplier.get();
            double mz = mc.player.getVelocity().z * multiplier.get();
            mc.player.setVelocity(mx, mc.player.getVelocity().y, mz);
        }
    }
}
EOF

cat > "$B/module/impl/movement/Phase.java" <<'EOF'
package dev.archive.hackclient.module.impl.movement;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.ModeSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.network.packet.c2s.play.PlayerMoveC2SPacket;

public class Phase extends Module {
    private final ModeSetting mode = add(new ModeSetting("Mode", "Packet", "Packet", "Sand", "Minecart"));
    public Phase() { super("Phase", "Clip through blocks", Category.MOVEMENT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.getNetworkHandler() == null) return;
        if (!mode.is("Packet")) return;
        if (!mc.player.horizontalCollision) return;
        double x = mc.player.getX(), y = mc.player.getY(), z = mc.player.getZ();
        mc.getNetworkHandler().sendPacket(new PlayerMoveC2SPacket.PositionAndOnGround(x, y - 0.0001, z, true, mc.player.horizontalCollision));
        mc.player.setPosition(x, y - 0.0001, z);
    }
}
EOF

cat > "$B/module/impl/movement/NoFall.java" <<'EOF'
package dev.archive.hackclient.module.impl.movement;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.ModeSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.network.packet.c2s.play.PlayerMoveC2SPacket;

public class NoFall extends Module {
    private final ModeSetting mode = add(new ModeSetting("Mode", "Packet", "Packet", "Ground"));
    public NoFall() { super("NoFall", "Prevents fall damage", Category.MOVEMENT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.getNetworkHandler() == null) return;
        if (mc.player.fallDistance > 2.5f) {
            if (mode.is("Packet"))
                mc.getNetworkHandler().sendPacket(new PlayerMoveC2SPacket.OnGroundOnly(true, mc.player.horizontalCollision));
            else if (mode.is("Ground"))
                mc.player.setOnGround(true);
        }
    }
}
EOF

cat > "$B/module/impl/movement/Step.java" <<'EOF'
package dev.archive.hackclient.module.impl.movement;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;

public class Step extends Module {
    public final NumberSetting height = add(new NumberSetting("Height", 1.5, 0.5, 2.5, 0.1));
    public Step() { super("Step", "Step up blocks", Category.MOVEMENT); }
}
EOF

cat > "$B/module/impl/movement/Scaffold.java" <<'EOF'
package dev.archive.hackclient.module.impl.movement;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.util.BlockUtil;
import net.minecraft.client.MinecraftClient;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.Vec3d;

public class Scaffold extends Module {
    private final BooleanSetting tower = add(new BooleanSetting("Tower", true));
    private final BooleanSetting rotate = add(new BooleanSetting("Rotate", true));
    public Scaffold() { super("Scaffold", "Auto bridge", Category.MOVEMENT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        BlockPos below = mc.player.getBlockPos().down();
        if (BlockUtil.isReplaceable(below))
            BlockUtil.place(below, Direction.UP, Vec3d.ofCenter(below).add(0, 0.5, 0));
        if (tower.get() && mc.options.jumpKey.isPressed())
            mc.player.setVelocity(mc.player.getVelocity().x, 0.42, mc.player.getVelocity().z);
    }
}
EOF

echo "[chunk2] done. Append chunks 3-4 before running."

# =========================================================================
# CHUNK 3/4 — RENDER + AESTHETIC
# =========================================================================
B=src/main/java/dev/archive/hackclient

cat > "$B/module/impl/render/ESP.java" <<'EOF'
package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.Entity;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.player.PlayerEntity;

public class ESP extends Module {
    public final BooleanSetting players = add(new BooleanSetting("Players", true));
    public final BooleanSetting mobs = add(new BooleanSetting("Mobs", false));
    public final NumberSetting range = add(new NumberSetting("Range", 64.0, 8.0, 256.0, 8.0));
    public ESP() { super("ESP", "Outline entities", Category.RENDER); }
    public boolean shouldRender(Entity e) {
        if (!isEnabled() || e == MinecraftClient.getInstance().player) return false;
        double r = range.get();
        if (MinecraftClient.getInstance().player.squaredDistanceTo(e) > r * r) return false;
        if (e instanceof PlayerEntity) return players.get();
        if (e instanceof LivingEntity) return mobs.get();
        return false;
    }
}
EOF

cat > "$B/module/impl/render/Tracers.java" <<'EOF'
package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;

public class Tracers extends Module {
    public final BooleanSetting players = add(new BooleanSetting("Players", true));
    public final BooleanSetting mobs = add(new BooleanSetting("Mobs", false));
    public final BooleanSetting throughWalls = add(new BooleanSetting("ThroughWalls", true));
    public Tracers() { super("Tracers", "Lines to entities", Category.RENDER); }
}
EOF

cat > "$B/module/impl/render/Nametags.java" <<'EOF'
package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class Nametags extends Module {
    public final BooleanSetting health = add(new BooleanSetting("Health", true));
    public final BooleanSetting ping = add(new BooleanSetting("Ping", true));
    public final NumberSetting scale = add(new NumberSetting("Scale", 1.0, 0.5, 3.0, 0.1));
    public Nametags() { super("Nametags", "Enhanced player nametags", Category.RENDER); }
}
EOF

cat > "$B/module/impl/render/Chams.java" <<'EOF'
package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.ModeSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class Chams extends Module {
    public final BooleanSetting players = add(new BooleanSetting("Players", true));
    public final BooleanSetting self = add(new BooleanSetting("Self", false));
    public final BooleanSetting mobs = add(new BooleanSetting("Mobs", false));
    public final ModeSetting mode = add(new ModeSetting("Mode", "Flat", "Flat", "Texture", "Glow", "Wireframe"));
    public final ModeSetting colorMode = add(new ModeSetting("Color", "Static", "Static", "Rainbow", "Health", "Team"));
    public final NumberSetting range = add(new NumberSetting("Range", 64.0, 8.0, 256.0, 8.0));
    public final NumberSetting alpha = add(new NumberSetting("Alpha", 0.6, 0.1, 1.0, 0.05));
    public final BooleanSetting throughWalls = add(new BooleanSetting("ThroughWalls", true));
    public Chams() { super("Chams", "Depth-tinted entity rendering", Category.RENDER); }
}
EOF

cat > "$B/module/impl/render/Wings.java" <<'EOF'
package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.ModeSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class Wings extends Module {
    public final ModeSetting style = add(new ModeSetting("Style", "Angel", "Angel", "Demon", "Crystal", "Feather"));
    public final ModeSetting colorMode = add(new ModeSetting("Color", "Rainbow", "Static", "Rainbow", "Gradient"));
    public final NumberSetting scale = add(new NumberSetting("Scale", 1.0, 0.3, 3.0, 0.1));
    public final NumberSetting flapSpeed = add(new NumberSetting("FlapSpeed", 1.5, 0.1, 5.0, 0.1));
    public final NumberSetting opacity = add(new NumberSetting("Opacity", 0.85, 0.1, 1.0, 0.05));
    public Wings() { super("Wings", "Cosmetic wings on player", Category.RENDER); }
}
EOF

cat > "$B/module/impl/render/VegaLines.java" <<'EOF'
package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class VegaLines extends Module {
    public final BooleanSetting players = add(new BooleanSetting("Players", true));
    public final BooleanSetting self = add(new BooleanSetting("Self", false));
    public final NumberSetting height = add(new NumberSetting("Height", 2.0, 0.5, 8.0, 0.1));
    public final NumberSetting width = add(new NumberSetting("Width", 0.15, 0.05, 0.5, 0.01));
    public final NumberSetting opacity = add(new NumberSetting("Opacity", 0.6, 0.1, 1.0, 0.05));
    public final NumberSetting range = add(new NumberSetting("Range", 64.0, 8.0, 256.0, 8.0));
    public VegaLines() { super("VegaLines", "Vertical rainbow beams under players", Category.RENDER); }
}
EOF

cat > "$B/module/impl/render/ChinaHat.java" <<'EOF'
package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class ChinaHat extends Module {
    public final BooleanSetting self = add(new BooleanSetting("Self", true));
    public final NumberSetting radius = add(new NumberSetting("Radius", 0.6, 0.3, 1.5, 0.05));
    public final NumberSetting height = add(new NumberSetting("Height", 0.5, 0.1, 2.0, 0.1));
    public final NumberSetting segments = add(new NumberSetting("Segments", 32.0, 8.0, 64.0, 1.0));
    public ChinaHat() { super("ChinaHat", "Cone hat on head", Category.RENDER); }
}
EOF

cat > "$B/module/impl/render/Trail.java" <<'EOF'
package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.util.math.Vec3d;
import java.util.*;

public class Trail extends Module {
    public final BooleanSetting self = add(new BooleanSetting("Self", true));
    public final BooleanSetting players = add(new BooleanSetting("Players", false));
    public final NumberSetting length = add(new NumberSetting("Length", 24.0, 4.0, 100.0, 1.0));
    public final NumberSetting opacity = add(new NumberSetting("Opacity", 0.5, 0.1, 1.0, 0.05));
    public final Map<UUID, Deque<Vec3d>> trails = new HashMap<>();

    public Trail() { super("Trail", "Motion trails behind entities", Category.RENDER); }
    public void push(UUID id, Vec3d pos) {
        Deque<Vec3d> d = trails.computeIfAbsent(id, k -> new ArrayDeque<>());
        d.addLast(pos);
        while (d.size() > length.getInt()) d.removeFirst();
    }
    @Override public void onDisable() { trails.clear(); }
}
EOF

cat > "$B/module/impl/render/Breadcrumbs.java" <<'EOF'
package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.util.math.Vec3d;
import java.util.*;

public class Breadcrumbs extends Module {
    public final NumberSetting length = add(new NumberSetting("Length", 200.0, 20.0, 1000.0, 10.0));
    public final NumberSetting opacity = add(new NumberSetting("Opacity", 0.7, 0.1, 1.0, 0.05));
    public final Deque<Vec3d> points = new ArrayDeque<>();

    public Breadcrumbs() { super("Breadcrumbs", "Dotted path behind player", Category.RENDER); }
    @Override public void onTick() {
        var mc = net.minecraft.client.MinecraftClient.getInstance();
        if (mc.player == null) return;
        points.addLast(mc.player.getPos());
        while (points.size() > length.getInt()) points.removeFirst();
    }
    @Override public void onDisable() { points.clear(); }
}
EOF

cat > "$B/module/impl/render/TargetHud.java" <<'EOF'
package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.ModeSetting;
import net.minecraft.entity.LivingEntity;

public class TargetHud extends Module {
    public final ModeSetting style = add(new ModeSetting("Style", "Glass", "Glass", "Mio", "Vega", "Minimal"));
    public final BooleanSetting health = add(new BooleanSetting("Health", true));
    public final BooleanSetting armor = add(new BooleanSetting("Armor", true));
    public final BooleanSetting ping = add(new BooleanSetting("Ping", true));
    public final BooleanSetting animation = add(new BooleanSetting("Animation", true));
    public LivingEntity lastTarget;
    public TargetHud() { super("TargetHud", "Info panel on last attack target", Category.RENDER); }
    public void setTarget(LivingEntity t) { this.lastTarget = t; }
}
EOF

cat > "$B/module/impl/render/Particles.java" <<'EOF'
package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.ModeSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class Particles extends Module {
    public final ModeSetting mode = add(new ModeSetting("Mode", "Aura", "Aura", "Hit", "Trail", "Death"));
    public final NumberSetting count = add(new NumberSetting("Count", 8.0, 1.0, 50.0, 1.0));
    public final NumberSetting lifetime = add(new NumberSetting("Lifetime", 20.0, 5.0, 100.0, 1.0));
    public Particles() { super("Particles", "Cosmetic particle effects", Category.RENDER); }
}
EOF

cat > "$B/module/impl/render/Crosshair.java" <<'EOF'
package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.ModeSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class Crosshair extends Module {
    public final ModeSetting style = add(new ModeSetting("Style", "Plus", "Plus", "Dot", "Circle", "Cross"));
    public final NumberSetting size = add(new NumberSetting("Size", 8.0, 2.0, 30.0, 1.0));
    public final NumberSetting thickness = add(new NumberSetting("Thickness", 1.0, 1.0, 4.0, 1.0));
    public final BooleanSetting rainbow = add(new BooleanSetting("Rainbow", true));
    public Crosshair() { super("Crosshair", "Custom crosshair", Category.RENDER); }
}
EOF

cat > "$B/module/impl/render/Watermark.java" <<'EOF'
package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.ModeSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class Watermark extends Module {
    public final ModeSetting position = add(new ModeSetting("Position", "TopLeft", "TopLeft", "TopRight", "BottomLeft", "BottomRight"));
    public final BooleanSetting rainbow = add(new BooleanSetting("Rainbow", true));
    public final BooleanSetting fps = add(new BooleanSetting("Fps", true));
    public final BooleanSetting ping = add(new BooleanSetting("Ping", true));
    public final BooleanSetting tps = add(new BooleanSetting("Tps", false));
    public final NumberSetting scale = add(new NumberSetting("Scale", 1.0, 0.5, 3.0, 0.1));
    public Watermark() { super("Watermark", "Client watermark HUD", Category.RENDER); }
}
EOF

cat > "$B/module/impl/render/Ambience.java" <<'EOF'
package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class Ambience extends Module {
    public final BooleanSetting skyOverride = add(new BooleanSetting("SkyOverride", false));
    public final NumberSetting hue = add(new NumberSetting("Hue", 0.6, 0.0, 1.0, 0.01));
    public final BooleanSetting fogReduce = add(new BooleanSetting("FogReduce", true));
    public final NumberSetting fogStart = add(new NumberSetting("FogStart", 100.0, 10.0, 1000.0, 10.0));
    public final BooleanSetting fullBright = add(new BooleanSetting("FullBright", true));
    public Ambience() { super("Ambience", "Sky and lighting overrides", Category.RENDER); }
}
EOF

cat > "$B/module/impl/render/BlockHighlight.java" <<'EOF'
package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class BlockHighlight extends Module {
    public final NumberSetting opacity = add(new NumberSetting("Opacity", 0.4, 0.1, 1.0, 0.05));
    public final BooleanSetting outline = add(new BooleanSetting("Outline", true));
    public final BooleanSetting fill = add(new BooleanSetting("Fill", true));
    public BlockHighlight() { super("BlockHighlight", "Highlights the block you look at", Category.RENDER); }
}
EOF

cat > "$B/module/impl/render/StorageESP.java" <<'EOF'
package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class StorageESP extends Module {
    public final BooleanSetting chests = add(new BooleanSetting("Chests", true));
    public final BooleanSetting shulkers = add(new BooleanSetting("Shulkers", true));
    public final BooleanSetting barrels = add(new BooleanSetting("Barrels", true));
    public final BooleanSetting enderChests = add(new BooleanSetting("EnderChests", false));
    public final BooleanSetting spawners = add(new BooleanSetting("Spawners", true));
    public final BooleanSetting throughWalls = add(new BooleanSetting("ThroughWalls", true));
    public final NumberSetting range = add(new NumberSetting("Range", 32.0, 8.0, 128.0, 8.0));
    public StorageESP() { super("StorageESP", "Outlines containers and spawners", Category.RENDER); }
}
EOF

cat > "$B/module/impl/render/HoleESP.java" <<'EOF'
package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class HoleESP extends Module {
    public final NumberSetting range = add(new NumberSetting("Range", 16.0, 4.0, 32.0, 1.0));
    public final NumberSetting opacity = add(new NumberSetting("Opacity", 0.5, 0.1, 1.0, 0.05));
    public final BooleanSetting bedrock = add(new BooleanSetting("Bedrock", true));
    public final BooleanSetting obsidian = add(new BooleanSetting("Obsidian", true));
    public final BooleanSetting mixed = add(new BooleanSetting("Mixed", false));
    public HoleESP() { super("HoleESP", "Highlights safe holes", Category.RENDER); }
}
EOF

cat > "$B/module/impl/render/Trajectories.java" <<'EOF'
package dev.archive.hackclient.module.impl.render;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;

public class Trajectories extends Module {
    public final BooleanSetting bows = add(new BooleanSetting("Bows", true));
    public final BooleanSetting pearls = add(new BooleanSetting("Pearls", true));
    public final BooleanSetting potions = add(new BooleanSetting("Potions", true));
    public final NumberSetting maxSteps = add(new NumberSetting("MaxSteps", 240.0, 40.0, 800.0, 20.0));
    public Trajectories() { super("Trajectories", "Projectile path prediction", Category.RENDER); }
}
EOF

echo "[chunk3] done. Append chunk 4 before running."

# =========================================================================
# CHUNK 4/4 — DONUT + SOUND MODULES + MIXINS
# =========================================================================
B=src/main/java/dev/archive/hackclient

# ---------- donut modules ----------
cat > "$B/module/impl/donut/DonutStashFinder.java" <<'EOF'
package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.block.Blocks;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.ChunkPos;
import java.util.*;

public class DonutStashFinder extends Module {
    private final NumberSetting range = add(new NumberSetting("Range", 32.0, 8.0, 128.0, 8.0));
    private final NumberSetting minContainers = add(new NumberSetting("MinContainers", 4.0, 1.0, 32.0, 1.0));
    private final BooleanSetting disconnect = add(new BooleanSetting("Disconnect", false));
    private final Map<ChunkPos, Integer> hits = new HashMap<>();

    public DonutStashFinder() { super("DonutStashFinder", "Scans for container clusters", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        int r = (int) Math.ceil(range.get());
        BlockPos center = mc.player.getBlockPos();
        for (int dx = -r; dx <= r; dx += 4)
        for (int dy = -32; dy <= 32; dy += 4)
        for (int dz = -r; dz <= r; dz += 4) {
            BlockPos p = center.add(dx, dy, dz);
            var block = mc.world.getBlockState(p).getBlock();
            if (block == Blocks.CHEST || block == Blocks.TRAPPED_CHEST || block == Blocks.BARREL
                || block == Blocks.SHULKER_BOX || block == Blocks.ENDER_CHEST) {
                ChunkPos cp = new ChunkPos(p);
                hits.merge(cp, 1, Integer::sum);
                if (hits.get(cp) >= minContainers.get()) {
                    if (disconnect.get())
                        mc.getNetworkHandler().getConnection().disconnect(
                            net.minecraft.text.Text.literal("Stash: " + cp.x + "," + cp.z));
                    hits.remove(cp);
                }
            }
        }
    }
    @Override public void onDisable() { hits.clear(); }
}
EOF

cat > "$B/module/impl/donut/DonutSpawnerProtect.java" <<'EOF'
package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.block.Blocks;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.util.math.BlockPos;

public class DonutSpawnerProtect extends Module {
    private final NumberSetting range = add(new NumberSetting("Range", 16.0, 4.0, 32.0, 1.0));
    private final BooleanSetting breakAndStore = add(new BooleanSetting("BreakStore", true));
    public DonutSpawnerProtect() { super("DonutSpawnerProtect", "Breaks spawner on player detection", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        boolean near = !mc.world.getEntitiesByClass(PlayerEntity.class,
            mc.player.getBoundingBox().expand(range.get()), e -> e != mc.player).isEmpty();
        if (!near || !breakAndStore.get()) return;
        BlockPos center = mc.player.getBlockPos();
        int r = (int) range.get();
        for (int dx = -r; dx <= r; dx++)
        for (int dy = -4; dy <= 4; dy++)
        for (int dz = -r; dz <= r; dz++) {
            BlockPos p = center.add(dx, dy, dz);
            if (mc.world.getBlockState(p).isOf(Blocks.SPAWNER)) {
                mc.interactionManager.updateBlockBreakingProgress(p, net.minecraft.util.math.Direction.UP);
                mc.player.swingHand(net.minecraft.util.Hand.MAIN_HAND);
                return;
            }
        }
    }
}
EOF

cat > "$B/module/impl/donut/DonutSpawnerSell.java" <<'EOF'
package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.item.Items;

public class DonutSpawnerSell extends Module {
    private final BooleanSetting bones = add(new BooleanSetting("Bones", true));
    public DonutSpawnerSell() { super("DonutSpawnerSell", "Drops spawner loot", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        for (int i = 9; i < 36; i++) {
            var s = mc.player.getInventory().getStack(i);
            if (bones.get() && s.getItem() == Items.BONE) mc.player.dropSelectedItem(false);
        }
    }
}
EOF

cat > "$B/module/impl/donut/DonutAutoSell.java" <<'EOF'
package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;

public class DonutAutoSell extends Module {
    private final NumberSetting delay = add(new NumberSetting("Delay", 500.0, 100.0, 2000.0, 50.0));
    private long last;
    public DonutAutoSell() { super("DonutAutoSell", "Runs /sell hand on hotbar", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (System.currentTimeMillis() - last < delay.get()) return;
        if (mc.player.getMainHandStack().isEmpty()) return;
        mc.player.networkHandler.sendChatCommand("sell hand");
        last = System.currentTimeMillis();
    }
}
EOF

cat > "$B/module/impl/donut/DonutAHSell.java" <<'EOF'
package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;

public class DonutAHSell extends Module {
    private final NumberSetting price = add(new NumberSetting("Price", 100.0, 1.0, 100000.0, 100.0));
    private final NumberSetting delay = add(new NumberSetting("Delay", 1000.0, 200.0, 5000.0, 100.0));
    private long last;
    public DonutAHSell() { super("DonutAHSell", "Lists held item on AH", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (System.currentTimeMillis() - last < delay.get()) return;
        if (mc.player.getMainHandStack().isEmpty()) return;
        mc.player.networkHandler.sendChatCommand("ah sell " + (int) price.get());
        last = System.currentTimeMillis();
    }
}
EOF

cat > "$B/module/impl/donut/DonutOrderDropper.java" <<'EOF'
package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import net.minecraft.client.MinecraftClient;

public class DonutOrderDropper extends Module {
    public DonutOrderDropper() { super("DonutOrderDropper", "Runs /order for held item", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (mc.options.useKey.isPressed()) {
            var held = mc.player.getMainHandStack();
            if (!held.isEmpty()) {
                String name = held.getItem().toString().toLowerCase().replace("item.", "").replace("_", "");
                mc.player.networkHandler.sendChatCommand("order " + name);
            }
        }
    }
}
EOF

cat > "$B/module/impl/donut/DonutEmergencyDisconnect.java" <<'EOF'
package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.player.PlayerEntity;

public class DonutEmergencyDisconnect extends Module {
    private final NumberSetting range = add(new NumberSetting("Range", 20.0, 4.0, 64.0, 1.0));
    public DonutEmergencyDisconnect() { super("DonutEmergencyDisconnect", "Disconnect on player proximity", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        boolean near = !mc.world.getEntitiesByClass(PlayerEntity.class,
            mc.player.getBoundingBox().expand(range.get()), e -> e != mc.player).isEmpty();
        if (near) mc.getNetworkHandler().getConnection().disconnect(net.minecraft.text.Text.literal("Emergency"));
    }
}
EOF

cat > "$B/module/impl/donut/DonutStorageStealer.java" <<'EOF'
package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.util.math.BlockPos;
import net.minecraft.block.Blocks;

public class DonutStorageStealer extends Module {
    private final NumberSetting range = add(new NumberSetting("Range", 4.5, 1.0, 6.0, 0.1));
    public DonutStorageStealer() { super("DonutStorageStealer", "Auto-loots chests/shulkers", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        if (mc.currentScreen != null) return;
        BlockPos center = mc.player.getBlockPos();
        int r = (int) range.get();
        for (int dx = -r; dx <= r; dx++)
        for (int dy = -2; dy <= 2; dy++)
        for (int dz = -r; dz <= r; dz++) {
            BlockPos p = center.add(dx, dy, dz);
            var block = mc.world.getBlockState(p).getBlock();
            if (block == Blocks.CHEST || block == Blocks.BARREL || block == Blocks.SHULKER_BOX) {
                if (mc.player.squaredDistanceTo(net.minecraft.util.math.Vec3d.ofCenter(p)) > range.get() * range.get()) continue;
                var hit = new net.minecraft.util.hit.BlockHitResult(
                    net.minecraft.util.math.Vec3d.ofCenter(p), net.minecraft.util.math.Direction.UP, p, false);
                mc.interactionManager.interactBlock(mc.player, net.minecraft.util.Hand.MAIN_HAND, hit);
                return;
            }
        }
    }
}
EOF

cat > "$B/module/impl/donut/DonutAdminDetector.java" <<'EOF'
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
EOF

cat > "$B/module/impl/donut/DonutAntiTrap.java" <<'EOF'
package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.Entity;
import net.minecraft.entity.EntityType;
import net.minecraft.network.packet.c2s.play.PlayerInteractEntityC2SPacket;
import net.minecraft.util.Hand;

public class DonutAntiTrap extends Module {
    public DonutAntiTrap() { super("DonutAntiTrap", "Escapes armor stand/minecart traps", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        for (Entity e : mc.world.getEntitiesByClass(Entity.class,
            mc.player.getBoundingBox().expand(2.0),
            en -> en.getType() == EntityType.ARMOR_STAND || en.getType() == EntityType.MINECART
                || en.getType() == EntityType.CHEST_MINECART || en.getType() == EntityType.HOPPER_MINECART)) {
            mc.getNetworkHandler().sendPacket(
                PlayerInteractEntityC2SPacket.attack(e, mc.player.isSneaking()));
            mc.player.swingHand(Hand.MAIN_HAND);
        }
    }
}
EOF

cat > "$B/module/impl/donut/DonutFreecam.java" <<'EOF'
package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.util.math.Vec3d;

public class DonutFreecam extends Module {
    private final NumberSetting speed = add(new NumberSetting("Speed", 1.0, 0.1, 5.0, 0.1));
    private Vec3d pos;
    public DonutFreecam() { super("DonutFreecam", "Detached camera", Category.DONUT); }
    @Override public void onEnable() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player != null) pos = mc.player.getPos();
    }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || pos == null) return;
        Vec3d fwd = Vec3d.fromPolar(0, mc.player.getYaw()).multiply(speed.get() * 0.1);
        if (mc.options.forwardKey.isPressed()) pos = pos.add(fwd);
        if (mc.options.backKey.isPressed()) pos = pos.subtract(fwd);
        if (mc.options.jumpKey.isPressed()) pos = pos.add(0, speed.get() * 0.1, 0);
        if (mc.options.sneakKey.isPressed()) pos = pos.subtract(0, speed.get() * 0.1, 0);
    }
    @Override public void onDisable() { pos = null; }
    public Vec3d getCamPos() { return pos; }
}
EOF

cat > "$B/module/impl/donut/DonutNoBlockInteract.java" <<'EOF'
package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import net.minecraft.client.MinecraftClient;

public class DonutNoBlockInteract extends Module {
    public DonutNoBlockInteract() { super("DonutNoBlockInteract", "Blocks container GUI while holding pearl", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (mc.player.getMainHandStack().getItem() == net.minecraft.item.Items.ENDER_PEARL) {
            if (mc.currentScreen != null && mc.currentScreen.getTitle() != null) {
                String t = mc.currentScreen.getTitle().getString().toLowerCase();
                if (t.contains("chest") || t.contains("barrel") || t.contains("shulker"))
                    mc.setScreen(null);
            }
        }
    }
}
EOF

cat > "$B/module/impl/donut/DonutAutoPearlChain.java" <<'EOF'
package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.item.Items;
import net.minecraft.util.Hand;

public class DonutAutoPearlChain extends Module {
    private final NumberSetting delay = add(new NumberSetting("Delay", 200.0, 50.0, 1000.0, 10.0));
    private long last;
    public DonutAutoPearlChain() { super("DonutAutoPearlChain", "Chains pearls after teleport", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (System.currentTimeMillis() - last < delay.get()) return;
        if (mc.player.getMainHandStack().getItem() != Items.ENDER_PEARL) return;
        if (!mc.player.isOnGround()) {
            mc.interactionManager.interactItem(mc.player, Hand.MAIN_HAND);
            mc.player.swingHand(Hand.MAIN_HAND);
            last = System.currentTimeMillis();
        }
    }
}
EOF

cat > "$B/module/impl/donut/DonutAnchorMacro.java" <<'EOF'
package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.item.Items;
import net.minecraft.util.Hand;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.Vec3d;

public class DonutAnchorMacro extends Module {
    private final NumberSetting range = add(new NumberSetting("Range", 4.5, 1.0, 6.0, 0.1));
    public DonutAnchorMacro() { super("DonutAnchorMacro", "Charges and detonates respawn anchors", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;
        int glowSlot = -1;
        for (int i = 0; i < 9; i++)
            if (mc.player.getInventory().getStack(i).getItem() == Items.GLOWSTONE) glowSlot = i;
        if (glowSlot == -1) return;
        BlockPos center = mc.player.getBlockPos();
        int r = (int) Math.ceil(range.get());
        for (int dx = -r; dx <= r; dx++)
        for (int dy = -2; dy <= 2; dy++)
        for (int dz = -r; dz <= r; dz++) {
            BlockPos p = center.add(dx, dy, dz);
            if (mc.world.getBlockState(p).isOf(net.minecraft.block.Blocks.RESPAWN_ANCHOR)) {
                if (mc.player.squaredDistanceTo(Vec3d.ofCenter(p)) > range.get() * range.get()) continue;
                int prev = mc.player.getInventory().selectedSlot;
                mc.player.getInventory().selectedSlot = glowSlot;
                mc.interactionManager.interactBlock(mc.player, Hand.MAIN_HAND,
                    new BlockHitResult(Vec3d.ofCenter(p), Direction.UP, p, false));
                mc.player.getInventory().selectedSlot = prev;
                mc.interactionManager.interactBlock(mc.player, Hand.MAIN_HAND,
                    new BlockHitResult(Vec3d.ofCenter(p), Direction.UP, p, false));
                return;
            }
        }
    }
}
EOF

cat > "$B/module/impl/donut/DonutKeyPearl.java" <<'EOF'
package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import net.minecraft.client.MinecraftClient;
import net.minecraft.item.Items;
import net.minecraft.util.Hand;

public class DonutKeyPearl extends Module {
    public DonutKeyPearl() { super("DonutKeyPearl", "Bind-triggered pearl throw", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (!mc.options.useKey.isPressed()) return;
        int pearlSlot = -1;
        for (int i = 0; i < 9; i++)
            if (mc.player.getInventory().getStack(i).getItem() == Items.ENDER_PEARL) { pearlSlot = i; break; }
        if (pearlSlot == -1) return;
        int prev = mc.player.getInventory().selectedSlot;
        mc.player.getInventory().selectedSlot = pearlSlot;
        mc.interactionManager.interactItem(mc.player, Hand.MAIN_HAND);
        mc.player.swingHand(Hand.MAIN_HAND);
        mc.player.getInventory().selectedSlot = prev;
    }
}
EOF

cat > "$B/module/impl/donut/DonutAutoCrystalSwitch.java" <<'EOF'
package dev.archive.hackclient.module.impl.donut;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import net.minecraft.client.MinecraftClient;
import net.minecraft.item.Items;

public class DonutAutoCrystalSwitch extends Module {
    public DonutAutoCrystalSwitch() { super("DonutAutoCrystalSwitch", "Switches to crystal after obsidian", Category.DONUT); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        int obsSlot = -1, crystalSlot = -1;
        for (int i = 0; i < 9; i++) {
            var s = mc.player.getInventory().getStack(i);
            if (s.getItem() == Items.OBSIDIAN) obsSlot = i;
            if (s.getItem() == Items.END_CRYSTAL) crystalSlot = i;
        }
        if (obsSlot != -1 && crystalSlot != -1 && mc.player.getInventory().selectedSlot == obsSlot)
            mc.player.getInventory().selectedSlot = crystalSlot;
    }
}
EOF

# ---------- player modules ----------
cat > "$B/module/impl/player/AutoTool.java" <<'EOF'
package dev.archive.hackclient.module.impl.player;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.block.BlockState;
import net.minecraft.util.math.BlockPos;

public class AutoTool extends Module {
    private final BooleanSetting swapBack = add(new BooleanSetting("SwapBack", false));
    private int prevSlot = -1;
    public AutoTool() { super("AutoTool", "Picks best tool for block", Category.PLAYER); }
    public void onBlockBreaking(BlockPos pos) {
        if (!isEnabled()) return;
        MinecraftClient mc = MinecraftClient.getInstance();
        BlockState state = mc.world.getBlockState(pos);
        int best = -1;
        float bestSpeed = 1.0f;
        for (int i = 0; i < 9; i++) {
            var stack = mc.player.getInventory().getStack(i);
            float s = stack.getMiningSpeedMultiplier(state);
            if (s > bestSpeed) { bestSpeed = s; best = i; }
        }
        if (best != -1) {
            if (prevSlot == -1) prevSlot = mc.player.getInventory().selectedSlot;
            mc.player.getInventory().selectedSlot = best;
        }
    }
    @Override public void onDisable() {
        if (swapBack.get() && prevSlot != -1) {
            MinecraftClient mc = MinecraftClient.getInstance();
            if (mc.player != null) mc.player.getInventory().selectedSlot = prevSlot;
        }
        prevSlot = -1;
    }
}
EOF

cat > "$B/module/impl/player/FastPlace.java" <<'EOF'
package dev.archive.hackclient.module.impl.player;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.client.MinecraftClient;

public class FastPlace extends Module {
    private final NumberSetting delay = add(new NumberSetting("Delay", 0.0, 0.0, 4.0, 1.0));
    public FastPlace() { super("FastPlace", "Zero right-click cooldown", Category.PLAYER); }
    @Override public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        mc.itemUseCooldown = delay.getInt();
    }
}
EOF

# ---------- misc ----------
cat > "$B/module/impl/misc/AntiPacket.java" <<'EOF'
package dev.archive.hackclient.module.impl.misc;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.BooleanSetting;

public class AntiPacket extends Module {
    public final BooleanSetting cancelSetback = add(new BooleanSetting("CancelSetback", true));
    public final BooleanSetting cancelRotate = add(new BooleanSetting("CancelRotate", false));
    public AntiPacket() { super("AntiPacket", "Drop server correction packets", Category.MISC); }
}
EOF

# ---------- sound modules ----------
cat > "$B/module/impl/sound/SoundFX.java" <<'EOF'
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
EOF

cat > "$B/module/impl/sound/EnableSound.java" <<'EOF'
package dev.archive.hackclient.module.impl.sound;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;

public class EnableSound extends Module {
    public EnableSound() { super("EnableSound", "Tone on module toggle", Category.RENDER); }
}
EOF

cat > "$B/module/impl/sound/ClickSound.java" <<'EOF'
package dev.archive.hackclient.module.impl.sound;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;

public class ClickSound extends Module {
    public ClickSound() { super("ClickSound", "Click tone in GUI", Category.RENDER); }
}
EOF

cat > "$B/module/impl/sound/HitSound.java" <<'EOF'
package dev.archive.hackclient.module.impl.sound;

import dev.archive.hackclient.module.Category;
import dev.archive.hackclient.module.Module;
import dev.archive.hackclient.setting.NumberSetting;
import net.minecraft.entity.LivingEntity;

public class HitSound extends Module {
    private final NumberSetting pitch = add(new NumberSetting("Pitch", 1.0, 0.5, 2.0, 0.05));
    private final NumberSetting volume = add(new NumberSetting("Volume", 0.5, 0.1, 1.0, 0.05));
    public HitSound() { super("HitSound", "Tone on entity hit", Category.RENDER); }
    public void onHit(LivingEntity target) {
        dev.archive.hackclient.sound.SoundManager.play(
            dev.archive.hackclient.sound.Tone.HIT,
            dev.archive.hackclient.sound.Synth.SR * pitch.getFloat());
    }
}
EOF

cat > "$B/module/impl/sound/KillSound.java" <<'EOF'
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
EOF

# ---------- mixins ----------
cat > "$B/mixin/KeyboardMixin.java" <<'EOF'
package dev.archive.hackclient.mixin;

import dev.archive.hackclient.HackClient;
import net.minecraft.client.Keyboard;
import net.minecraft.client.MinecraftClient;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(Keyboard.class)
public class KeyboardMixin {
    @Inject(method = "onKey", at = @At("HEAD"))
    private void onKey(long window, int key, int scancode, int action, int mods, CallbackInfo ci) {
        if (action != 1) return;
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.currentScreen != null) return;
        HackClient.MODULES.onKey(key);
    }
}
EOF

cat > "$B/mixin/ClientPlayerEntityMixin.java" <<'EOF'
package dev.archive.hackclient.mixin;

import dev.archive.hackclient.HackClient;
import dev.archive.hackclient.module.impl.combat.Velocity;
import net.minecraft.client.network.ClientPlayerEntity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(ClientPlayerEntity.class)
public class ClientPlayerEntityMixin {
    @Inject(method = "setVelocityClient", at = @At("HEAD"), cancellable = true)
    private void onVelocity(double x, double y, double z, CallbackInfo ci) {
        Velocity v = HackClient.MODULES.get(Velocity.class);
        if (v != null && v.isEnabled()) {
            ClientPlayerEntity self = (ClientPlayerEntity)(Object)this;
            self.setVelocity(x * v.horizontal.get() / 100.0, y * v.vertical.get() / 100.0, z * v.horizontal.get() / 100.0);
            ci.cancel();
        }
    }
}
EOF

cat > "$B/mixin/PlayerEntityMixin.java" <<'EOF'
package dev.archive.hackclient.mixin;

import dev.archive.hackclient.HackClient;
import dev.archive.hackclient.module.impl.combat.Criticals;
import dev.archive.hackclient.module.impl.render.TargetHud;
import dev.archive.hackclient.module.impl.sound.HitSound;
import net.minecraft.entity.Entity;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.player.PlayerEntity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(PlayerEntity.class)
public class PlayerEntityMixin {
    @Inject(method = "attack", at = @At("HEAD"))
    private void onAttack(Entity target, CallbackInfo ci) {
        Criticals c = HackClient.MODULES.get(Criticals.class);
        if (c != null) c.doCrit(target);
        if (target instanceof LivingEntity le) {
            TargetHud th = HackClient.MODULES.get(TargetHud.class);
            if (th != null) th.setTarget(le);
            HitSound hs = HackClient.MODULES.get(HitSound.class);
            if (hs != null && hs.isEnabled()) hs.onHit(le);
        }
    }
}
EOF

cat > "$B/mixin/ClientPlayerInteractionManagerMixin.java" <<'EOF'
package dev.archive.hackclient.mixin;

import dev.archive.hackclient.HackClient;
import dev.archive.hackclient.module.impl.combat.Reach;
import net.minecraft.client.network.ClientPlayerInteractionManager;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(ClientPlayerInteractionManager.class)
public class ClientPlayerInteractionManagerMixin {
    @Inject(method = "getReachDistance", at = @At("RETURN"), cancellable = true)
    private void onGetReach(CallbackInfoReturnable<Float> cir) {
        Reach r = HackClient.MODULES.get(Reach.class);
        if (r != null && r.isEnabled()) cir.setReturnValue(r.blockReach.getFloat());
    }
}
EOF

cat > "$B/mixin/EntityMixin.java" <<'EOF'
package dev.archive.hackclient.mixin;

import dev.archive.hackclient.HackClient;
import dev.archive.hackclient.module.impl.combat.Reach;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.Entity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(Entity.class)
public class EntityMixin {
    @Inject(method = "getTargetingMargin", at = @At("RETURN"), cancellable = true)
    private void onTargetingMargin(CallbackInfoReturnable<Float> cir) {
        Reach r = HackClient.MODULES.get(Reach.class);
        if (r != null && r.isEnabled() && (Object)this == MinecraftClient.getInstance().player)
            cir.setReturnValue(r.entityReach.getFloat() - 3.0f);
    }
}
EOF

cat > "$B/mixin/EntityRenderDispatcherMixin.java" <<'EOF'
package dev.archive.hackclient.mixin;

import dev.archive.hackclient.HackClient;
import dev.archive.hackclient.module.impl.render.Chams;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.render.entity.EntityRenderDispatcher;
import net.minecraft.entity.Entity;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.player.PlayerEntity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(EntityRenderDispatcher.class)
public class EntityRenderDispatcherMixin {
    @Inject(method = "shouldRender", at = @At("RETURN"), cancellable = true)
    private void onShouldRender(Entity e, net.minecraft.client.util.math.MatrixStack ms,
                                net.minecraft.client.render.VertexConsumerProvider vcp,
                                net.minecraft.client.render.VertexConsumer vc,
                                net.minecraft.client.render.Frustum f,
                                double x, double y, double z,
                                CallbackInfoReturnable<Boolean> cir) {
        Chams c = HackClient.MODULES.get(Chams.class);
        if (c == null || !c.isEnabled()) return;
        if (!(e instanceof LivingEntity)) return;
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        double r2 = c.range.get() * c.range.get();
        if (mc.player.squaredDistanceTo(e) > r2) return;
        if (e == mc.player && !c.self.get()) return;
        if (e instanceof PlayerEntity && !c.players.get()) return;
        if (!(e instanceof PlayerEntity) && !c.mobs.get()) return;
        cir.setReturnValue(true);
    }
}
EOF

cat > "$B/mixin/InGameHudMixin.java" <<'EOF'
package dev.archive.hackclient.mixin;

import dev.archive.hackclient.HackClient;
import dev.archive.hackclient.module.impl.render.Crosshair;
import net.minecraft.client.gui.hud.InGameHud;
import net.minecraft.client.gui.DrawContext;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(InGameHud.class)
public class InGameHudMixin {
    @Inject(method = "renderCrosshair", at = @At("HEAD"), cancellable = true)
    private void onRenderCrosshair(DrawContext ctx, CallbackInfo ci) {
        Crosshair cr = HackClient.MODULES.get(Crosshair.class);
        if (cr != null && cr.isEnabled()) ci.cancel();
    }
}
EOF

cat > "$B/mixin/LightmapTextureManagerMixin.java" <<'EOF'
package dev.archive.hackclient.mixin;

import dev.archive.hackclient.HackClient;
import dev.archive.hackclient.module.impl.render.Ambience;
import net.minecraft.client.render.LightmapTextureManager;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.ModifyVariable;

@Mixin(LightmapTextureManager.class)
public class LightmapTextureManagerMixin {
    @ModifyVariable(method = "update", at = @At("HEAD"), argsOnly = true, index = 1)
    private float modifyGamma(float gamma) {
        Ambience a = HackClient.MODULES.get(Ambience.class);
        if (a != null && a.isEnabled() && a.fullBright.get()) return 10.0f;
        return gamma;
    }
}
EOF

echo "[chunk4] done. All chunks appended. Run: bash gen.sh"
