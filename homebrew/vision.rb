# typed: false
# frozen_string_literal: true

# Homebrew formula for google_vision_cli
# Install with: brew tap cdavis-code/google-vision && brew install vision
class Vision < Formula
  desc "CLI tool for Google Vision API — image labeling, face/logo/landmark detection, OCR, and explicit content detection"
  homepage "https://github.com/cdavis-code/google_vision_workspace"
  version "2.0.1"
  license "MIT"

  url "https://github.com/cdavis-code/google_vision_workspace/archive/refs/tags/v2.0.1.tar.gz"
  sha256 "7191cd1b7d6a2b7470993728b0cbd39e696888a310addf2aeb3afaaa00082db3"

  # Development / HEAD install: brew install --head vision
  head "https://github.com/cdavis-code/google_vision_workspace.git", branch: "main"

  depends_on "dart-sdk" => :build

  def install
    # Build from the package directory with standalone resolution
    cd "packages/google_vision_cli" do
      # Remove workspace resolution to build standalone (avoids Flutter dep in google_vision_flutter)
      inreplace "pubspec.yaml", "resolution: workspace\n", ""

      system "dart", "pub", "get"

      # Compile the CLI entrypoint to a native binary
      system "dart", "compile", "exe",
             "bin/vision.dart",
             "-o", "vision"

      bin.install "vision"
    end
  end

  test do
    assert_match "vision", shell_output("#{bin}/vision --help")
  end
end
