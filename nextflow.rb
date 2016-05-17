class Nextflow < Formula
  desc "Data-driven computational pipelines"
  homepage "http://www.nextflow.io/"
  # doi "10.6084/m9.figshare.1254958"
  # tag "bioinformatics"

  url "http://www.nextflow.io/releases/v0.18.2/nextflow"
  version "0.18.2"
  sha256 "1e372c25217f7fad759ae499225302fc43c68dbfe1103dac2e5520d363de3227"

  head "https://github.com/nextflow-io/nextflow.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "4fed11f4576ac92ec7c2862adeca0b4197ee5a0e4d0862b3e1c0a11f26b0764c" => :el_capitan
    sha256 "9f4b279175b1ae157e91c92cdee6f2337a64cd51295600a5bbd4f8a9cb01bccc" => :yosemite
    sha256 "89a5f3b1b998b609399720d6e57234e8e10e119b93a9732979ba91010e724bad" => :mavericks
  end

  depends_on :java => "1.7+"

  def install
    bin.install "nextflow"
  end

  test do
    system "#{bin}/nextflow", "-download"
    system "echo", "println \'hello\' | #{bin}/nextflow -q run - |grep hello"
  end
end
