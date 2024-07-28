import std.stdio;
import std.math.rounding;

import structs;
import render;
import win;
import bindbc.sdl;

//
// global variables, enums, etc
//

enum int WIDTH = 800;
enum int HEIGHT = 600;

static DisplayContext* dctx;
static WindowContext* wctx;
static EventContext* ectx;

static ulong f_start;
static ulong f_end;
static float f_elapsed;

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

    makeWindow(wctx.win_list, 300, 200, 150, 150, "Examble");

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
        SDL_TEXTUREACCESS_STREAMING, width, height);
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
    wctx.cur = returnWindowRef(wctx.cur, wctx.win_list, wctx.bug);

    if(wctx.cur != null)
        ectx.doMoveWin = true;
}

void handleMouseUp()
{
    wctx.cur = null;
    ectx.doMoveWin = false;
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
        updateBug(&wctx.bug);
        updateWindows(ectx.doMoveWin, wctx.cur, wctx.bug);

        // ldc optimizes this, makes it a memset or something
        clear_pb(dctx, ZColor.WHITE);
        drawWindows(dctx, wctx.win_list);
        doRender(dctx);

        f_end = SDL_GetPerformanceCounter();
        f_elapsed = (f_end - f_start) / (SDL_GetPerformanceFrequency() * 1000.0f);

        // cap to 60 fps
        SDL_Delay(cast(uint)floor(16.666f - f_elapsed));
    }

    doShutdown();
    return 0;
}
