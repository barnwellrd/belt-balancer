require("helper.table")

---register_on_tick
---@param tick number
---@param balancer_index uint the balancer that runs on this tick
function register_on_tick(tick, balancer_index)
    local bucket = storage.events[tick]
    if not bucket then
        bucket = {}
        storage.events[tick] = bucket
        script.on_nth_tick(tick, on_tick)
    end
    bucket[balancer_index] = true
end

---unregister_on_tick
---@param balancer_index uint
function unregister_on_tick(balancer_index)
    for tick, bucket in pairs(storage.events) do
        if bucket[balancer_index] then
            bucket[balancer_index] = nil
            if next(bucket) == nil then
                script.on_nth_tick(tick, nil)
                storage.events[tick] = nil
            end
        end
    end
end

function on_tick(e)
    for balancer_id in pairs(storage.events[e.nth_tick]) do
        balancer_functions.run(balancer_id)
    end
end

function rebuild_on_tick()
    for tick in pairs(storage.events) do script.on_nth_tick(tick, nil) end
    storage.events = {}
    for balancer_index, balancer in pairs(storage.balancer) do
        balancer.nth_tick = 0
        balancer_functions.recalculate_nth_tick(balancer_index)
    end
end

function reregister_on_tick()
    -- reregister balancer
    for tick, _ in pairs(storage.events) do
        script.on_nth_tick(tick, on_tick)
    end
end
