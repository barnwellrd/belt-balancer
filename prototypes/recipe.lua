data:extend {
    {
        type = "recipe",
        name = "belt-balancer-normal-belt",
        enabled = false,
        energy_required = 3,
        ingredients = {
            { type = "item", name = "iron-gear-wheel", amount = 20 },
            { type = "item", name = "electronic-circuit", amount = 15 },
            { type = "item", name = "transport-belt", amount = 5 },
        },
        results = { { type = "item", name = "balancer-part", amount = 1 } },
        order = "g[balancer]-a[balancer]"
    },
    {
        type = "recipe",
        name = "belt-balancer-fast-belt",
        enabled = false,
        energy_required = 2.5,
        ingredients = {
            { type = "item", name = "iron-gear-wheel", amount = 20 },
            { type = "item", name = "electronic-circuit", amount = 15 },
            { type = "item", name = "fast-transport-belt", amount = 5 },
        },
        results = {
            { type = "item", name = "balancer-part", amount = 2 }
        },
        order = "g[balancer]-b[balancer]"
    },
    {
        type = "recipe",
        name = "belt-balancer-express-belt",
        enabled = false,
        energy_required = 2,
        ingredients = {
            { type = "item", name = "iron-gear-wheel", amount = 20 },
            { type = "item", name = "advanced-circuit", amount = 15 },
            { type = "item", name = "express-transport-belt", amount = 5 },
        },
        results = {
            { type = "item", name = "balancer-part", amount = 3 }
        },
        order = "g[balancer]-c[balancer]"
    },
}

if mods["space-age"] and not mods["boblogistics"] then
    data:extend {
        {
            type = "recipe",
            name = "belt-balancer-turbo-belt",
            enabled = false,
            energy_required = 1.5,
            ingredients = {
                { type = "item", name = "iron-gear-wheel", amount = 20 },
                { type = "item", name = "processing-unit", amount = 15 },
                { type = "item", name = "express-transport-belt", amount = 5 },
            },
            results = { { type = "item", name = "balancer-part", amount = 4 } },
            order = "g[balancer]-d[balancer]"
        },
    }
end

if mods["boblogistics"] then
    -- add recipes for the additional boblogistics belts
    if settings.startup["bobmods-logistics-beltoverhaul"].value == true then
        data:extend {
            {
                type = "recipe",
                name = "belt-balancer-basic-belt",
                enabled = false,
                energy_required = 5,
                ingredients = {
                    { type = "item", name = "iron-gear-wheel", amount = 25 },
                    { type = "item", name = "electronic-circuit", amount = 20 },
                    { type = "item", name = "basic-transport-belt", amount = 10 },
                },
                results = { { type = "item", name = "balancer-part", amount = 1 } },
                order = "g[balancer]-0a[balancer]"
            },
        }
    end

    data:extend {
        {
            type = "recipe",
            name = "belt-balancer-turbo-belt",
            enabled = false,
            energy_required = 1.8,
            ingredients = {
                { type = "item", name = "iron-gear-wheel", amount = 20 },
                { type = "item", name = "processing-unit", amount = 3 },
                { type = "item", name = "turbo-transport-belt", amount = 10 },
            },
            results = {
                { type = "item", name = "balancer-part", amount = 4 }
            },
            order = "g[balancer]-d[balancer]"
        },
        {
            type = "recipe",
            name = "belt-balancer-ultimate-belt",
            enabled = false,
            energy_required = 1.5,
            ingredients = {
                { type = "item", name = "iron-gear-wheel", amount = 20 },
                { type = "item", name = "processing-unit", amount = 5 },
                { type = "item", name = "ultimate-transport-belt", amount = 10 },
            },
            results = {
                { type = "item", name = "balancer-part", amount = 5 }
            },
            order = "g[balancer]-e[balancer]"
        },
    }
end

-- NOTICE IndustrialRevolution is not developed anymore and it will not be updated to 0.18 :(
