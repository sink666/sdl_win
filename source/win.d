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

    // decoration stuff
    int bezel_wid = 2;

    // state stuff
    bool hidden = false;
    bool kill = false;
    uint color;

    // titlebar
    string tb_title;
    // ZButton[] tb_controls;
    // has its own interaction rect
    int tb_dx;
    int tb_dy;

    // constructor
    this(int w, int h, int xx, int yy, string str)
    {
        x = xx;
        y = yy;
        dx = w;
        dy = h;

        tb_dx = dx;
        tb_dy = ((dy / 4) * 3);

        color = pal[ZColor.BLACK];
        tb_title = str;
    }
}

//
// window functions
//

void makeWindow(ref ZWindow[] winlist, int width, int height, int x, int y, string str)
{
    winlist ~= ZWindow(width, height, x, y, str);
}

// a window is:
// - the frame -- top bar, divider between top bar and content area
// - the decorations -- title, top bar buttons
// - content area -- buttons, images, etc in the content area
void drawWindows(DisplayContext* dctx, ref ZWindow[] winlist)
{
    foreach(ref w; winlist)
    {
        // draw rect edge: frame edge
        // draw line: 'border' between top and content
        // draw text: title
        // draw window controls
        draw_win(dctx, w);
    }
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
    bool found_win = false;

    if(ret != null)
        goto finish;

    foreach(size_t i, ref w; winlist)
    {
        if(bref.x >= w.x && bref.x <= (w.x + w.dx) &&
            bref.y >= w.y && bref.y <= (w.y + w.dy))
        {
            index = i;
            focus_copy = w;
            found_win = true;
        }
    }

    if(found_win is false)
        goto finish;

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
