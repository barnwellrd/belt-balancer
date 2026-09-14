storage.next_belt_check, _ = next(storage.belts, storage.next_belt_check)

if storage.balancer then
    for _, balancer in pairs(storage.balancer) do
	balancer.next_output = next(balancer.output_lanes, balancer.last_success)
    end
end
