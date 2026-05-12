# typed: false
# frozen_string_literal: true

# Homebrew formula for google_vision_cli
# Install with: brew tap cdavis-code/google-vision && brew install vision
class Vision < Formula
  desc "CLI tool for Google Vision API — image labeling, face/logo/landmark detection, OCR, and explicit content detection"
  homepage "https://github.com/cdavis-code/google_vision_workspace"
  version "2.0.0"
  license "MIT"

  # When a stable release tag exists, uncomment and update the stable block:
  # url "https://github.com/cdavis-code/google_vision_workspace/archive/refs/tags/v2.0.0.tar.gz"
  # sha256 "REPLACE_WITH_SHA256_OF_TAGGED_TARBALL"

  # Development / HEAD install: brew install --head vision
  head "https://github.com/cdavis-code/google_vision_workspace.git", branch: "main"

  depends_on "dart-sdk" => :build

  def install
    # Resolve workspace dependencies from the monorepo root
    system "dart", "pub", "get"

    # Compile the CLI entrypoint to a native binary
    system "dart", "compile", "exe",
           "packages/google_vision_cli/bin/vision.dart",
           "-o", "vision"

    bin.install "vision"
  end

  test do
    assert_match "vision", shell_output("#{bin}/vision --help")
  end
end
