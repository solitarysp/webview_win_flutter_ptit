#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

constexpr ULONGLONG kDoubleShiftMaxIntervalMs = 400;
HWND g_main_window = nullptr;
HHOOK g_keyboard_hook = nullptr;
bool g_shift_down = false;
ULONGLONG g_last_shift_down_tick = 0;

void BringWindowToFront(HWND hwnd) {
  if (!hwnd) {
    return;
  }

  if (IsIconic(hwnd)) {
    ShowWindow(hwnd, SW_RESTORE);
  } else {
    ShowWindow(hwnd, SW_SHOW);
  }

  SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
  SetWindowPos(hwnd, HWND_NOTOPMOST, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
  SetForegroundWindow(hwnd);
}

LRESULT CALLBACK KeyboardProc(int n_code, WPARAM w_param, LPARAM l_param) {
  if (n_code == HC_ACTION) {
    auto* keyboard = reinterpret_cast<KBDLLHOOKSTRUCT*>(l_param);
    const bool is_shift =
        keyboard->vkCode == VK_LSHIFT || keyboard->vkCode == VK_RSHIFT;

    if (is_shift) {
      if (w_param == WM_KEYDOWN || w_param == WM_SYSKEYDOWN) {
        if (!g_shift_down) {
          ULONGLONG now = GetTickCount64();
          if (g_last_shift_down_tick != 0 &&
              now - g_last_shift_down_tick <= kDoubleShiftMaxIntervalMs) {
            BringWindowToFront(g_main_window);
          }
          g_last_shift_down_tick = now;
          g_shift_down = true;
        }
      } else if (w_param == WM_KEYUP || w_param == WM_SYSKEYUP) {
        g_shift_down = false;
      }
    }
  }

  return CallNextHookEx(nullptr, n_code, w_param, l_param);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"webview_win_flutter", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  g_main_window = window.GetHandle();
  g_keyboard_hook =
      SetWindowsHookEx(WH_KEYBOARD_LL, KeyboardProc, instance, 0);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  if (g_keyboard_hook != nullptr) {
    UnhookWindowsHookEx(g_keyboard_hook);
    g_keyboard_hook = nullptr;
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
