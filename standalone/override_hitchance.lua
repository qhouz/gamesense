-- @qhouz

-- const
local FL_ONGROUND = bit.lshift(1, 0); -- 1 << 0

-- @package skeet
local skeet = {}; do
    skeet.weapon_type = ui.reference("Rage", "Weapon type", "Weapon type");
    skeet.hitchance = ui.reference("Rage", "Aimbot", "Minimum hit chance");
end

-- @package hitchance
local hitchance = {}; do
    -- @private
    local list = {};
    local master = ui.new_checkbox("Rage", "Aimbot", "Override hit chance");
    local in_air = ui.new_slider("Rage", "Aimbot", "In-air hit chance", 0, 100, 50, true, "%", 1, {[0] = "Off"});
    local no_scope = ui.new_slider("Rage", "Aimbot", "Noscope hit chance", 0, 100, 50, true, "%", 1, {[0] = "Off"});

    local can_scope = {
        ["G3SG1 / SCAR-20"] = true,
        ["SSG 08"] = true,
        ["AWP"] = true,
        ["Rifles"] = true
    };

    local function callback(item)
        local val = ui.get(item);
        local wpn = ui.get(skeet.weapon_type);

        ui.set_visible(in_air, val);
        ui.set_visible(no_scope, val and can_scope[wpn]);
    end

    ui.set_callback(master, callback);
    callback(master);

    -- @public
    function hitchance:on_shutdown()
        local prev = ui.get(skeet.weapon_type);

        for k, v in pairs(list) do
            ui.set(skeet.weapon_type, k);
            ui.set(skeet.hitchance, v);
        end

        ui.set(skeet.weapon_type, prev);
    end

    function hitchance:set(weapon, value)
        if list[weapon] == nil then
            list[weapon] = ui.get(skeet.hitchance);
        end

        ui.set(skeet.hitchance, value);
    end

    function hitchance:on_paint()
        local me = entity.get_local_player();

        if me == nil or not entity.is_alive(me) then
            return;
        end

        local wpn = ui.get(skeet.weapon_type);
        local m_fFlags = entity.get_prop(me, "m_fFlags");

        if ui.get(master) then
            if bit.band(m_fFlags, FL_ONGROUND) == 0 then
                local value = ui.get(in_air);

                if value ~= 0 then
                    self:set(wpn, value);
                    return;
                end
            end

            if can_scope[wpn] and entity.get_prop(me, "m_bIsScoped") == 0 then
                local value = ui.get(no_scope);

                if value ~= 0 then
                    self:set(wpn, value);
                    return;
                end
            end
        end

        if list[wpn] ~= nil then
            ui.set(skeet.hitchance, list[wpn]);
            list[wpn] = nil;
        end
    end
end

-- @event
client.set_event_callback("shutdown", function()
    hitchance:on_shutdown();
end);

client.set_event_callback("paint", function()
    hitchance:on_paint();
end);
