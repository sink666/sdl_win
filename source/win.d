module win;

import std.stdio;
import std.range;
import std.math.rounding;

import structs;
import render;
import bindbc.sdl;

//
// structures
//

// the bug, aka the mouse pointer hotspot
struct ZBug
{
    int x;
    int y;
    int rel_x;
    int rel_y;
}

struct ZWindow
{
    // frame stuff
    int dx;
    int dy;
    int x;
    int y;

    // state stuff
    bool hidden = false;
    bool kill = false;
    uint color;

    // titlebar
    // string tb_title;
    // ZButton[] tb_controls;

    //

    this(int w, int h, int xx, int yy, uint cc)
    {
        dx = w;
        dy = h;
        x = xx;
        y = yy;
        color = cc;
    }

}

//
// window functions
//

void makeWindow(ref ZWindow[] winlist, int width, int height, int x, int y, ZColor c)
{
    winlist ~= ZWindow(width, height, x, y, palette[c]);
}

void drawWindows(DisplayContext* dctx, ref ZWindow[] winlist)
{
    foreach(ref p; dctx.pixel_buffer)
        p = palette[ZColor.BLACK];

    foreach(ref w; winlist)
        draw_win(dctx, w.x, w.y, w.dx, w.dy, w.color);
}

void updateBug(ZBug* bref)
{
    SDL_GetMouseState(&bref.x, &bref.y);
    SDL_GetRelativeMouseState(&bref.rel_x, &bref.rel_y);
}

ZWindow* returnWindowRef(ZWindow* cur, ref ZWindow[] winlist, ref ZBug bref)
{
    ZWindow* ret = cur;
    ZWindow[] new_list;
    ZWindow focus_copy;
    size_t index;

    if(ret != null)
        goto finish;

    foreach(size_t i, ref w; winlist)
    {
        if(bref.x >= w.x && bref.x <= (w.x + w.dx) &&
            bref.y >= w.y && bref.y <= (w.y + w.dy))
        {
            index = i;
            focus_copy = w;
        }
    }

    for(size_t i = 0; i < winlist.length; ++i)
    {
        if(i == index)
            continue;
        
        new_list ~= winlist[i];
    }

    new_list ~= focus_copy;
    winlist = new_list;
    ret = &winlist[$-1];

finish:
    return ret;
}

void updateWindows(bool doMove, ZWindow* cur, ref ZBug bref)
{   
    if(doMove)
    {
        cur.x += bref.rel_x;
        cur.y += bref.rel_y;
    }
}
