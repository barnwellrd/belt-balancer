if storage.balancer then
    for k, _ in pairs(storage.balancer) do
        balancer_functions.recalculate_nth_tick(k)
    end
end
