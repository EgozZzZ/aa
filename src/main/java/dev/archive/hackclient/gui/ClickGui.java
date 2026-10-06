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
