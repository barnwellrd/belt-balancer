-- remove old values
storage.belt_balancer_max_id = nil
storage.new_balancers = nil
storage.events = nil

-- set defaults and initialize values in storage table
storage.next_balancer_unit_number = 1
storage.next_lane_unit_number = 1
storage.balancer = {}
storage.parts = {}
storage.belts = {}
storage.lanes = {}
storage.events = {}

-- rebuild storage tables with all existing balancers
for _, surface in pairs(game.surfaces) do
    local all_balancer = surface.find_entities_filtered { name = { "balancer-part" } }
    for i = 1, #all_balancer do
        built_entity({ entity = all_balancer[i]})
    end
end
