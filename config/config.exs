use Mix.Config

case Mix.env do
  env when env in [:prod, :dev] -> import_config "#{env}.exs"
  _other                        -> import_config "other.exs"
end
