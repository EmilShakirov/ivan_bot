defmodule AclIvanBot.Constants do
  @moduledoc false

  defmacro projects_list do
    quote do: ~w(projects results risks)
  end

  defmacro projects_ids do
    quote do: ~w(U32FGC7UG U334YACBV U3373TYHY U33ST9YLW U33T52M5M)
  end

  defmacro results_ids do
    quote do: ~w(U32FL6RS4 U39S2MMJ5)
  end

  defmacro risks_ids do
    quote do: ~w(U3356MZGT U33TFH5ST)
  end

  defmacro all_user_ids do
    quote do: unquote(projects_ids ++ results_ids ++ risks_ids)
  end
end
