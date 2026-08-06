package com.nexus.core.init;

import com.nexus.core.NexusCore;
import net.minecraft.core.registries.Registries;
import net.minecraft.network.chat.Component;
import net.minecraft.world.item.CreativeModeTab;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Rarity;
import net.minecraftforge.registries.DeferredRegister;
import net.minecraftforge.registries.ForgeRegistries;
import net.minecraftforge.registries.RegistryObject;

public final class ItemInit {

    public static final DeferredRegister<Item> ITEMS =
            DeferredRegister.create(ForgeRegistries.ITEMS, NexusCore.MOD_ID);
    public static final DeferredRegister<CreativeModeTab> TABS =
            DeferredRegister.create(Registries.CREATIVE_MODE_TAB, NexusCore.MOD_ID);

    public static final RegistryObject<Item> BALLISTIC_STEEL = ITEMS.register("ballistic_steel",
            () -> new Item(new Item.Properties().rarity(Rarity.COMMON)));

    public static final RegistryObject<Item> ARCANE_CATALYST = ITEMS.register("arcane_catalyst",
            () -> new Item(new Item.Properties().rarity(Rarity.RARE).fireResistant()));

    public static final RegistryObject<Item> TECHNOMANTIC_CRYSTAL = ITEMS.register("technomantic_crystal",
            () -> new Item(new Item.Properties().rarity(Rarity.EPIC).fireResistant()));

    public static final RegistryObject<Item> CONTAINMENT_RUNE = ITEMS.register("containment_rune",
            () -> new Item(new Item.Properties().rarity(Rarity.UNCOMMON)));

    public static final RegistryObject<CreativeModeTab> NEXUS_TAB = TABS.register("nexus",
            () -> CreativeModeTab.builder()
                    .title(Component.translatable("itemGroup.nexus.nexus"))
                    .icon(() -> new ItemStack(TECHNOMANTIC_CRYSTAL.get()))
                    .displayItems((params, output) -> {
                        output.accept(BALLISTIC_STEEL.get());
                        output.accept(ARCANE_CATALYST.get());
                        output.accept(TECHNOMANTIC_CRYSTAL.get());
                        output.accept(CONTAINMENT_RUNE.get());
                    })
                    .build());

    private ItemInit() {
    }
}
