
defmodule FinderTest do
  use ExUnit.Case, async: true

  @testfiles __DIR__ <> "/files/"

  test "creating a new Finder config" do
  	assert Finder.Config[mode: :all] == Finder.new()
  end 

  test "only files Finder config" do
  	assert Finder.Config[mode: :files] == Finder.new() |> Finder.onlyFiles()
  end 

  test "only directories Finder config" do
  	assert Finder.Config[mode: :dirs] == Finder.new() |> Finder.onlyDirectories()
  end

  test "files ending with Finder config" do
    config = Finder.new() |> Finder.withFileEndings([".foo", ".bar"])
    assert Finder.Config[mode: :files, file_endings: [".foo", ".bar"]] == config
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
          |> Finder.onlyFiles()
          |> Finder.find(@testfiles)
          |> Enum.to_list
          |> Enum.sort
  	assert all_files() == result
  end

  test "find only directories in directory" do
  	result = Finder.new()
          |> Finder.onlyDirectories()
          |> Finder.find(@testfiles)
          |> Enum.to_list
          |> Enum.sort
  	assert all_dirs == result
  end

  test "find nothing in not existing directory" do
  	result = Finder.new()
          |> Finder.onlyDirectories()
          |> Finder.find(__DIR__ <> "/does-not-exist/")
          |> Enum.to_list
  	assert [] == result
  end
  
  test "find only files with .md ending" do
    result = Finder.new()
          |> Finder.withFileEndings([".md"])
          |> Finder.find(@testfiles)
          |> Enum.to_list
          |> Enum.sort
    assert prefix_list_with(["foo/bob.md", "foo/alice.md"], @testfiles) == result
  end

    test "find only files with .md and .txt ending" do
    result = Finder.new()
          |> Finder.withFileEndings([".md", ".txt", ".bar"])
          |> Finder.find(@testfiles)
          |> Enum.to_list
          |> Enum.sort
    assert prefix_list_with(["foo/bob.md", "foo/alice.md", "baz.txt"], @testfiles) == result
  end

  test "find only files with no given ending" do
    result = Finder.new()
          |> Finder.withFileEndings([])
          |> Finder.find(@testfiles)
          |> Enum.to_list
          |> Enum.sort
    assert all_files() == result
  end

  #--- Helper ---

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
