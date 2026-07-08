#ifndef RUNNER_NATIVE_SAVE_DIALOG_H_
#define RUNNER_NATIVE_SAVE_DIALOG_H_

#include <optional>
#include <string>

std::optional<std::string> ShowNativeSaveDialog(
    const std::string& file_name,
    const std::string& initial_directory,
    const std::string& dialog_title);

#endif  // RUNNER_NATIVE_SAVE_DIALOG_H_
