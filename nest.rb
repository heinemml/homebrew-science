class Nest < Formula
  desc "The Neural Simulation Tool"
  homepage "http://www.nest-simulator.org/"
  url "https://github.com/nest/nest-simulator/releases/download/v2.10.0/nest-2.10.0.tar.gz"
  sha256 "2b6fc562cd6362e812d94bb742562a5a685fb1c7e08403765dbe123d59b0996c"

  head "https://github.com/nest/nest-simulator.git"

  bottle do
    sha256 "ad44e8f56407a055bb78174df407b6941b2152c1286e6ba68594a0908919baff" => :el_capitan
    sha256 "37edaf1a7296d0f925fcf4f6f2bc989d3b2bae9355aec64b8da5b21a458bef78" => :yosemite
    sha256 "4109d97bacd320b3c40ba738122af044a305a4703200e89b2e2005dbcc5a629b" => :mavericks
  end

  option "with-python", "Build Python bindings (PyNEST)."
  option "without-openmp", "Build without OpenMP support."
  needs :openmp if build.with? "openmp"

  depends_on "gsl" => :recommended
  depends_on :mpi => [:optional, :cc, :cxx]
  depends_on :python => :optional if MacOS.version <= :snow_leopard
  depends_on "numpy" => :python if build.with? "python"
  depends_on "scipy" => :python if build.with? "python"
  depends_on "matplotlib" => :python if build.with? "python"
  depends_on "cython" => :python if build.with? "python"
  depends_on "libtool" => :run
  depends_on "readline" => :run
  depends_on "autoconf" => :build
  depends_on "automake" => :build

  fails_with :clang do
    cause <<-EOS.undent
      Building NEST with clang is not stable. See https://github.com/nest/nest-simulator/issues/74 .
    EOS
  end

  def install
    args = ["--disable-debug",
            "--disable-dependency-tracking",
            "--prefix=#{prefix}",
           ]

    if build.with? "mpi"
      # change CC / CXX in open-mpi
      ENV["OMPI_CC"] = ENV["CC"]
      ENV["OMPI_CXX"] = ENV["CXX"]

      # change CC / CXX in mpich
      ENV["MPICH_CC"] = ENV["CC"]
      ENV["MPICH_CXX"] = ENV["CXX"]

      args << "CC=#{ENV["MPICC"]}"
      args << "CXX=#{ENV["MPICXX"]}"
      args << "--with-mpi"
    end

    args << "--without-openmp" if build.without? "openmp"
    args << "--without-gsl" if build.without? "gsl"
    args << "--without-python" if build.without? "python"

    # "out of source" build
    mkdir "build" do
      system "../configure", *args
      # adjust src and bld path
      inreplace "../sli/slistartup.cc", /PKGSOURCEDIR/, "\"#{pkgshare}/sources\""
      inreplace "libnestutil/sliconfig.h", /#define SLI_BUILDDIR .*/, "#define SLI_BUILDDIR \"#{pkgshare}/sources/build\""
      # do not re-generate .hlp during /validate (tries to regenerate from
      # not existing source file)
      inreplace "../lib/sli/helpinit.sli", /^ makehelp$/, "% makehelp"
      system "make"
      system "make", "install"
    end

    # install sources for later testing
    mkdir pkgshare/"sources"
    (pkgshare/"sources").install Dir["./*"]
  end

  test do
    # simple check whether NEST was compiled & linked
    system bin/"nest", "--version"

    # necessary for the python tests
    ENV["exec_prefix"] = prefix
    # necessary for one regression on the sources
    ENV["NEST_SOURCE"] = pkgshare/"sources"

    if build.with? "mpi"
      # we need the command /mpirun defined for the mpi tests
      # and since we are in the sandbox, we create it again
      nestrc = %{
        /mpirun
        [/integertype /stringtype]
        [/numproc     /slifile]
        {
         () [
          (mpirun -np ) numproc cvs ( ) statusdict/prefix :: (/bin/nest )  slifile
         ] {join} Fold
        } Function def
      }
      File.open(ENV["HOME"]+"/.nestrc", "w") { |file| file.write(nestrc) }
    end

    # run all tests
    args = []
    args << "--test-pynest" if build.with? "python"
    system pkgshare/"extras/do_tests.sh", *args
  end
end
