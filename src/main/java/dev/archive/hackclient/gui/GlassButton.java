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
