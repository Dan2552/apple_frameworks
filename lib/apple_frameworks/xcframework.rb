module AppleFrameworks
  # Creates an Apple (iOS or macOS) XCFramework from a set of existing
  # frameworks (`.framework`).
  #
  # XCFramework as a concept is newer than Frameworks. It was introduced due to
  # targets supporting more architectures. For example iOS Simulator now
  # supports the same architecture as iOS itself (arm64). Previously a Fat or
  # Universal Library could contain both x64 and arm64 architectures, thereby
  # supporting both simulator and real devices, but with the Fat format this
  # isn't possible anymore for arm64 and arm64. Enter XCFramework which simply
  # contains many frameworks of the same library but for different targets and
  # architectures.
  #
  # To create a `.framework` from a `.a` library, see
  # `AppleFrameworks::Framework`.
  #
  # The XCFramework is built up with a directory structure, including each
  # Framework for each individual target:
  #
  # ```
  # LibraryName.XCFramework
  #   Info.plist
  #   ios-arm64
  #     LibraryName.framework
  #   ios-x86_64-simulator
  #     LibraryName.framework
  # ```
  #
  class XCFramework
    class BuildUsingXcodeFailure < StandardError; end

    # - parameter framework_name: The name of the resulting XCFramework.
    # - parameter parent_directory: The directory in which to create the
    #   framework.
    # - parameter framework_paths: An array of paths to the `.framework`
    #   bundles.
    #
    def initialize(framework_name, parent_directory, framework_paths)
      @framework_name = framework_name
      @framework_paths = framework_paths
      @parent_directory = parent_directory

      @framework_directory = File.join(
        @parent_directory,
        "#{@framework_name}.xcframework"
      )
    end

    # Uses the `xcodebuild -create-xcframework` command to create the
    # XCFramework.
    #
    # This will require Xcode and its command line tools to be installed.
    #
    # Xcode has a couple of notable annoyances:
    #
    # * Fat binaries with multiple platforms (e.g. a single binary containing
    #   iOS simulator x64 and iOS arm64) are not supported.
    # * To include multiple architectures of the same platform (e.g. iOS
    #   simulator x64 and arm64), they first need to be combined as a Fat
    #   binary.
    #
    def build_using_xcode
      validations

      framework_args = @framework_paths
        .map { |path| "-framework #{path}" }
        .join(" ")

      FileUtils.mkdir_p(@parent_directory)
      output_path = File.join(@parent_directory, "#{@framework_name}.xcframework")
      output_args = "-output #{output_path}"

      logfile = Tempfile.new(['xcframework', '.log'])

      cmd = "xcodebuild -create-xcframework #{framework_args} #{output_args}"

      system("#{cmd} >#{logfile.path} 2>&1") ||
        raise(BuildUsingXcodeFailure.new(File.read(logfile).strip))
    ensure
      if logfile
        logfile.close
        logfile.delete
      end
    end

    private

    def validations
      if File.directory?(@framework_directory)
        raise "XCFramework already exists"
      end

      if File.file?(@framework_directory)
        raise "File already exists at XCFramework destination"
      end
    end
  end
end
