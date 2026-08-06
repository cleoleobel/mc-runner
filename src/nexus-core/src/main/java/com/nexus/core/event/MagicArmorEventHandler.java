package com.nexus.core.event;

import com.nexus.core.NexusCore;
import net.minecraft.world.entity.EquipmentSlot;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraftforge.event.entity.living.LivingEquipmentChangeEvent;
import net.minecraftforge.eventbus.api.SubscribeEvent;
import net.minecraftforge.fml.common.Mod;

@Mod.EventBusSubscriber(modid = NexusCore.MOD_ID)
public class MagicArmorEventHandler {

    @SubscribeEvent
    public static void onEquipmentChange(LivingEquipmentChangeEvent event) {
        if (event.getEntity() instanceof Player player) {
            if (event.getSlot().getType() == EquipmentSlot.Type.ARMOR) {
                boolean hasHeavyArmor = checkHeavyArmor(player);
                player.getPersistentData().putBoolean("nexus_heavy_armor_penalty", hasHeavyArmor);
            }
        }
    }

    private static boolean checkHeavyArmor(Player player) {
        for (ItemStack armor : player.getArmorSlots()) {
            if (!armor.isEmpty()) {
                String name = armor.getItem().getDescriptionId().toLowerCase();
                if (name.contains("mekasuit") || name.contains("netherite") || name.contains("ignitium")) {
                    return true;
                }
            }
        }
        return false;
    }
}
