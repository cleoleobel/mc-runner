package com.nexus.core.event;

import com.nexus.core.NexusCore;
import com.nexus.core.config.NexusConfig;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.entity.EquipmentSlot;
import net.minecraft.world.entity.ai.attributes.Attribute;
import net.minecraft.world.entity.ai.attributes.AttributeInstance;
import net.minecraft.world.entity.ai.attributes.AttributeModifier;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraftforge.event.entity.living.LivingEquipmentChangeEvent;
import net.minecraftforge.event.entity.player.PlayerEvent;
import net.minecraftforge.eventbus.api.SubscribeEvent;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.registries.ForgeRegistries;

import java.util.UUID;

/**
 * Heavy tech armour weakens spellcasting, so MekaSuit does not simply dominate
 * the magic pillar. Implemented as transient attribute modifiers on Iron's
 * Spells attributes, looked up by registry id so Nexus Core needs no compile
 * dependency on that mod: if Iron's Spells is absent this silently does nothing.
 */
@Mod.EventBusSubscriber(modid = NexusCore.MOD_ID)
public final class MagicArmorEventHandler {

    private static final ResourceLocation MAX_MANA = new ResourceLocation("irons_spellbooks", "max_mana");
    private static final ResourceLocation SPELL_POWER = new ResourceLocation("irons_spellbooks", "spell_power");

    private static final UUID MANA_MODIFIER_ID = UUID.fromString("6f0a1c4e-2b7d-4f21-9a3e-5c8d0e1f2a3b");
    private static final UUID POWER_MODIFIER_ID = UUID.fromString("7a1b2c3d-4e5f-4061-8b92-0c1d2e3f4a5b");

    private MagicArmorEventHandler() {
    }

    @SubscribeEvent
    public static void onEquipmentChange(LivingEquipmentChangeEvent event) {
        if (event.getSlot().getType() != EquipmentSlot.Type.ARMOR) {
            return;
        }
        if (event.getEntity() instanceof Player player && !player.level().isClientSide()) {
            apply(player);
        }
    }

    @SubscribeEvent
    public static void onLogin(PlayerEvent.PlayerLoggedInEvent event) {
        if (!event.getEntity().level().isClientSide()) {
            apply(event.getEntity());
        }
    }

    /** Respawning builds a fresh player entity, so the modifier must be re-applied. */
    @SubscribeEvent
    public static void onClone(PlayerEvent.Clone event) {
        if (!event.getEntity().level().isClientSide()) {
            apply(event.getEntity());
        }
    }

    private static void apply(Player player) {
        boolean penalise = NexusConfig.MAGIC.enableHeavyArmorPenalty && wearsHeavyArmor(player);
        set(player, MAX_MANA, MANA_MODIFIER_ID, "nexus_heavy_armor_mana",
                penalise ? -NexusConfig.MAGIC.heavyArmorMaxManaPenalty : 0.0);
        set(player, SPELL_POWER, POWER_MODIFIER_ID, "nexus_heavy_armor_power",
                penalise ? -NexusConfig.MAGIC.heavyArmorSpellPowerPenalty : 0.0);
    }

    private static void set(Player player, ResourceLocation attributeId, UUID modifierId, String name, double amount) {
        Attribute attribute = ForgeRegistries.ATTRIBUTES.getValue(attributeId);
        if (attribute == null) {
            return; // Iron's Spells not installed.
        }
        AttributeInstance instance = player.getAttribute(attribute);
        if (instance == null) {
            return;
        }
        instance.removeModifier(modifierId);
        if (amount != 0.0) {
            instance.addTransientModifier(new AttributeModifier(
                    modifierId, name, amount, AttributeModifier.Operation.MULTIPLY_TOTAL));
        }
    }

    private static boolean wearsHeavyArmor(Player player) {
        for (ItemStack armor : player.getArmorSlots()) {
            if (armor.isEmpty()) {
                continue;
            }
            ResourceLocation id = ForgeRegistries.ITEMS.getKey(armor.getItem());
            if (id != null && NexusConfig.isHeavyArmorId(id.toString())) {
                return true;
            }
        }
        return false;
    }
}
