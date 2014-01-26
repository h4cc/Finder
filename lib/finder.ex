defmodule Finder do

    @moduledoc """
        This library is abled to list files from directories
        according to given parameters given via a fluent interface.

        Main idea is found here:
        http://symfony.com/doc/current/components/finder.html
    """

    @doc "Configuration. Will be evaluated in find/2."
    # This record is held public, so it could be stored and manipulated externally.
    # Maybe this is a not so good idea ...
    defrecord Config, mode: :all, file_endings: [], file_regexes: []

    @doc "Creates a new Finder Config with default values"
    def new() do
        Config.new()
    end

    @doc "Return only files"
    def only_files(config) when is_record(config, Config) do
        config.mode(:files)
    end

    @doc "Return only directories"
    def only_directories(config) when is_record(config, Config) do
        config.mode(:dirs)
    end

    @doc "Will find only files, with given file endings like '.exs'"
    def with_file_endings(config, endings) when is_record(config, Config) and is_list(endings) do
        config.file_endings(endings).mode(:files)
    end

    @doc "Add a regex any file name has to fit to."
    def with_file_regex(config, regex) when is_record(config, Config) and is_regex(regex) do
    #is_record(regex, Regex) do
        config.file_regexes(config.file_regexes ++ [regex])
    end

    @doc "Returns a stream of found files"
    def find(config, rootDir) when is_record(config, Config) do
        # Remove a possible trailing right slash.
        rootDir = String.rstrip(rootDir, ?/)
        # Perform search.
        search_in_directory(config, rootDir)
    end 

    #--- Private Functions ---

    # Perform the search starting in given directory.
    defp search_in_directory(config, dir) do
        case File.ls(dir) do
            # Create a stream for each path in list.
            { :ok, list } -> stream_path_list(config, dir, list)
            # Ignore errors so far.
            _ -> Stream.concat([[]])
        end
    end

    # Enum.map(list, &(dir <> "/" <> &1))

    # Returning a concatenation of streams for the given files and directories.
    defp stream_path_list(config, dir, list) do

        {files, dirs} = Enum.partition(list, &(File.dir?(dir <> "/" <> &1)))

        files = files
            |> filter_files_by_ending(config)
            |> filter_files_by_regex(config)
            # Prefix file with absolute path.
            |> Enum.map(&(dir <> "/" <> &1))

        dirs = dirs
            # Prefix dir with absolute path.
            |> Enum.map(&(dir <> "/" <> &1))

        streams = [files, dirs]
        if config.mode == :files do
            streams = [files]
        end
        if config.mode == :dirs do
            streams = [dirs]
        end
        Stream.concat(streams ++ [list_of_streams_for_dirs(config, dirs)])
    end

    # Creating a list of streams for each given directory.
    defp list_of_streams_for_dirs(config, dirs) do
        Stream.concat(
            Stream.unfold(
                dirs,
                fn
                    # Iterate through directories
                    [subDir | t] ->
                        {search_in_directory(config, subDir), t}
                    [] ->
                        nil
                end
            )
        )
    end

    # Do not filter if there are no defined regexes.
    defp filter_files_by_regex(files, Config[file_regexes: []]) do
        files
    end

    defp filter_files_by_regex(files, Config[file_regexes: regexes]) do
        # Filter all files that do not fit to any given regex.
        Enum.filter(
            files,
            # Try to find at least one regex that fits.
            fn file -> Enum.any?(regexes, &(Regex.match?(&1, file))) end
        )
    end 

    # Do not filter if there are no defined endings.
    defp filter_files_by_ending(files, Config[file_endings: []]) do
        files
    end

    defp filter_files_by_ending(files, Config[file_endings: endings]) do
        Enum.filter(files, &(String.ends_with?(&1, endings)))
    end 

    #--- not yet implemented functionality ---
    # Implement if you like to do :)

    #@doc "Adds paths to the config"
    #def inPath(config, path) when is_record(config, Config) do
    #    config.paths([path | config.paths])
    #end

    # @doc "Exclude directory"
    # def excludePath(config, path) when is_record(config, Config) do
    #     config.paths(['^'++path] ++ config.paths)
    # end

    # @doc "Adds a pattern for the file name to match"
    # def name(config, pattern) when is_record(config, Config) do
    #     config
    # end

    # @doc "Adds a pattern for files to exclude"
    # def notName(config, name) when is_record(config, Config) do
    #     config
    # end

end
