---@param stack LuaItemStack
---@return SimpleItemStack
function stabilize_item_stack(stack)
    local item_type = stack.prototype.type
    return {
        name = stack.name,
        count = stack.count,
        quality = stack.quality.name,
        health = stack.health,
        durability = (item_type == "tool" or item_type == "repair-tool" or item_type == "armor") and stack.durability,
        ammo = item_type == "ammo" and stack.ammo,
        tags = item_type == "item-with-tags" and stack.tags,
        custom_description = item_type == "item-with-tags" and stack.custom_description,
        spoil_percent = stack.spoil_percent
    }
end

---convert_items_from_input_to_buffer
---@param balancer Balancer
---@param next_input uint
function convert_items_from_input_to_buffer(balancer, next_input)
    local ilane = balancer.input_lanes[next_input]
    local lane_size = #ilane
    if lane_size > 0 then
        local buffer = balancer.buffer
        local last = balancer.buffer_last or #buffer
        for i = 1, lane_size do
            local item = ilane[i]
            last = last + 1
            buffer[last] = stabilize_item_stack(item)
        end
        balancer.buffer_first = balancer.buffer_first or 1
        balancer.buffer_last = last
        -- Will always dump the entire lane contents (up to all 4 item stacks) into the buffer.
        ilane.clear()
    end
    return lane_size
end
