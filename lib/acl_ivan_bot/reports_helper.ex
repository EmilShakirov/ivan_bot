defmodule AclIvanBot.ReportsHelper do
  def fetch_name(users, user_id) do
    users
    |> get_in([user_id, :profile, :first_name])
    |> to_string
    |> case do
        "" -> get_in(users, [user_id, :name])
        name -> name
      end
    |> to_string
    |> String.upcase
  end
end
