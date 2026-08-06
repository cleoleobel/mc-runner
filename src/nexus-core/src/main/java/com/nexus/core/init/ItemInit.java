package com.nexus.core.init;

import com.nexus.core.NexusCore;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.Rarity;
import net.minecraftforge.registries.DeferredRegister;
import net.minecraftforge.registries.ForgeRegistries;
import net.minecraftforge.registries.RegistryObject;

public class ItemInit {
    public static final DeferredRegister<Item> ITEMS = DeferredRegister.create(ForgeRegistries.ITEMS, NexusCore.MOD_ID);

    public static final RegistryObject<Item> BALLISTIC_STEEL = ITEMS.register("ballistic_steel",
            () -> new Item(new Item.Properties().rarity(Rarity.COMMON)));

    public static final RegistryObject<Item> ARCANE_CATALYST = ITEMS.register("arcane_catalyst",
            () -> new Item(new Item.Properties().rarity(Rarity.RARE).fireResistant()));

    public static final RegistryObject<Item> TECHNOMANTIC_CRYSTAL = ITEMS.register("technomantic_crystal",
            () -> new Item(new Item.Properties().rarity(Rarity.EPIC).fireResistant()));

    public static final RegistryObject<Item> CONTAINMENT_RUNE = ITEMS.register("containment_rune",
            () -> new Item(new Item.Properties().rarity(Rarity.UNCOMMON)));
}
