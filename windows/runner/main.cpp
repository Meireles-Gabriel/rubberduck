#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

// Entry point for the Windows application / Ponto de entrada para a aplicação Windows
int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  // Anexa ao console quando presente (ex: 'flutter run') ou cria um
  // novo console quando executando com debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  // Inicializa COM, para que esteja disponível para uso na biblioteca e/ou
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(400, 500);

  // Create window without standard decorations / Cria janela sem decorações padrão
  if (!window.CreateAndShow(L"Tamagotchi Duck", origin, size)) {
    return EXIT_FAILURE;
  }

  // Set window properties for widget behavior / Define propriedades da janela para comportamento de widget
  HWND hwnd = window.GetHandle();

  // Remove window from taskbar / Remove janela da barra de tarefas
  LONG_PTR exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
  SetWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle | WS_EX_TOOLWINDOW);

  // Set window to be always on top / Define janela para sempre estar em primeiro plano
  SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);

  // Make window borderless / Torna janela sem bordas
  LONG_PTR style = GetWindowLongPtr(hwnd, GWL_STYLE);
  SetWindowLongPtr(hwnd, GWL_STYLE, style & ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU));

  // Set window shape to rounded rectangle / Define forma da janela como retângulo arredondado
  HRGN hRgn = CreateRoundRectRgn(0, 0, 400, 500, 15, 15);
  SetWindowRgn(hwnd, hRgn, TRUE);

  window.RunMessageLoop();

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
