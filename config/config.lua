Config = {

    Debug = false,

    StartBot = {
        model   = 's_m_m_chemsec_01',
        coords  = vector3(-1353.827, -2707.127, 13.945),
        heading = 90.0,
        prompt  = "~INPUT_CONTEXT~ Start Chemical Job"
    },

    ExchangeBot = {
        model   = 's_m_m_chemsec_01',
        coords  = vector3(-1334.445, -2716.969, 13.945),
        heading = 90.0,
        prompt  = "~INPUT_CONTEXT~ Exchange Chemicals"
    },

    ExchangeShop = {
        chem_a = 'proc_a',
        chem_b = 'proc_b',
        chem_c = 'proc_c'
    },

    BarrelLocations = {

        barrel_a = {
            locations = {
                a = {
                    vector3(-1349.12, -2698.87, 13.94),
                    vector3(-1348.49, -2696.66, 13.94),
                    vector3(-1346.76, -2693.82, 13.94),
                },
                b = {
                    vector3(-1370.123, -2730.678, 13.945),
                    vector3(-1365.456, -2725.890, 13.945),
                    vector3(-1359.789, -2719.234, 13.945),
                },
                c = {
                    vector3(-1368.901, -2729.345, 13.945),
                    vector3(-1363.234, -2723.456, 13.945),
                    vector3(-1357.567, -2717.678, 13.945),
                }
            },
            reward = "chem_a"
        },

        barrel_b = {
            locations = {
                a = {
                    vector3(-1346.29, -2703.18, 13.95),
                    vector3(-1347.16, -2704.66, 13.94),
                    vector3(-1348.49, -2706.84, 13.94),
                },
                b = {
                    vector3(-1346.567, -2700.678, 13.945),
                    vector3(-1340.890, -2694.123, 13.945),
                    vector3(-1335.234, -2688.456, 13.945),
                },
                c = {
                    vector3(-1344.901, -2699.345, 13.945),
                    vector3(-1339.234, -2693.567, 13.945),
                    vector3(-1333.567, -2687.789, 13.945),
                }
            },
            reward = "chem_b"
        },

        barrel_c = {
            locations = {
                a = {
                    vector3(-1353.13, -2716.87, 13.94),
                    vector3(-1352.55, -2714.52, 13.94),
                    vector3(-1351.41, -2712.59, 13.94),
                },
                b = {
                    vector3(-1322.678, -2670.890, 13.945),
                    vector3(-1316.123, -2664.234, 13.945),
                    vector3(-1310.456, -2658.567, 13.945),
                },
                c = {
                    vector3(-1320.345, -2669.567, 13.945),
                    vector3(-1314.567, -2662.890, 13.945),
                    vector3(-1308.789, -2657.123, 13.945),
                }
            },
            reward = "chem_c"
        }
    },

    TruckSpawn = {
        model   = 'benson',
        coords  = vector3(-1362.12, -2703.68, 13.94),
        heading = 90.0
    },

    DeliveryZone = {

        barrel_a_delivery = {
            locations = {
                vector3(-1356.45, -2723.25, 13.94),
                -- vector3(-1210.789, -2810.678, 13.945),
                -- vector3(-1220.345, -2820.890, 13.945),
            },
            reward = "chem_a",
            count = 1,
            radius = 5.0
        },

        barrel_b_delivery = {
            locations = {
                vector3(-1362.01, -2721.68, 13.94),
                -- vector3(-1215.789, -2815.678, 13.945),
                -- vector3(-1220.789, -2820.678, 13.945),
            },
            reward = "chem_b",
            count = 1,
            radius = 5.0
        },

        barrel_c_delivery = {
            locations = {
                vector3(-1369.98, -2717.26, 13.94),
                --  vector3(-1225.789, -2825.678, 13.945),
                -- vector3(-1230.789, -2830.678, 13.945),
            },
            reward = "chem_c",
            count = 1,
            radius = 5.0
        }
    },

    TruckPark = vector3(-1369.1923, -2696.0134, 13.9212),

    LabLocation = vector3(-1328.272, -2738.602, 13.945),

    Items = {
        barrel = 'barrel',
        chem_a = 'chem_a',
        chem_b = 'chem_b',
        chem_c = 'chem_c',
        proc_a = 'proc_a',
        proc_b = 'proc_b',
        proc_c = 'proc_c',
        gunpowder = 'gunpowder'
    },

    LastRewardCount = 3,

    Cooldowns = {
        mission  = 300000,
        pickup   = 1000,
        load     = 2000,
        deliver  = 5000,
        exchange = 1000,
        mix      = 15000
    },

    TruckSlots = {
        { offset = vector3(0.5, -2.0, 0.5),  rot = vector3(0.0, 0.0, 0.0) },
        { offset = vector3(0.5, -3.0, 0.5),  rot = vector3(0.0, 0.0, 0.0) },
        { offset = vector3(-0.5, -4.0, 0.5), rot = vector3(0.0, 0.0, 0.0) },
        { offset = vector3(-0.5, -3.0, 0.5), rot = vector3(0.0, 0.0, 0.0) },
        { offset = vector3(-0.5, -2.0, 0.5), rot = vector3(0.0, 0.0, 0.0) },
    },

    MaxBarrels = 9,
    AutoCloseDoors = true,

    PropModels = {
        barrel = 'prop_barrel_01a'
    },

    AnimDicts = {
        carry = 'anim@heists@box_carry@'
    }
}
