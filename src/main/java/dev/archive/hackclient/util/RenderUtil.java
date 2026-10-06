package dev.archive.hackclient.util;

import net.minecraft.client.gui.DrawContext;

public final class RenderUtil {
    public static void glassRect(DrawContext ctx, int x, int y, int w, int h, int bg, int border) {
        ctx.fill(x, y, x + w, y + h, bg);
        ctx.fill(x, y, x + w, y + 1, border);
        ctx.fill(x, y + h - 1, x + w, y + h, border);
        ctx.fill(x, y, x + 1, y + h, border);
        ctx.fill(x + w - 1, y, x + w, y + h, border);
    }
}
