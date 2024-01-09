local status_ok, dn = pcall(require, "dark_notify")
if not status_ok then
  return
end

dn.run()
