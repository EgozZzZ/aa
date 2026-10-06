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
