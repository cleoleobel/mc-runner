package com.nexus.core.event;

import com.nexus.core.NexusCore;
import com.nexus.core.config.NexusConfig;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.ai.attributes.AttributeInstance;
import net.minecraft.world.entity.ai.attributes.Attributes;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.phys.AABB;
import net.minecraftforge.event.entity.EntityJoinLevelEvent;
import net.minecraftforge.event.entity.living.LivingHurtEvent;
import net.minecraftforge.eventbus.api.SubscribeEvent;
import net.minecraftforge.fml.common.Mod;

import java.util.List;

@Mod.EventBusSubscriber(modid = NexusCore.MOD_ID)
public class BossEventHandler {

    @SubscribeEvent
    public static void onBossSpawn(EntityJoinLevelEvent event) {
        if (event.getLevel().isClientSide()) return;

        if (event.getEntity() instanceof LivingEntity living && isBossEntity(living)) {
            // Verificar que no haya sido ya ajustado
            if (living.getPersistentData().getBoolean("nexus_scaled")) return;

            AABB area = living.getBoundingBox().inflate(64.0);
            List<Player> nearbyPlayers = event.getLevel().getEntitiesOfClass(Player.class, area);
            int playerCount = Math.max(1, nearbyPlayers.size());

            if (playerCount > 1) {
                int extraPlayers = playerCount - 1;
                double hpMultiplier = 1.0 + (extraPlayers * NexusConfig.BOSS.healthScalingPerPlayer);
                double dmgMultiplier = 1.0 + (extraPlayers * NexusConfig.BOSS.damageScalingPerPlayer);

                AttributeInstance maxHealthAttr = living.getAttribute(Attributes.MAX_HEALTH);
                if (maxHealthAttr != null) {
                    double newMaxHealth = maxHealthAttr.getBaseValue() * hpMultiplier;
                    maxHealthAttr.setBaseValue(newMaxHealth);
                    living.setHealth((float) newMaxHealth);
                }

                AttributeInstance attackDmgAttr = living.getAttribute(Attributes.ATTACK_DAMAGE);
                if (attackDmgAttr != null) {
                    attackDmgAttr.setBaseValue(attackDmgAttr.getBaseValue() * dmgMultiplier);
                }

                NexusCore.LOGGER.info("Scaled Boss {} for {} players: +{}% HP", living.getScoreboardName(), playerCount, (extraPlayers * NexusConfig.BOSS.healthScalingPerPlayer * 100));
            }

            living.getPersistentData().putBoolean("nexus_scaled", true);
        }
    }

    @SubscribeEvent
    public static void onBossHurt(LivingHurtEvent event) {
        LivingEntity living = event.getEntity();
        if (isBossEntity(living)) {
            float amount = event.getAmount();
            float cap = NexusConfig.BOSS.maxDamageCapPerHit;

            // Revisar si el origen del daño es munición anti-coloso
            boolean isAntiColossus = event.getSource().getMsgId().contains("anti_colossus") ||
                                     (event.getSource().getEntity() instanceof Player p && p.getMainHandItem().getHoverName().getString().contains("Anti-Colossus"));

            if (!isAntiColossus && amount > cap) {
                event.setAmount(cap);
            }
        }
    }

    private static boolean isBossEntity(LivingEntity entity) {
        String regName = entity.getType().getDescriptionId().toLowerCase();
        return regName.contains("cataclysm") || regName.contains("eeeabsmobs") || regName.contains("ender_dragon") || regName.contains("wither");
    }
}
