{$mode objfpc}{$modeswitch objectivec2}program Main;uses	Application, SDLUtils, SDL;	var	window: TGameWindow;	begin	window := TGameWindow.Create(800, 800, kSDLOpenGLWindow_Modern);	window.RunMainLoop;	SDL_Quit;end.