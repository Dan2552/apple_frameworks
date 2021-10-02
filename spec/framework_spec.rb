RSpec.describe AppleFrameworks::Framework do
  let(:framework_name) { "framework_name" }
  let(:parent_directory) { Bundler.root.join("tmp", "framework_name") }
  let(:library) { Bundler.root.join("spec", "fixtures", "fake.a") }
  let(:headers_directory) { Bundler.root.join("spec", "fixtures", "headers") }
  let(:described_instance) { described_class.new(framework_name, parent_directory, library, headers_directory) }

  describe "#build" do
    subject { described_instance.build }
    before { FileUtils.rm_rf(parent_directory) }
    after { FileUtils.rm_rf(parent_directory) }

    context "when there is already a framework in the parent_directory" do
      before do
        FileUtils.mkdir_p(File.join(parent_directory, "#{framework_name}.framework"))

        expect(File.directory?(parent_directory))
          .to eq(true)
      end

      it "raises an error" do
        expect { subject }
          .to raise_error("Framework already exists")
      end
    end

    context "when there is a file at the target parent_directory" do
      before do
        FileUtils.mkdir_p(parent_directory)
        FileUtils.touch(File.join(parent_directory, "#{framework_name}.framework"))

        expect(File.file?(File.join(parent_directory, "#{framework_name}.framework")))
          .to eq(true)
      end

      it "raises an error" do
        expect { subject }
          .to raise_error("File already exists at Framework destination")
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

      it "copies the library" do
        subject

        expected_library_path = File.join(parent_directory, "#{framework_name}.framework", framework_name)
        a = Digest::MD5.hexdigest(File.read(library))
        b = Digest::MD5.hexdigest(File.read(expected_library_path))

        expect(a).to eq(b)
      end

      it "copies the headers" do
        subject

        a1 = File.join(headers_directory, "a.h")
        b1 = File.join(headers_directory, "b.h")

        a2 = File.join(parent_directory, "#{framework_name}.framework", "Headers", framework_name, "a.h")
        b2 = File.join(parent_directory, "#{framework_name}.framework", "Headers", framework_name, "b.h")

        expect(File.read(a1)).to eq(File.read(a2))
        expect(File.read(b1)).to eq(File.read(b2))
      end

      it "creates a plist" do
        subject

        path = File.join(parent_directory, "#{framework_name}.framework", "Info.plist")

        expected_contents = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
            <key>CFBundleName</key>
            <string>framework_name</string>
            <key>CFBundleDevelopmentRegion</key>
            <string>en</string>
            <key>CFBundleInfoDictionaryVersion</key>
            <string>6.0</string>
            <key>CFBundlePackageType</key>
            <string>FMWK</string>
            <key>CFBundleIdentifier</key>
            <string>framework_name.framework_name</string>
            <key>CFBundleExecutable</key>
            <string>framework_name</string>
            <key>CFBundleVersion</key>
            <string>1</string>
          </dict>
          </plist>
        XML

        expect(File.read(path)).to eq(expected_contents)
      end
    end
  end
end
