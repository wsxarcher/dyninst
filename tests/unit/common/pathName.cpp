#include "common/src/pathName.h"

#include <array>
#include <boost/filesystem.hpp>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <string>

int main() {
  auto home = []() -> std::string {
    auto* h = getenv("HOME");
    if(!h) {
      return {};
    }
    return h;
  }();

  if(home.empty()) {
    std::cerr << "Didn't find 'HOME' in environment\n";
    return EXIT_FAILURE;
  }

  auto user = []() -> std::string {
    auto* h = getenv("USER");
    if(!h) {
      return {};
    }
    return h;
  }();

  if(user.empty()) {
    std::cerr << "Didn't find 'USER' in environment\n";
    return EXIT_FAILURE;
  }

  struct test {
    std::string input;
    std::string expected;
  };

  std::string const test_file{"/test1"};
  std::string const test_file_path{home + test_file};

  // Make sure we have a test file
  {
    std::ofstream fout(home + test_file);
    fout << "\n";
  }

  // clang-format off
  const std::array<test, 6> tests = {{
    {"~", home},
    {"~//", home},
    {"~/" + test_file, test_file_path},
    {home, home},
    {"~" + user, home},
    {"~" + user + test_file, test_file_path},
  }};
  // clang-format on

  bool failed = false;
  auto test_id = 1;

  for(auto t : tests) {
    auto fp = resolve_file_path(t.input);
    if(fp != t.expected) {
      std::cerr << "Test " << test_id << " '" << t.input << "' failed: expected '"
                << t.expected << "', got '" << fp << "'\n";
      failed = true;
    }
    test_id++;
  }

  namespace bf = boost::filesystem;
  bf::remove(bf::path(test_file_path));

  return (failed) ? EXIT_FAILURE : EXIT_SUCCESS;
}
