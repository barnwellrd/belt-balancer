require("helper.math")
require("util")
require("helper.conversion")

balancer_functions = {}

---creates a new balancer object in the storage stack
---This will NOT set the parts and the lanes!!
---@return Balancer the created balancer
function balancer_functions.new()
    ---@type Balancer
    local balancer = {}

    balancer.unit_number = get_next_balancer_unit_number()
    balancer.parts = {}
    balancer.nth_tick = 0
    balancer.buffer = {}
    balancer.buffer_first = 1
    balancer.buffer_last = 0
    balancer.input_lanes = {}
    balancer.output_lanes = {}

    storage.balancer[balancer.unit_number] = balancer

    return balancer
end

---merge two balancer, the first balancer_index is the base, to merge things into.
---The second balancer (balancer_index2) will be deleted after it is merged.
---@param balancer_index uint
---@param balancer_index2 uint
function balancer_functions.merge(balancer_index, balancer_index2)
    local balancer = storage.balancer[balancer_index]
    local balancer2 = storage.balancer[balancer_index2]

    for k, part_index in pairs(balancer2.parts) do
        balancer.parts[k] = part_index

        -- change balancer link on part too
        local part = storage.parts[part_index]
        part.balancer = balancer_index

        -- change balancer link on belts too
        for _, belt_index in pairs(part.input_belts) do
            local belt = storage.belts[belt_index]
            belt.output_balancer[balancer_index2] = nil
            belt.output_balancer[balancer_index] = balancer_index
        end

        for _, belt_index in pairs(part.output_belts) do
            local belt = storage.belts[belt_index]
            belt.input_balancer[balancer_index2] = nil
            belt.input_balancer[balancer_index] = balancer_index
        end
    end

    for k, v in pairs(balancer2.input_lanes) do
        balancer.input_lanes[k] = v
    end

    for k, v in pairs(balancer2.output_lanes) do
        balancer.output_lanes[k] = v
    end

    for index = balancer_functions.buffer_first(balancer2), balancer_functions.buffer_last(balancer2) do
        balancer_functions.push_buffer(balancer, balancer2.buffer[index])
    end

    -- remove merged balancer from the storage stack
    storage.balancer[balancer_index2] = nil

    -- unregister nth_tick
    unregister_on_tick(balancer_index2)
end

---This will find nearby balancer, creates/adds/merges balancer if needed.
---The part is automatically added to the balancer!
---@param part Part The part entity to work from
---@return uint The balancer index, that the part is part of :)
function balancer_functions.find_from_part(part)
    if part.balancer ~= nil then
        return part.balancer
    end

    local entity = part.entity

    local nearby_balancer_indices = part_functions.find_nearby_balancer(entity)
    local nearby_balancer_amount = table_size(nearby_balancer_indices)

    if nearby_balancer_amount == 0 then
        -- create new balancer
        local balancer = balancer_functions.new()
        balancer.parts[entity.unit_number] = entity.unit_number
        return balancer.unit_number
    elseif nearby_balancer_amount == 1 then
        -- add to existing balancer
        local balancer
        for _, index in pairs(nearby_balancer_indices) do
            balancer = storage.balancer[index]
            balancer.parts[entity.unit_number] = entity.unit_number
        end
        return balancer.unit_number
    elseif nearby_balancer_amount >= 2 then
        -- add to existing balancer and merge them
        -- merge fond balancer
        local base_balancer_index
        for _, nearby_balancer_index in pairs(nearby_balancer_indices) do
            if not base_balancer_index then
                base_balancer_index = nearby_balancer_index

                -- add splitter to balancer
                local balancer = storage.balancer[nearby_balancer_index]
                balancer.parts[entity.unit_number] = entity.unit_number
            else
                -- merge balancer and remove them from storage table
                balancer_functions.merge(base_balancer_index, nearby_balancer_index)
            end
        end
        return base_balancer_index
    end
end

---recalculate_nth_tick
---@param balancer_index uint
function balancer_functions.recalculate_nth_tick(balancer_index)
    local balancer = storage.balancer[balancer_index]

    local input_lane_count = table_size(balancer.input_lanes)
    local output_lane_count = table_size(balancer.output_lanes)
    balancer.input_lane_count = input_lane_count
    balancer.output_lane_count = output_lane_count
    balancer.max_buffer_size = output_lane_count * 4

    if input_lane_count == 0 or output_lane_count == 0 or table_size(balancer.parts) == 0 then
        unregister_on_tick(balancer_index)
        balancer.nth_tick = 0
        return
    end

    -- recalculate nth_tick
    local tick_list = {}
    local run_on_tick_override = false

    for _, part in pairs(balancer.parts) do
        local stack_part = storage.parts[part]
        for _, belt in pairs(stack_part.output_belts) do
            local stack_belt = storage.belts[belt]
            local belt_speed = stack_belt.entity.prototype.belt_speed
            local ticks_per_tile = 0.25 / belt_speed
            local nth_tick = math.floor(ticks_per_tile)
            if nth_tick ~= ticks_per_tile then
                run_on_tick_override = true
                break
            end
            tick_list[nth_tick] = nth_tick
        end

        if run_on_tick_override then
            break
        end
    end

    local smallest_gcd = -1
    if not run_on_tick_override then
        for _, tick in pairs(tick_list) do
            if smallest_gcd == -1 then
                smallest_gcd = tick
            elseif smallest_gcd == 1 then
                break
            elseif smallest_gcd == tick then
                -- do nothing
            else
                smallest_gcd = math.gcd(smallest_gcd, tick)
            end
        end
    end

    if run_on_tick_override then
        smallest_gcd = 1
    end
    if smallest_gcd ~= -1 and balancer.nth_tick ~= smallest_gcd then
        balancer.nth_tick = smallest_gcd
        unregister_on_tick(balancer_index)
        register_on_tick(smallest_gcd, balancer_index)
    end
end

function balancer_functions.buffer_first(balancer)
    return balancer.buffer_first or 1
end

function balancer_functions.buffer_last(balancer)
    return balancer.buffer_last or #balancer.buffer
end

function balancer_functions.buffer_size(balancer)
    return balancer_functions.buffer_last(balancer) - balancer_functions.buffer_first(balancer) + 1
end

function balancer_functions.push_buffer(balancer, item)
    local last = balancer_functions.buffer_last(balancer) + 1
    balancer.buffer[last] = item
    balancer.buffer_last = last
    balancer.buffer_first = balancer_functions.buffer_first(balancer)
end

function balancer_functions.pop_buffer(balancer)
    if balancer_functions.buffer_size(balancer) <= 0 then return nil end
    local first = balancer_functions.buffer_first(balancer)
    local item = balancer.buffer[first]
    balancer.buffer[first] = nil
    first = first + 1
    if first > balancer_functions.buffer_last(balancer) then
        balancer.buffer_first = 1
        balancer.buffer_last = 0
    else
        balancer.buffer_first = first
    end
    return item
end

-- Main on_tick() function to run each balancer
function balancer_functions.run(balancer_index)
    local balancer = storage.balancer[balancer_index]
    local input_lane_count = balancer.input_lane_count or table_size(balancer.input_lanes)
    local output_lane_count = balancer.output_lane_count or table_size(balancer.output_lanes)
    if input_lane_count > 0 then
        -- input
        balancer.next_input = balancer_functions.input_lanes_to_buffer(balancer_index)
    end
    if  output_lane_count > 0 then
        -- output
        balancer.next_output = balancer_functions.buffer_to_output_lanes(balancer_index)
    end
end

-- Function to fill buffer from input lanes on balancer
function balancer_functions.input_lanes_to_buffer(balancer_index)
    local balancer = storage.balancer[balancer_index]
    local input_lane_count = balancer.input_lane_count or table_size(balancer.input_lanes)
    local output_lane_count = balancer.output_lane_count or table_size(balancer.output_lanes)
    local max_buffer_size = balancer.max_buffer_size or output_lane_count * 4
    local next_input = (not balancer.next_input and next(balancer.input_lanes) or next(balancer.input_lanes, balancer.next_input))

    for _ = 0, input_lane_count do
        --print("Entered input repeat..")
        if balancer_functions.buffer_size(balancer) >= max_buffer_size then
            break
        else
            if next_input then
                if balancer_functions.buffer_size(balancer) < max_buffer_size then
                    convert_items_from_input_to_buffer(balancer_index, next_input)
                else
                    break
                end
            end
        end
        next_input = next(balancer.input_lanes, next_input)
    end
    return next_input
end

-- Function to fill output lanes from buffer on balancer
function balancer_functions.buffer_to_output_lanes(balancer_index)
    local balancer = storage.balancer[balancer_index]
    local output_lane_count = balancer.output_lane_count or table_size(balancer.output_lanes)
    local next_output = (not balancer.next_output and next(balancer.output_lanes) or next(balancer.output_lanes, balancer.next_output))

    for _ = 0, output_lane_count do
        if balancer_functions.buffer_size(balancer) > 0 then
            if next_output then
                local olane = balancer.output_lanes[next_output]
                local olane_start_size = #olane
                for _ = olane_start_size,4 do
                    if olane_start_size < 4 and balancer_functions.buffer_size(balancer) > 0 then
                        local item = balancer.buffer[balancer_functions.buffer_first(balancer)]
                        if olane.insert_at_back(item) then balancer_functions.pop_buffer(balancer) end
                    end
                end
            end
            next_output = next(balancer.output_lanes, next_output)
        else
            break
        end
    end
    return next_output
end

---check if this balancer still needs to be tracked, if not, remove it from storage stack!
---@param balancer_index uint
---@param drop_to Item_drop_param
---@return boolean True if balancer is still tracked, false if balancer was removed
function balancer_functions.check_track(balancer_index, drop_to)
    local balancer = storage.balancer[balancer_index]
    if table_size(balancer.parts) == 0 then
        -- balancer is not valid, remove it from storage stack
        if table_size(balancer.output_lanes) > 0 or table_size(balancer.input_lanes) > 0 then
            print("Belt-balancer: Something is off with the removing of balancer lanes")
            print("balancer: ", balancer_index)
            print(serpent.block(storage.balancer))
        end

        balancer_functions.empty_buffer(balancer, drop_to)

        storage.balancer[balancer_index] = nil

        return false
    end

    return true
end

---empty_buffer
---@overload fun(balancer:Balancer, buffer:LuaInventory)
---@param balancer Balancer
---@param drop_to Item_drop_param
function balancer_functions.empty_buffer(balancer, drop_to)
    if drop_to.buffer and drop_to.buffer.valid then
        for index = balancer_functions.buffer_first(balancer), balancer_functions.buffer_last(balancer) do
            drop_to.buffer.insert(balancer.buffer[index])
        end
    else
        -- drop items on ground
        for index = balancer_functions.buffer_first(balancer), balancer_functions.buffer_last(balancer) do
            drop_to.surface.spill_item_stack { position = drop_to.position, stack = balancer.buffer[index], enable_looted = false, force = drop_to.force }
        end
    end
end

---balancer_get_linked
---get all lined splitters into an array of LuaEntity
---@param balancer Balancer balancer to perform on
---@return LuaEntity[][]
function balancer_functions.get_linked(balancer)
    -- create matrix
    local matrix = {}
    for _, part_index in pairs(balancer.parts) do
        local part = storage.parts[part_index]
        local pos = part.entity.position
        if not matrix[pos.x] then
            matrix[pos.x] = {}
        end
        matrix[pos.x][pos.y] = part.entity
    end

    local curr_num = 0
    local result = {}
    repeat
        curr_num = curr_num + 1
        balancer_functions.expand_first(matrix, curr_num, result)
    until (table_size(matrix) == 0)
    return result
end

---balancer_expand_first
---expand the first found not expanded Element in the matrix
---@param matrix LuaEntity[][] matrix to perform logic on
---@param num number
function balancer_functions.expand_first(matrix, num, result)
    for x_key, _ in pairs(matrix) do
        local breaker = false
        for y_key, _ in pairs(matrix[x_key]) do
            if matrix[x_key][y_key] then
                result[num] = {}
                balancer_functions.expand_matrix(matrix, { x = x_key, y = y_key }, num, result)
                breaker = true
                break
            end
        end

        if breaker then
            break
        end
    end
end

---balancer_expand_matrix
---expand given element in the matrix and then expand its neighbours
---only expand if this element is not nil
function balancer_functions.expand_matrix(matrix, pos, num, result)
    if matrix[pos.x] and matrix[pos.x][pos.y] then
        local part_entity = matrix[pos.x][pos.y]
        result[num][part_entity.unit_number] = part_entity
        matrix[pos.x][pos.y] = nil
        if table_size(matrix[pos.x]) == 0 then
            matrix[pos.x] = nil
        end

        balancer_functions.expand_matrix(matrix, { x = pos.x - 1, y = pos.y }, num, result)
        balancer_functions.expand_matrix(matrix, { x = pos.x + 1, y = pos.y }, num, result)
        balancer_functions.expand_matrix(matrix, { x = pos.x, y = pos.y - 1 }, num, result)
        balancer_functions.expand_matrix(matrix, { x = pos.x, y = pos.y + 1 }, num, result)
    end
end

---create a new balancer with already created parts
---@param part_list LuaEntity[]
---@return Balancer
function balancer_functions.new_from_part_list(part_list)
    local balancer = balancer_functions.new()

    for _, part_entity in pairs(part_list) do
        local part = storage.parts[part_entity.unit_number]

        -- add part to balancer
        balancer.parts[part_entity.unit_number] = part_entity.unit_number

        -- add balancer to part
        part.balancer = balancer.unit_number

        for _, belt_index in pairs(part.input_belts) do
            local belt = storage.belts[belt_index]

            -- add balancer to belt
            belt.output_balancer[balancer.unit_number] = balancer.unit_number
        end

        for _, belt_index in pairs(part.output_belts) do
            local belt = storage.belts[belt_index]

            -- add balancer to belt
            belt.input_balancer[balancer.unit_number] = balancer.unit_number
        end

        -- add lanes to balancer
        for lane_index, lane in pairs(part.input_lanes) do
            balancer.input_lanes[lane_index] = lane
        end
        for lane_index, lane in pairs(part.output_lanes) do
            balancer.output_lanes[lane_index] = lane
        end
    end

    balancer_functions.recalculate_nth_tick(balancer.unit_number)

    return balancer
end

---check if this balancer still is one piece, if not, create multiple balancer if needed.
---@param balancer_index uint
---@param drop_to Item_drop_param
function balancer_functions.check_connected(balancer_index, drop_to)
    local balancer = storage.balancer[balancer_index]

    local linked = balancer_functions.get_linked(balancer)
    if table_size(linked) > 1 then
        -- unregister balancer, before splitting it
        unregister_on_tick(balancer_index)

        -- create multiple new balancer
        for _, parts in pairs(linked) do
            balancer_functions.new_from_part_list(parts)
        end

        -- remove old balancer from belts
        for _, part_index in pairs(balancer.parts) do
            local part = storage.parts[part_index]
            for _, belt_index in pairs(part.input_belts) do
                local belt = storage.belts[belt_index]
                belt.input_balancer[balancer_index] = nil
                belt.output_balancer[balancer_index] = nil
            end
            for _, belt_index in pairs(part.output_belts) do
                local belt = storage.belts[belt_index]
                belt.input_balancer[balancer_index] = nil
                belt.output_balancer[balancer_index] = nil
            end
        end

        -- clear the old balancer buffer
        balancer_functions.empty_buffer(balancer, drop_to)

        -- finally, remove old balancer form storage stack
        storage.balancer[balancer_index] = nil
    end
end

return balancer_functions
