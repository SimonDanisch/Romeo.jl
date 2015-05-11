using Lumberjack

configure(; modes = ["debug", "info", "warn", "error", "crazy"])
Lumberjack.add_truck(LumberjackTruck("/tmp/Lumber.log"), "lumberj-logger")

log("debug", "some-msg")
log("info", "some-msg")
log("warn", "some-msg")
log("error", "some-msg")
log("crazy", "some-msg")

add_saw(Lumberjack.msec_date_saw)
log("debug", "dated-msg")
log("info", "dated-msg")
log("warn", "dated-msg")
log("error", "dated-msg")
log("crazy", "dated-msg")



Lumberjack.remove_truck("console")

log("debug", "noconsole-msg")
log("info", "noconsole-msg")
log("warn", "noconsole-msg")
log("error", "noconsole-msg")
log("crazy", "noconsole-msg")


a=[1.0 2.0 ; 3.0 4.0]


log("debug", "Strange matrix",Dict(:aa=>a, :bb => "BLA BLA"))


