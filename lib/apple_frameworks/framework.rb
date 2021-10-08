module AppleFrameworks
  # Creates an Apple (iOS or macOS) Framework from an existing library (`.a`
  # file).
  #
  # The Framework is built up with a directory structure:
  #
  # ```
  # LibraryName.Framework
  #   Info.plist
  #   library_name (the actual static lib)
  #   Headers
  #     library_name
  #       (all the headers)
  # ```
  #
  class Framework
    # - parameter framework_name: The name of the resulting framework.
    # - parameter parent_directory: The directory in which to create the
    #   framework.
    # - parameter library: The library itself; the `.a` file.
    # - parameter headers_directory: The directory which includes the headers.
    #   Normally located in the `include/` directory.
    #
    def initialize(framework_name, parent_directory, library, headers_directory)
      @framework_name = framework_name
      @parent_directory = parent_directory
      @library = library
      @headers_directory = headers_directory

      @framework_directory = File.join(
        @parent_directory,
        "#{@framework_name}.framework"
      )
    end

    # Generates the `.framework` bundle.
    #
    def build
      create_directories
      copy_lib
      copy_headers
      generate_plist
    end

    private

    def create_directories
      if File.directory?(@framework_directory)
        raise "Framework already exists"
      end

      if File.file?(@framework_directory)
        raise "File already exists at Framework destination"
      end

      FileUtils.mkdir_p(File.join(@framework_directory, "Headers"))
    end

    def copy_lib
      FileUtils.cp(@library, File.join(@framework_directory, @framework_name))
    end

    def copy_headers
      FileUtils.cp_r(File.join(@headers_directory), File.join(@framework_directory, "Headers", @framework_name))
    end

    def generate_plist
      filepath = File.join(@framework_directory, "Info.plist")

      plist_contents = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>CFBundleName</key>
          <string>#{@framework_name}</string>
          <key>CFBundleDevelopmentRegion</key>
          <string>en</string>
          <key>CFBundleInfoDictionaryVersion</key>
          <string>6.0</string>
          <key>CFBundlePackageType</key>
          <string>FMWK</string>
          <key>CFBundleIdentifier</key>
          <string>#{@framework_name}.#{@framework_name}</string>
          <key>CFBundleExecutable</key>
          <string>#{@framework_name}</string>
          <key>CFBundleVersion</key>
          <string>1</string>
        </dict>
        </plist>
      XML

      File.open(filepath, "w") { |file| file.puts(plist_contents) }
    end
  end
end
