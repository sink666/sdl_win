import std.stdio;
import std.range;
import std.math.rounding;

import context;
import win;
import bindbc.sdl;

//
// global variables, enums, etc
//

enum int WIDTH = 800;
enum int HEIGHT = 600;

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

static DisplayContext* dctx;
static WindowContext* wctx;
static EventContext* ectx;

static ulong f_start;
static ulong f_end;
static float f_elapsed;

//
// rendering functions
//

void change_pixel(int x, int y, uint color)
{
    int index = (dctx.buf_stride * x) + y;

    if (index < dctx.pixel_buffer.length)
    {
        dctx.pixel_buffer[index] = color;
    }
}

void draw_win(int x, int y, int width, int height, uint color)
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
                change_pixel(j, k, color);
        }
    }
}

void doRender()
{
    SDL_UpdateTexture(dctx.framebuffer_ptr, null, dctx.pixel_buffer.ptr, dctx.buf_pitch);
    SDL_RenderCopy(dctx.renderer_ptr, dctx.framebuffer_ptr, null, null);
    SDL_RenderPresent(dctx.renderer_ptr);
}

//
// begin init, main loop, rendering
//

bool doCursorInit()
{
    SDL_Surface* cursor_img = IMG_Load("source/9cursor.png");
    if(cursor_img is null)
        goto init_err;

    wctx.cursor = SDL_CreateColorCursor(cursor_img, 0, 0);
    if(wctx.cursor is null)
        goto init_err;
    
    SDL_SetCursor(wctx.cursor);

    return true;

init_err:
    SDL_Log("SDL error: %s\n", SDL_GetError());
    return false;
}

bool doInit(int width, int height)
{
    dctx = new DisplayContext;
    dctx.width = width;
    dctx.height = height;
    dctx.buf_pitch = (cast(int)(uint.sizeof * width));
    dctx.buf_stride = width;
    dctx.pixel_buffer = new uint[](width * height);

    wctx = new WindowContext;
    wctx.max_width = width;
    wctx.max_height = height;

    makeWindow(300, 80, 50, 50, ZColor.RED);
    makeWindow(100, 100, 100, 300, ZColor.BLUE);
    makeWindow(199, 100, 409, 400, ZColor.GREEN);
    makeWindow(299, 200, 150, 150, ZColor.WHITE);

    ectx = new EventContext;

    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) == -1)
        goto init_err;

    if(IMG_Init(IMG_INIT_PNG) == -1)
        goto init_err;

    dctx.win_ptr = SDL_CreateWindow("f", SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED,
        width, height,
        SDL_WINDOW_ALLOW_HIGHDPI);
    if (dctx.win_ptr is null)
        goto init_err;

    dctx.renderer_ptr = SDL_CreateRenderer(dctx.win_ptr, -1, SDL_RENDERER_TARGETTEXTURE);
    if (dctx.renderer_ptr is null)
        goto init_err;

    dctx.framebuffer_ptr = SDL_CreateTexture(dctx.renderer_ptr, SDL_PIXELFORMAT_RGBA32,
        SDL_TEXTUREACCESS_TARGET, width, height);
    if (dctx.framebuffer_ptr is null)
        goto init_err;

    // scaling setup to deal with high dpi
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "linear");
    SDL_RenderSetLogicalSize(dctx.renderer_ptr, width, height);

    return true;

init_err:
    SDL_Log("SDL error: %s\n", SDL_GetError());
    return false;
}

void doShutdown()
{
    SDL_FreeCursor(wctx.cursor);
    SDL_DestroyWindow(dctx.win_ptr);
    SDL_DestroyTexture(dctx.framebuffer_ptr);
    SDL_DestroyRenderer(dctx.renderer_ptr);
    SDL_QuitSubSystem(SDL_INIT_VIDEO | SDL_INIT_TIMER);
    IMG_Quit();
    SDL_Quit();
}

//
// event stuff
//

void handleMouseDown()
{
    wctx.cur = returnWindowRef();

    if(wctx.cur != null)
        ectx.doDrag = true;
}

void handleMouseUp()
{
    wctx.cur = null;
    ectx.doDrag = false;
}

void handleEvents()
{
    SDL_PollEvent(&ectx.ev);

    switch(ectx.ev.type)
    {
        case SDL_QUIT:
            ectx.doQuit = true;
            break;
        case SDL_MOUSEBUTTONDOWN:
            handleMouseDown();
            break;
        case SDL_MOUSEBUTTONUP:
            handleMouseUp();
            break;
        default:
            break;
    }
}

//
// window functions
//

void makeWindow(int width, int height, int x, int y, ZColor c)
{
    wctx.win_list ~= ZWindow(width, height, x, y, palette[c]);
}

void drawWindows()
{
    foreach(ref p; dctx.pixel_buffer)
        p = palette[ZColor.BLACK];

    foreach(ZWindow w; wctx.win_list)
        draw_win(w.x, w.y, w.dx, w.dy, w.color);
}

void updateBug()
{
    SDL_GetMouseState(&wctx.bug.x, &wctx.bug.y);
    SDL_GetRelativeMouseState(&wctx.bug.rel_x, &wctx.bug.rel_y);
}

ZWindow* returnWindowRef()
{
    ZWindow* ret = wctx.cur;

    if(ret != null)
        goto finish;

    foreach_reverse(ref w; wctx.win_list)
    {
        ZBug* b = &wctx.bug;

        if(b.x >= w.x && b.x <= (w.x + w.dx) &&
            b.y >= w.y && b.y <= (w.y + w.dy))
        {
            ret = &w;
        }
    }

finish:
    return ret;
}

void updateWindows()
{   
    if(ectx.doDrag)
    {
        wctx.cur.x += wctx.bug.rel_x;
        wctx.cur.y += wctx.bug.rel_y;
    }

    // if(ectx.doClick)
    // {
    //     wctx.cur = returnWindowRef();

    //     if(wctx.cur != null)
    //     {
    //         wctx.cur.x += wctx.bug.rel_x;
    //         wctx.cur.y += wctx.bug.rel_y;
    //     }
    // }

    // wctx.cur = null;
}

//
//
//

int main()
{
    if(doInit(WIDTH, HEIGHT) is false)
    {
        doShutdown();
        return 1;
    }

    if(doCursorInit() is false)
    {
        doShutdown();
        return 1;
    }

    while(1)
    {
        if (ectx.doQuit)
            break;

        f_start = SDL_GetPerformanceCounter();

        handleEvents();
        updateBug();
        updateWindows();
        drawWindows();
        doRender();

        f_end = SDL_GetPerformanceCounter();
        f_elapsed = (f_end - f_start) / (SDL_GetPerformanceFrequency() * 1000.0f);

        // cap to 60 fps
        SDL_Delay(cast(uint)floor(16.666f - f_elapsed));

    }

    doShutdown();
    return 0;
}
