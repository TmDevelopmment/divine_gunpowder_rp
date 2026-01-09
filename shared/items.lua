-- Shared item definitions
-- These are used across client and server for consistency

ITEMS = {
    BARREL = 'barrel',
    CHEM_A = 'chem_a',
    CHEM_B = 'chem_b',
    CHEM_C = 'chem_c',
    PROC_A = 'proc_a',
    PROC_B = 'proc_b',
    PROC_C = 'proc_c',
    GUNPOWDER = 'gunpowder'
}

-- Helper function to get item name
function GetItem(name)
    return ITEMS[name:upper()] or name
end