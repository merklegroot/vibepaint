#include "native_save_dialog.h"

#include <windows.h>
#include <commdlg.h>

#include <algorithm>
#include <cctype>
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

std::string EnsureExtension(const std::string& path, const std::string& ext) {
  if (ext.empty()) {
    return path;
  }

  // Find last dot after the last separator.
  size_t sep = path.find_last_of("/\\");
  size_t dot = path.find_last_of('.');
  bool hasExt = (dot != std::string::npos) &&
                (sep == std::string::npos || dot > sep);

  std::string base = path;
  if (hasExt) {
    base = path.substr(0, dot);
  }

  // If base already ends with the desired (case-insensitive), keep as-is.
  std::string desired = "." + ext;
  auto toLowerAscii = [](unsigned char c) { return static_cast<char>(std::tolower(c)); };
  std::string lowerBase = base;
  std::transform(lowerBase.begin(), lowerBase.end(), lowerBase.begin(), toLowerAscii);
  std::string lowerDesired = desired;
  std::transform(lowerDesired.begin(), lowerDesired.end(), lowerDesired.begin(), toLowerAscii);
  if (lowerBase.size() >= lowerDesired.size() &&
      lowerBase.compare(lowerBase.size() - lowerDesired.size(),
                        lowerDesired.size(), lowerDesired) == 0) {
    return base; // already good (without forcing another dot)
  }

  if (!base.empty() && base.back() == '.') {
    return base + ext;
  }
  return base + desired;
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
      L"OpenRaster (*.ora)\0*.ora\0"
      L"All Supported Images\0*.png;*.jpg;*.jpeg;*.bmp;*.gif;*.webp;*.ora\0";

  OPENFILENAMEW dialog = {};
  dialog.lStructSize = sizeof(dialog);
  dialog.lpstrFilter = filter;
  dialog.nFilterIndex = 1; // default PNG
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

  std::string resultPath = WideToUtf8(file_buffer.data());

  // Map the selected filter to a concrete extension and ensure the path has it.
  // This makes the "Save as type" choice determine the image format.
  std::string chosenExt;
  switch (dialog.nFilterIndex) {
    case 1: chosenExt = "png"; break;
    case 2: chosenExt = "jpg"; break;
    case 3: chosenExt = "bmp"; break;
    case 4: chosenExt = "gif"; break;
    case 5: chosenExt = "webp"; break;
    case 6: chosenExt = "ora"; break;
    case 7: {
      // "All Supported" — keep whatever extension the user typed, or default to png.
      size_t dot = resultPath.find_last_of('.');
      size_t sep = resultPath.find_last_of("/\\");
      bool hasExt = (dot != std::string::npos) &&
                    (sep == std::string::npos || dot > sep);
      if (!hasExt) {
        chosenExt = "png";
      }
      break;
    }
    default:
      break;
  }

  if (!chosenExt.empty()) {
    resultPath = EnsureExtension(resultPath, chosenExt);
  }

  return resultPath;
}
