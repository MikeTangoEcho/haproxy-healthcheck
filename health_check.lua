--- HealthCheck module.
-- Register a background task to pull backend and server stats and push them.
--
-- @module health_check

-- TODO check queues for way to hook om email_alert
-- Timer in seconds
local timer = 10


-- Sentry Configuration
-- TODO find a way to extract variable from haproxy conf file
-- TODO configurate different dsn according to backend
local sentry_dsn_url = "http://d981d55fa66549bba49a2fda1182b60a@192.168.43.1:9000/2"

function get_sentry_raven()
  local raven = require "raven"
  local rvn = raven.new {
    -- multiple senders are available for different networking backends,
    -- doing a custom one is also very easy.
    sender = require("raven.senders.luasocket").new { dsn = sentry_dsn_url }
  }
  return rvn
end

function sentry_send_message(rvn, message, conf)
  local id, err = rvn:captureMessage(message, conf)
  if not id then
     core.Alert(err)
  end
end

function sentry_level_message(status)
  if status == "DOWN" then
    return "error"
  end
  if status ~= "UP" then
    return "warning"
  end
  return "info"
end

--- Main Task
function health_check_task()
  local rvn = get_sentry_raven()
  while true do
    for backend_key, backend in pairs(core.backends) do
      -- TODO filter on backend.name
      local backend_stats = backend:get_stats()
      if backend_stats.status ~= "UP" then
          sentry_send_message(
            rvn,
            "Backend " .. backend.name .. " Status " .. backend_stats.status,
            { extra = backend_stats, tags = { backend = backend_key } }
          )
      end
      -- Backend can be UP and have only 1 healthy server
      -- Server in transient state (UP 1/x - DN 1/x) will send a warning instead of an error
      for server_key, server in pairs(backend.servers) do
        local server_stats = server:get_stats()
        if server_stats.status ~= "UP" then
          sentry_send_message(
            rvn,
            "Backend " .. server_stats.pxname .. " Server " .. server_key .. " Status " .. server_stats.status,
            { extra = server_stats,
              tags = { backend = server_stats.pxname, server = server_key },
              level = sentry_level_message(server_stats.status) }
          )
        end
      end
    end
    core.sleep(timer)
  end
end

-- Register HAProxy background task
core.register_task(health_check_task)

