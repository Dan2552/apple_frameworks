module AppleFrameworks
  # Creates "fat" or "universal" libraries by combining two builds of the same
  # library with different architectures.
  #
  # Note: While it's possible (and used to be recommended) to make a fat library
  # for multiple platforms (iOS simulator and device), it's no longer
  # recommended to have these mixed in a single fat binary. For mixing
  # platforms, use `XCFramework`.
  #
  class Fat
    class CombineUsingLipoFailure < StandardError; end

    # - parameter output_path: The path of the resulting library.
    # - parameter library_paths: An array of paths to the static libraries
    #   (`.a` files).
    #
    def initialize(output_path, library_paths)
      @output_path = output_path
      @library_paths = library_paths
    end

    # Uses the `lipo -create` command to combine two or more libraries into a
    # single fat library.
    #
    def combine_using_lipo
      validations

      path_args = @library_paths.join(" ")

      cmd = "lipo #{path_args} -create -output #{@output_path}"

      logfile = Tempfile.new(['fat', '.log'])

      system("#{cmd} >#{logfile.path} 2>&1") ||
        raise(CombineUsingLipoFailure.new(File.read(logfile).strip.split(/\/.*\/lipo: /).last))
    ensure
      if logfile
        logfile.close
        logfile.delete
      end
    end

    private


    def validations
      if File.directory?(@output_path)
        raise "Directory already exists at Fat library output_path"
      end

      if File.file?(@output_path)
        raise "File already exists at Fat library output_path"
      end
    end
  end
end
