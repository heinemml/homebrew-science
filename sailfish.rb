class Sailfish < Formula
  desc "Rapid mapping-based RNA-Seq isoform quantification"
  homepage "http://www.cs.cmu.edu/~ckingsf/software/sailfish"
  # doi "10.1038/nbt.2862"
  # tag "bioinformatics"
  url "https://github.com/kingsfordgroup/sailfish/archive/v0.9.2.tar.gz"
  sha256 "4872c5241864ae12a3aa5e519cf6d2d38d0e510bfcfd420c8d05249f7ee83f82"

  bottle do
    sha256 "cc870770c98a55fafb75ceb80ec4eec18be196c165060eabf1366a87359b8fa9" => :el_capitan
    sha256 "4b2e5b0a77b261622374cb2a82b484e79a6a706705e83b89f4094938127ff9a0" => :yosemite
    sha256 "988822bf7f6af7a72320a1f7c4d875e39f0013742667cd92a4d779f1d9a4cbc9" => :mavericks
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "boost"
  depends_on "cmake" => :build
  depends_on "tbb"
  needs :cxx11

  def install
    ENV.deparallelize
    mkdir "build" do
      system "cmake", "..", *std_cmake_args
      system "make", "install"
    end
  end

  test do
    system "#{bin}/sailfish", "--version"
  end
end
