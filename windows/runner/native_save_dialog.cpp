#include "native_save_dialog.h"

#include <windows.h>
#include <commdlg.h>

#include <string>
#include <vector>

namespace {

std::wstring Utf8ToWide(const std::string& value) {
  if (value.empty()) {
    return std::wstring();
  }

  const int size = MultiByteToWideChar(CP_UTF8, 0, value.c_str(), -1, nullptr, 0);
  if (size <= 0) {
    return std::wstring();
  }

  std::wstring wide(size - 1, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, value.c_str(), -1, wide.data(), size);
  return wide;
}

std::string WideToUtf8(const std::wstring& value) {
  if (value.empty()) {
    return std::string();
  }

  const int size =
      WideCharToMultiByte(CP_UTF8, 0, value.c_str(), -1, nullptr, 0, nullptr, nullptr);
  if (size <= 0) {
    return std::string();
  }

  std::string utf8(size - 1, '\0');
  WideCharToMultiByte(CP_UTF8, 0, value.c_str(), -1, utf8.data(), size, nullptr, nullptr);
  return utf8;
}

}  // namespace

std::optional<std::string> ShowNativeSaveDialog(
    const std::string& file_name,
    const std::string& initial_directory,
    const std::string& dialog_title) {
  const std::wstring wide_file_name = Utf8ToWide(file_name);
  const std::wstring wide_title = Utf8ToWide(dialog_title);
  const std::wstring wide_initial_directory = Utf8ToWide(initial_directory);

  std::vector<wchar_t> file_buffer(MAX_PATH, L'\0');
  if (!wide_file_name.empty()) {
    const size_t copy_length =
        std::min(wide_file_name.size(), static_cast<size_t>(MAX_PATH - 1));
    wcsncpy_s(file_buffer.data(), MAX_PATH, wide_file_name.c_str(), copy_length);
  }

  const wchar_t filter[] =
      L"PNG Image (*.png)\0*.png\0"
      L"JPEG Image (*.jpg)\0*.jpg;*.jpeg\0"
      L"BMP Image (*.bmp)\0*.bmp\0"
      L"GIF Image (*.gif)\0*.gif\0"
      L"WebP Image (*.webp)\0*.webp\0"
      L"All Supported Images\0*.png;*.jpg;*.jpeg;*.bmp;*.gif;*.webp\0";

  OPENFILENAMEW dialog = {};
  dialog.lStructSize = sizeof(dialog);
  dialog.lpstrFilter = filter;
  dialog.nFilterIndex = 1;
  dialog.lpstrFile = file_buffer.data();
  dialog.nMaxFile = MAX_PATH;
  dialog.Flags = OFN_OVERWRITEPROMPT | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY |
                 OFN_EXPLORER | OFN_NOCHANGEDIR;
  dialog.lpstrTitle = wide_title.empty() ? nullptr : wide_title.c_str();
  dialog.lpstrInitialDir =
      wide_initial_directory.empty() ? nullptr : wide_initial_directory.c_str();

  if (!GetSaveFileNameW(&dialog)) {
    return std::nullopt;
  }

  return WideToUtf8(file_buffer.data());
}
