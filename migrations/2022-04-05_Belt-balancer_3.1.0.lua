if storage.balancer then
    for _, balancer in pairs(storage.balancer) do
        for i, _ in pairs(balancer.input_lanes) do
            balancer.input_lanes[i] = storage.lanes[i]
        end
        for i, _ in pairs(balancer.output_lanes) do
            balancer.output_lanes[i] = storage.lanes[i]
        end
    end
end

if storage.parts then
    for _, part in pairs(storage.parts) do
        for i, _ in pairs(part.input_lanes) do
            part.input_lanes[i] = storage.lanes[i]
        end
        for i, _ in pairs(part.output_lanes) do
            part.output_lanes[i] = storage.lanes[i]
        end
    end
end
