
defmodule FinderTest do
  use ExUnit.Case

  @testfiles __DIR__ <> "/files/"

  test "creating a new Finder config" do
  	assert %Finder.Config{dir_regexes: [], file_endings: [], file_regexes: [], mode: :all, stats: false} == Finder.new()
  end 

  test "only files Finder config" do
  	assert %Finder.Config{mode: :files} == Finder.new() |> Finder.only_files()
  end 

  test "only directories Finder config" do
  	assert %Finder.Config{mode: :dirs} == Finder.new() |> Finder.only_directories()
  end

  test "files ending with Finder config" do
    config = Finder.new() |> Finder.with_file_endings([".foo", ".bar"])
    assert %Finder.Config{mode: :files, file_endings: [".foo", ".bar"]} == config
  end 

  test "find all files in directory" do
  	result = Finder.new()
          |> Finder.find(@testfiles)
          |> Enum.to_list
          |> Enum.sort
  	assert all_files_and_dirs() == result
  end

  test "find only files in directory" do
  	result = Finder.new()
          |> Finder.only_files()
          |> Finder.find(@testfiles)
          |> Enum.to_list
          |> Enum.sort
  	assert all_files() == result
  end

  test "find only directories in directory" do
  	result = Finder.new()
          |> Finder.only_directories()
          |> Finder.find(@testfiles)
          |> Enum.to_list
          |> Enum.sort
  	assert all_dirs == result
  end

  test "find nothing in not existing directory" do
  	result = Finder.new()
          |> Finder.only_directories()
          |> Finder.find(__DIR__ <> "/does-not-exist/")
          |> Enum.to_list
  	assert [] == result
  end
  
  test "find only files with .md ending" do
    result = Finder.new()
          |> Finder.with_file_endings([".md"])
          |> Finder.find(@testfiles)
          |> Enum.to_list
          |> Enum.sort
    assert prefix_list_with(["foo/bob.md", "foo/alice.md"], @testfiles) == result
  end

    test "find only files with .md and .txt ending" do
    result = Finder.new()
          |> Finder.with_file_endings([".md", ".txt", ".bar"])
          |> Finder.find(@testfiles)
          |> Enum.to_list
          |> Enum.sort
    assert prefix_list_with(["foo/bob.md", "foo/alice.md", "baz.txt"], @testfiles) == result
  end

  test "find only files with no given ending" do
    result = Finder.new()
          |> Finder.with_file_endings([])
          |> Finder.find(@testfiles)
          |> Enum.to_list
          |> Enum.sort
    assert all_files() == result
  end

  test "find only files with matching regex" do
    result = Finder.new()
          |> Finder.with_file_regex(Regex.compile!("^b")) # Only files starting with "b"
          |> Finder.only_files
          |> Finder.find(@testfiles)
          |> Enum.to_list
          |> Enum.sort
    assert prefix_list_with(["foo/bob.md", "baz.txt"], @testfiles) == result
  end

  test "find only dirs with matching regex" do
    result = Finder.new()
          |> Finder.with_directory_regex(Regex.compile!("^b")) # Only dirs starting with "b"
          |> Finder.only_directories
          |> Finder.find(@testfiles)
          |> Enum.to_list
          |> Enum.sort
    assert prefix_list_with(["bar"], @testfiles) == result
  end

  test "return file stats instead of path" do
    result = Finder.new()
          |> Finder.return_stats(true)
          |> Finder.find(@testfiles)
          |> Enum.to_list
          |> Enum.sort
    assert all_files_and_dirs() |> paths_to_stat == result
  end

  #--- Helper ---

  defp paths_to_stat(paths) do
    Enum.map(paths, fn(path) -> File.stat!(path) end) |> Enum.sort
  end

  defp prefix_list_with(list, prefix) do
    Enum.map(list, fn(name) -> prefix <> name end) |> Enum.sort
  end

  defp all_files_and_dirs() do
    all_dirs() ++ all_files() |> Enum.sort
  end

  defp all_files() do
    prefix_list_with(["baz.txt", "bar/.gitkeep", "foo/bob.md", "foo/alice.md"], @testfiles)
  end

  defp all_dirs() do
    prefix_list_with(["bar", "foo"], @testfiles)
  end

end
