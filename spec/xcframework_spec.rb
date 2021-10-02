RSpec.describe AppleFrameworks::XCFramework do
  let(:framework_name) { "framework_name" }
  let(:parent_directory) { Bundler.root.join("tmp", "framework_name") }
  let(:framework_paths) do
    [Bundler.root.join("spec", "fixtures" , "fake.framework")]
  end
  let(:described_instance) { described_class.new(framework_name, parent_directory, framework_paths) }

  describe "#build_using_xcode" do
    subject { described_instance.build_using_xcode }
    before { FileUtils.rm_rf(parent_directory) }
    after { FileUtils.rm_rf(parent_directory) }

    context "when there is already a framework in the parent_directory" do
      before do
        FileUtils.mkdir_p(File.join(parent_directory, "#{framework_name}.xcframework"))

        expect(File.directory?(parent_directory))
          .to eq(true)
      end

      it "raises an error" do
        expect { subject }
          .to raise_error("XCFramework already exists")
      end
    end

    context "when there is a file at the target parent_directory" do
      before do
        FileUtils.mkdir_p(parent_directory)
        FileUtils.touch(File.join(parent_directory, "#{framework_name}.xcframework"))

        expect(File.file?(File.join(parent_directory, "#{framework_name}.xcframework")))
          .to eq(true)
      end

      it "raises an error" do
        expect { subject }
          .to raise_error("File already exists at XCFramework destination")
      end
    end

    context "when there is an error from xcodebuild" do
      let(:framework_paths) do
        []
      end

      it "raises an error" do
        expect { subject }
          .to raise_error(
            AppleFrameworks::XCFramework::BuildUsingXcodeFailure,
            "error: at least one framework or library must be specified."
          )
      end
    end

    context "when there isn't a directory at parent_directory" do
      before do
        expect(File.directory?(parent_directory))
          .to eq(false)
      end

      it "creates the directory" do
        subject

        expect(File.directory?(parent_directory))
          .to eq(true)
      end

      it "copies the frameworks" do
        subject

        framework_library_path = Bundler.root.join("spec", "fixtures" , "fake.framework", "fake")
        xcframework_library_path = File.join(parent_directory, "#{framework_name}.xcframework", "macos-arm64", "fake.framework", "fake")
        a = Digest::MD5.hexdigest(File.read(framework_library_path))
        b = Digest::MD5.hexdigest(File.read(xcframework_library_path))

        expect(a).to eq(b)
      end

      it "creates a plist" do
        subject

        path = File.join(parent_directory, "#{framework_name}.xcframework", "Info.plist")

        expected_contents = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
            <key>AvailableLibraries</key>
            <array>
              <dict>
                <key>LibraryIdentifier</key>
                <string>macos-arm64</string>
                <key>LibraryPath</key>
                <string>fake.framework</string>
                <key>SupportedArchitectures</key>
                <array>
                  <string>arm64</string>
                </array>
                <key>SupportedPlatform</key>
                <string>macos</string>
              </dict>
            </array>
            <key>CFBundlePackageType</key>
            <string>XFWK</string>
            <key>XCFrameworkFormatVersion</key>
            <string>1.0</string>
          </dict>
          </plist>
        XML

        expect(File.read(path).gsub("\t", "  ")).to eq(expected_contents)
      end
    end
  end
end
