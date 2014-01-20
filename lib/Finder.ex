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
    defrecord Config, mode: :all

    @doc "Creates a new Finder Config with default values"
    def new() do
        Config.new()
    end

    # @doc "Return only files"
    def onlyFiles(config) when is_record(config, Config) do
        config.mode(:files)
    end

    # @doc "Return only directories"
    def onlyDirectories(config) when is_record(config, Config) do
        config.mode(:dirs)
    end

    @doc "Returns a stream of found files"
    def find(config, rootDir) when is_record(config, Config) do
        # Remove a possible trailing right slash.
        rootDir = String.rstrip(rootDir, ?/)
        # 
        searchInDirectory(config, rootDir)
    end 

    #--- Private Functions ---

    # Perform the search starting in given directory.
    defp searchInDirectory(config, dir) do
        case File.ls(dir) do
            # Create a stream for each path in list.
            { :ok, list } -> streamPathList(config, Enum.map(list, &(dir <> "/" <> &1)))
            # Ignore errors so far.
            _ -> []
        end
    end

    # Returning a concatenation of streams for the given files and directories.
    defp streamPathList(config, list) do
        files = Enum.filter(list, &(!File.dir?(&1)))
        dirs = Enum.filter(list, &(File.dir?(&1)))
        streams = [files, dirs]
        if config.mode == :files do
            streams = [files]
        end
        if config.mode == :dirs do
            streams = [dirs]
        end
        Stream.concat(streams ++ [listOfStreamsForDirs(config, dirs)])
    end

    # Creating a list of streams for each given directory.
    defp listOfStreamsForDirs(config, dirs) do
        Stream.concat(
            Stream.unfold(
                dirs,
                fn 
                    # Iterate through directories
                    [subDir | t] ->
                        {searchInDirectory(config, subDir), t}
                    [] ->
                        nil
                end
            )
        )
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
