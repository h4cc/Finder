
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

  test "find all files in directory" do
  	expectedFiles = prefix_list_with(["baz.txt", "bar", "foo", "bar/.gitkeep", "foo/bob.md", "foo/alice.md"], @testfiles)
  	stream = Finder.new() |> Finder.find(@testfiles)
  	assert Enum.sort(expectedFiles) == Enum.sort(Enum.to_list(stream))
  end

  test "find only files in directory" do
  	expectedFiles = prefix_list_with(["baz.txt", "bar/.gitkeep", "foo/bob.md", "foo/alice.md"], @testfiles)
  	stream = Finder.new() |> Finder.onlyFiles() |> Finder.find(@testfiles)
  	assert Enum.sort(expectedFiles) == Enum.sort(Enum.to_list(stream))
  end

  test "find only directories in directory" do
  	expectedFiles = prefix_list_with(["bar", "foo"], @testfiles)
  	stream = Finder.new() |> Finder.onlyDirectories() |> Finder.find(@testfiles)
  	assert Enum.sort(expectedFiles) == Enum.sort(Enum.to_list(stream))
  end

  test "find nothing in not existing directory" do
  	stream = Finder.new() |> Finder.onlyDirectories() |> Finder.find(__DIR__ <> "/does-not-exist/")
  	assert [] == Enum.to_list(stream)
  end
  
  defp prefix_list_with(list, prefix) do
    Enum.map(list, fn(name) -> prefix <> name end)
  end

end
