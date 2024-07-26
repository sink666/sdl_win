module context;

import win;
import bindbc.sdl;

struct DisplayContext
{
    SDL_Window* win_ptr;
    SDL_Texture* framebuffer_ptr;
    SDL_Renderer* renderer_ptr;
    uint[] pixel_buffer;

    int width;
    int height;
    int buf_pitch;
    int buf_stride;
}

struct EventContext
{
    SDL_Event ev;
    bool doQuit = false;
    bool doMoveWin = false;
}

struct WindowContext
{
    ZWindow[] win_list;
    ZWindow* cur;

    ZBug bug;
    SDL_Cursor* cursor;

    int max_width;
    int max_height;
}
