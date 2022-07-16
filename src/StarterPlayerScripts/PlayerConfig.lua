return {
    RunSpeed = 18,
    SprintSpeed = 30,
    MaxStamina = 100,
    StaminaDecrease = 1,
    Animations = {
        Eat = 9002979172,
        MeleeWeapon = {
            Attack = {10115834605, 9137224525}
        }
        -- Needs to be server side because of charging weirdness
        -- TODO: Combine these bow animations into one and add animation events for "Charged" where we can pause it when charging
        -- Bow = {10185324226, 10195926270, 10181760589} -- Charging, charged, fire
    }
}
