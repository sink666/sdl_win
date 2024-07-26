module render;

import structs;
import bindbc.sdl;

enum ZColor
{
    BLACK,
    RED,
    BLUE,
    GREEN,
    WHITE,
    MAX
}

uint[5] palette = [
    0x00000000, 0x000000FF, 0x0000FF00, 0x00FF0000, 0x00FFFFFF
];

//
// rendering functions
//

void change_pixel(DisplayContext* dctx, int x, int y, uint color)
{
    int index = (dctx.buf_stride * x) + y;

    if (index < dctx.pixel_buffer.length)
    {
        dctx.pixel_buffer[index] = color;
    }
}

void draw_win(DisplayContext* dctx, int x, int y, int width, int height, uint color)
{
    int xplusw = x + width;
    int yplush = y + height;

    for (int j = y; j < yplush; ++j)
    {
        for (int k = x; k < xplusw; ++k)
        {
            if(k < 0 || k >= dctx.width || (j < 0 || j >= dctx.height))
                continue;
            else
                change_pixel(dctx, j, k, color);
        }
    }
}

void doRender(DisplayContext* dctx)
{
    SDL_UpdateTexture(dctx.framebuffer_ptr, null, dctx.pixel_buffer.ptr, dctx.buf_pitch);
    SDL_RenderCopy(dctx.renderer_ptr, dctx.framebuffer_ptr, null, null);
    SDL_RenderPresent(dctx.renderer_ptr);
}