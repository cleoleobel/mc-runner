package com.nexus.core.init;

import com.nexus.core.NexusCore;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.tags.ItemTags;
import net.minecraft.tags.TagKey;
import net.minecraft.world.item.Item;

public final class NexusTags {

    /** Weapons/ammo allowed to exceed the normal boss damage cap. Filled by the datapack. */
    public static final TagKey<Item> ANTI_COLOSSUS =
            ItemTags.create(new ResourceLocation(NexusCore.MOD_ID, "anti_colossus"));

    private NexusTags() {
    }
}
