defmodule Controllers.FilesControllerTest do
  # async: false — these tests set the global :directory app env.
  use ExUnit.Case, async: false

  alias Controllers.FilesController
  alias Protocol.{HTTPRequest, HTTPResponse}

  setup do
    dir = Path.join(System.tmp_dir!(), "files_controller_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    previous = Application.get_env(:codecrafters_http_server, :directory)
    Application.put_env(:codecrafters_http_server, :directory, dir)

    on_exit(fn ->
      File.rm_rf!(dir)

      if previous do
        Application.put_env(:codecrafters_http_server, :directory, previous)
      else
        Application.delete_env(:codecrafters_http_server, :directory)
      end
    end)

    {:ok, dir: dir}
  end

  defp read_request(target) do
    %HTTPRequest{line: %{method: "GET", target: target, version: "HTTP/1.1"}, headers: %{}}
  end

  defp write_request(target, body) do
    %HTTPRequest{
      line: %{method: "POST", target: target, version: "HTTP/1.1"},
      headers: %{},
      body: body
    }
  end

  defp body(response) do
    [_head, body] = :binary.split(response, "\r\n\r\n")
    body
  end

  describe "read/1" do
    test "returns the file contents as an octet stream", %{dir: dir} do
      File.write!(Path.join(dir, "hello.txt"), "file-contents")

      assert {:ok, response} = FilesController.read(read_request("/files/hello.txt"))
      assert HTTPResponse.status_code(response) == "200"
      assert response =~ "Content-Type: application/octet-stream"
      assert body(response) == "file-contents"
    end

    test "returns 404 when the file does not exist" do
      assert {:ok, response} = FilesController.read(read_request("/files/missing.txt"))
      assert HTTPResponse.status_code(response) == "404"
    end
  end

  describe "write/1" do
    test "creates the file and returns 201", %{dir: dir} do
      assert {:ok, response} = FilesController.write(write_request("/files/new.txt", "payload"))
      assert HTTPResponse.status_code(response) == "201"
      assert File.read!(Path.join(dir, "new.txt")) == "payload"
    end

    test "returns an error response when the file cannot be written" do
      # The parent directory does not exist, so File.write fails.
      assert {:error, response} =
               FilesController.write(write_request("/files/missing-dir/x.txt", "data"))

      assert HTTPResponse.status_code(response) == "404"
    end
  end
end
