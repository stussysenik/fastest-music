import Config

# SSL/HTTPS is handled at the proxy level by Fly.io (force_https in fly.toml).
# Using force_ssl here would redirect internal health checks and break deployment.

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
