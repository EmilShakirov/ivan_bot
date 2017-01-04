# Ivan Bot

Slack bot to automate and simplify daily stand-up meetings. Stores each team member daily report.
JIRA integration available.

## Avilable commands and usage examples

See [guide](https://github.com/EmilShakirov/ivan_bot/blob/master/templates/guide.eex)

## Dependencies

* Elixir 1.3.x
* Redis server

## Quick Start

```bash
# clone repo
git clone git@github.com:EmilShakirov/ivan_bot.git
cd ivan_bot

# install dependencies
mix deps.get

# run tests
mix test

# run codestyle linter
mix credo

# generate documentation
mix docs
```
