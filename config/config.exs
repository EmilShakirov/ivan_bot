use Mix.Config

# config :quantum, cron: [
#     # Every minute
#     "45 10 * * *": &Alice.Handlers.Standup.notify/0,
# ]

case Mix.env do
  env when env in [:prod, :dev] -> import_config "#{env}.exs"
  _other                        -> import_config "other.exs"
end
