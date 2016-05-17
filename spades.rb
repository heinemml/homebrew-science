class Spades < Formula
  desc "SPAdes: de novo genome assembly"
  homepage "http://bioinf.spbau.ru/spades/"
  # tag "bioinformatics"
  # doi "10.1089/cmb.2012.0021"
  url "http://spades.bioinf.spbau.ru/release3.7.1/SPAdes-3.7.1.tar.gz"
  sha256 "e904f57b08c5790c64406763b29650ffba872da47ec5a3e659396fcfcbc9b35a"

  bottle do
    cellar :any
    sha256 "36d8ecf7aaa2a9ae1082404d613bb7f2a74e6105191f405c5c61875f7ab5d1f7" => :el_capitan
    sha256 "13bce60a596f206c649a3612c9fee84eee9f81a17a2c60f181211d23d10fe8a5" => :yosemite
    sha256 "a6b955e62b6824b45efa3784fdacf542c380573f0a83236043fa963cddfb951c" => :mavericks
  end

  depends_on "cmake" => :build

  needs :openmp

  fails_with :gcc => "4.7" do
    cause "Compiling SPAdes requires GCC >= 4.7 for OpenMP 3.1 support"
  end

  def install
    mkdir "src/build" do
      system "cmake", "..", *std_cmake_args
      system "make", "install"
    end

    # Fix audit error "Non-executables were installed to bin"
    inreplace bin/"spades_init.py" do |s|
      s.sub! /^/, "#!/usr/bin/env python\n"
    end
  end

  test do
    system "spades.py", "--test"
  end
end
