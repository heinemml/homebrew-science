class Gap < Formula
  desc "A system for computational discrete algebra"
  homepage "http://www.gap-system.org/"
  url "http://www.gap-system.org/pub/gap/gap48/tar.bz2/gap4r8p2_2016_02_20-18_51.tar.bz2"
  version "4.8.2"
  sha256 "8104f6936b6e6f7f8cf399b87da2ba968b5938f309e0ff94dbe6e02f50496ee5"

  bottle do
    cellar :any
    sha256 "61034dfb4e2e0ea7a7742ad5844ea1652a03269d6b5f9c7421fa5f8caee36d9c" => :el_capitan
    sha256 "89ca57099235158f60d90c3fdd8c6fa3b3805d11429cfafa14f66afec8fec65c" => :yosemite
    sha256 "def02768b4d712e86e76e07fe1c02ba089b9f13195e041fa1160b9356b75a325" => :mavericks
  end

  # NOTE:  the archive contains the [GMP library](http://gmplib.org) under
  #   `extern/`, which is not needed if it is already installed (for example,
  #   with Homebrew), and a number of GAP packages under `pkg/`, some of
  #   which need to be built.

  option "with-InstPackages",
         "Try to build included packages using InstPackages script"

  depends_on "gmp"
  # NOTE:  A version of [GMP](https://gmplib.org) is included in GAP archive
  #   under `extern/`, it is possible to use it instead of the brewed `gmp`.
  #   See http://www.gap-system.org/Download/INSTALL for details.

  depends_on "readline" => :recommended

  INST_PACKAGES_SCRIPT_URL = "http://www.gap-system.org/Download/InstPackages.sh"

  resource "script_that_builds_included_packages" do
    url INST_PACKAGES_SCRIPT_URL
    sha256 "8910cde7f5ab5ab46ea238a7712aa34d035cff3267704b6eadf307389294ecb2"
  end

  def install
    # Remove some useless files
    rm Dir["bin/*.bat", "bin/*.ico", "bin/*.bmp", "bin/cygwin.ver"]

    # Remove GMP archives (`gmp` formula is declared as a dependency)
    rm Dir["extern/gmp-*.tar.gz"]

    # XXX:  Currently there is no `install` target in `Makefile`.
    #   According to the manual installation instructions in
    #
    #     http://www.gap-system.org/Download/INSTALL ,
    #
    #   the compiled "bundle" is intended to be used "as is," and there is
    #   no instructions for how to remove the source and other unnecessary
    #   files after compilation.  Moreover, the content of the
    #   subdirectories with special names, such as `bin` and `lib`, is not
    #   suitable for merging with the content of the corresponding
    #   subdirectories of `/usr/local`.  The easiest temporary solution seems
    #   to be to drop the compiled bundle into `<prefix>/libexec` and to
    #   create a symlink `<prefix>/bin/gap` to the startup script.
    #   This use of `libexec` seems to contradict Linux Filesystem Hierarchy
    #   Standard, but is recommended in Homebrew's "Formula Cookbook."

    args = %W[--prefix=#{libexec} --with-gmp=system]

    args << "--#{build.with?("readline") ? "with" : "without"}-readline"
    # NOTE: `--with-readline` is the default, it is included for clarity

    system "./configure", *args

    # Fix a bug caused by the buggy `configure` which does not respect
    # `--prefix` when generating the startup script: the variable `GAP_DIR`
    # is being set to the (temporary) build directory, but should be set to
    # the value of `--prefix` option.
    ["bin/gap-default32.sh", "bin/gap-default64.sh"].each do |startup_script|
      next unless File.exist?(startup_script)
      inreplace startup_script, /^GAP_DIR="[^"]*"$/,
                                        "GAP_DIR=\"#{libexec}\""
    end

    system "make"

    libexec.install Dir["*"]

    # Create a symlink `bin/gap` from the symlink `gap.sh`
    cd libexec/"bin" do
      # NOTE: the symbolic link `gap.sh` is (or may be) relaive
      bin.install_symlink File.expand_path(`readlink -n gap.sh`) => "gap"
    end

    if build.with? "InstPackages"
      ohai "Trying to automatically build included packages"

      resource("script_that_builds_included_packages").stage do
        chmod "u+x", "InstPackages.sh"
        (libexec/"pkg").install "InstPackages.sh"
      end

      cd libexec/"pkg" do
        # NOTE:  running this script is known to produce a number of error
        #   messages, possibly failing to build certain packages
        system "./InstPackages.sh"
      end
    end
  end

  # XXX:  `brew info` displays the caveats according to the options it is
  #   given, not according to the options with which the formula is installed
  def caveats
    if build.without?("InstPackages")
      <<-EOS.undent
        If the formula is installed without the `--with-InstPackages' option,
        some packages in:
          #{libexec/"pkg"}
        will need to be built manually with the following script:
          #{INST_PACKAGES_SCRIPT_URL}
        See the Section 7 of #{libexec/"INSTALL"} for more info.
      EOS
    else
      <<-EOS.undent
        When the formula is installed with the `--with-InstPackages' option,
        some packages in
          #{libexec/"pkg"}
        are automatically built using the following script:
          #{INST_PACKAGES_SCRIPT_URL}
        However, this script is known to produce a number of error messages,
        and thus it might have failed to build certain packages.
      EOS
    end
  end

  test do
    File.open("test_input.g", "w") do |f|
      f.write <<-EOS.undent
        Print(Factorial(3), "\\n");
        Print(IsDocumentedWord("IsGroup"), "\\n");
        Print(IsDocumentedWord("MakeGAPDocDoc"), "\\n");
        QUIT;
      EOS
    end
    test_output = `#{bin/"gap"} -b test_input.g`
    assert_equal 0, $?.exitstatus
    expected_output =
      <<-EOS.undent
        6
        true
        true
      EOS
    assert_equal expected_output, test_output
  end
end
