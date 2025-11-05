#include <fstream>
#include <iostream>

int main(int argc, char* argv[]) {
  if (argc != 2) {
    std::cerr << "Usage: " << argv[0] << " <output_file>" << std::endl;
    return 1;
  }

  std::ofstream outfile(argv[1]);
  if (!outfile) {
    std::cerr << "Error: Could not open file " << argv[1] << " for writing." << std::endl;
    return 1;
  }

  outfile << "HI THERE";
  outfile.close();

  return 0;
}
