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
