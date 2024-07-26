module win;
import context;
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
