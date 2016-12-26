use Mix.Config

config :alice,
  api_key: System.get_env("SLACK_KEY"),
  state_backend: :redis,
  room: System.get_env("SLACK_ROOM"),
  redis: System.get_env("REDIS_URL")

config :logger,
  level: :info,
  truncate: 512

config :jira,
  username: System.get_env("JIRA_USERNAME"),
  password: System.get_env("JIRA_PASSWORD"),
  host: System.get_env("JIRA_HOST")
