ExUnit.start()

defmodule ExUnit.TestHelpers do
  def load_fixture(file_or_path) do
    {:ok, work_dir} = File.cwd
    File.read!("#{work_dir}/test/fixtures/#{file_or_path}")
  end
end
