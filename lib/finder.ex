defmodule Finder do

    @moduledoc """
        This library is abled to list files from directories
        according to given parameters given via a fluent interface.

        Main idea is found here:
        http://symfony.com/doc/current/components/finder.html
    """

    alias Finder.Config, as: Config

    @doc "Creates a new Finder Config with default values"
    def new() do
        %Config{}
    end

    @doc "Return only files"
    def only_files(%Config{} = config) do
        %Config{config | mode: :files}
    end

    @doc "Return only directories"
    def only_directories(%Config{} = config) do
        %Config{config | mode: :dirs}
    end

    @doc "Will find only files, with given file endings like '.exs'"
    def with_file_endings(%Config{} = config, endings) when is_list(endings) do
        %Config{config | mode: :files, file_endings: endings}
    end

    @doc "Add a regex any file name has to fit to."
    def with_file_regex(%Config{file_regexes: regexes} = config, regex) do
      if Regex.regex?(regex) do
        %Config{config | file_regexes: regexes ++ [regex]}
      else
        config
      end
    end

    @doc "Add a regex any dir name has to fit to."
    def with_directory_regex(%Config{dir_regexes: regexes} = config, regex) do
      if Regex.regex?(regex) do
        %Config{config | dir_regexes: regexes ++ [regex]}
      else
        config
      end
    end

    @doc "Return File.Stat instead of the paths"
    def return_stats(%Config{} = config, flag) when is_boolean(flag) do
        %Config{config | stats: flag}
    end

    @doc "Returns a stream of found files"
    def find(config, rootDir) do
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

    # Returning a concatenation of streams for the given files and directories.
    defp stream_path_list(config, dir, list) do

        # Split to dirs and files.
        {dirs, files} = Enum.partition(list, &(File.dir?(dir <> "/" <> &1)))

        # Filter files.
        files = files
            |> filter_files_by_ending(config)
            |> filter_files_by_regex(config)
            |> Enum.map(&(dir <> "/" <> &1))    # Prefix file with absolute path.

        # Filter dirs.
        dirs = dirs
            |> filter_dirs_by_regex(config)
            |> Enum.map(&(dir <> "/" <> &1))    # Prefix dir with absolute path.

        # Apply mode.
        streams = [files, dirs]
        if config.mode == :files do
            streams = [files]
        end
        if config.mode == :dirs do
            streams = [dirs]
        end

        # Global filter of dirs and files.
        streams = streams
            |> Enum.map(&(get_file_stats(&1, config)))

        Stream.concat(streams ++ [list_of_streams_for_dirs(config, dirs)])
    end

    # Not returning stats.
    defp get_file_stats(paths, %Config{:stats => false}) do
        paths
    end

    # Return stats.
    defp get_file_stats(paths, %Config{:stats => true}) do
        Enum.map(paths, &(File.stat!(&1)))
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
    defp filter_dirs_by_regex(dirs, %{:dir_regexes => []}) do
        dirs
    end

    defp filter_dirs_by_regex(dirs, %{:dir_regexes => regexes}) do
        # Filter all dirs that do not fit to any given regex.
        Enum.filter(
            dirs,
            # Try to find at least one regex that fits.
            fn dir -> Enum.any?(regexes, &(Regex.match?(&1, dir))) end
        )
    end

    # Do not filter if there are no defined regexes.
    defp filter_files_by_regex(files, %{:file_regexes => []}) do
        files
    end

    defp filter_files_by_regex(files, %{:file_regexes => regexes}) do
        # Filter all files that do not fit to any given regex.
        Enum.filter(
            files,
            # Try to find at least one regex that fits.
            fn file -> Enum.any?(regexes, &(Regex.match?(&1, file))) end
        )
    end

    # Do not filter if there are no defined endings.
    defp filter_files_by_ending(files, %{:file_endings => []}) do
        files
    end

    defp filter_files_by_ending(files, %{:file_endings => endings}) do
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
