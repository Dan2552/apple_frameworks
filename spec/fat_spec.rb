RSpec.describe AppleFrameworks::Fat do
  let(:output_path) { Bundler.root.join("tmp", "fat") }
  let(:library_paths) do
    [
      Bundler.root.join("spec", "fixtures", "fake.a"),
      Bundler.root.join("spec", "fixtures", "fake-x64.a")
    ]
  end
  let(:described_instance) { described_class.new(output_path, library_paths) }

  describe "#combine_using_lipo" do
    subject { described_instance.combine_using_lipo }
    before { FileUtils.rm_rf(output_path) }
    after { FileUtils.rm_rf(output_path) }

    context "when there is already a directory in the parent_directory" do
      before do
        FileUtils.mkdir_p(File.join(output_path))

        expect(File.directory?(output_path))
          .to eq(true)
      end

      it "raises an error" do
        expect { subject }
          .to raise_error("Directory already exists at Fat library output_path")
      end
    end

    context "when there is a file at the target parent_directory" do
      before do
        FileUtils.mkdir_p(Bundler.root.join("tmp"))
        FileUtils.touch(output_path)

        expect(File.file?(output_path))
          .to eq(true)
      end

      it "raises an error" do
        expect { subject }
          .to raise_error("File already exists at Fat library output_path")
      end
    end

    context "when there is an error from lipo" do
      let(:library_paths) do
        ["doesnt_exist"]
      end

      it "raises an error" do
        expect { subject }
          .to raise_error(
            AppleFrameworks::Fat::CombineUsingLipoFailure,
            "can't open input file: doesnt_exist (No such file or directory)"
          )
      end
    end

    context "when there isn't a file or directory at output_path" do
      before do
        expect(File.directory?(output_path))
          .to eq(false)

        expect(File.file?(output_path))
          .to eq(false)
      end

      it "creates the fat library" do
        subject

        expect(File.file?(output_path))
          .to eq(true)

        expect(`lipo -info #{output_path}`.strip)
          .to end_with("are: x86_64 arm64")
      end
    end
  end
end
