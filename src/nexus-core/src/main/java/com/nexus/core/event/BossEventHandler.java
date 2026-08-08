package com.nexus.core.event;

import com.nexus.core.NexusCore;
import com.nexus.core.config.NexusConfig;
import com.nexus.core.init.NexusTags;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.ai.attributes.AttributeInstance;
import net.minecraft.world.entity.ai.attributes.Attributes;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.phys.AABB;
import net.minecraftforge.event.entity.EntityJoinLevelEvent;
import net.minecraftforge.event.entity.living.LivingHurtEvent;
import net.minecraftforge.eventbus.api.SubscribeEvent;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.registries.ForgeRegistries;

import java.util.List;

/**
 * Co-op boss scaling and the anti-colossus damage rule.
 * Purely event-driven: no ticking, no global scans.
 */
@Mod.EventBusSubscriber(modid = NexusCore.MOD_ID)
public final class BossEventHandler {

    /** Marks an entity as already scaled; survives save/load via ForgeData. */
    private static final String SCALED_TAG = "nexus_scaled";

    private BossEventHandler() {
    }

    @SubscribeEvent
    public static void onBossSpawn(EntityJoinLevelEvent event) {
        if (event.getLevel().isClientSide()) {
            return;
        }
        if (!(event.getEntity() instanceof LivingEntity boss) || !isBoss(boss)) {
            return;
        }
        // Cheap flag check first so re-entering chunks costs nothing.
        if (boss.getPersistentData().getBoolean(SCALED_TAG)) {
            return;
        }
        boss.getPersistentData().putBoolean(SCALED_TAG, true);

        AABB area = boss.getBoundingBox().inflate(NexusConfig.BOSS.playerScanRadius);
        List<Player> nearby = event.getLevel().getEntitiesOfClass(Player.class, area);
        int extraPlayers = Math.max(0, nearby.size() - 1);
        if (extraPlayers == 0) {
            return;
        }

        double hpMultiplier = 1.0 + extraPlayers * NexusConfig.BOSS.healthScalingPerPlayer;
        double dmgMultiplier = 1.0 + extraPlayers * NexusConfig.BOSS.damageScalingPerPlayer;

        AttributeInstance maxHealth = boss.getAttribute(Attributes.MAX_HEALTH);
        if (maxHealth != null) {
            double scaled = maxHealth.getBaseValue() * hpMultiplier;
            maxHealth.setBaseValue(scaled);
            boss.setHealth((float) scaled);
        }
        AttributeInstance attack = boss.getAttribute(Attributes.ATTACK_DAMAGE);
        if (attack != null) {
            attack.setBaseValue(attack.getBaseValue() * dmgMultiplier);
        }

        NexusCore.LOGGER.info("Scaled boss {} for {} players (x{} HP, x{} damage).",
                key(boss), extraPlayers + 1, String.format("%.2f", hpMultiplier), String.format("%.2f", dmgMultiplier));
    }

    @SubscribeEvent
    public static void onBossHurt(LivingHurtEvent event) {
        LivingEntity victim = event.getEntity();
        if (victim.level().isClientSide() || !isBoss(victim)) {
            return;
        }
        float cap = isAntiColossus(event) ? NexusConfig.BOSS.antiColossusDamageCap
                                          : NexusConfig.BOSS.maxDamageCapPerHit;
        if (event.getAmount() > cap) {
            event.setAmount(cap);
        }
    }

    private static boolean isBoss(LivingEntity entity) {
        return NexusConfig.isBossId(key(entity));
    }

    private static String key(LivingEntity entity) {
        ResourceLocation id = ForgeRegistries.ENTITY_TYPES.getKey(entity.getType());
        return id == null ? "" : id.toString();
    }

    /**
     * Anti-colossus is decided by data, never by display names: the damage type id,
     * an item tagged nexus:anti_colossus, or a configured TaCZ gun id. TaCZ stores
     * the gun id in the "GunId" NBT string because every gun shares one item.
     */
    private static boolean isAntiColossus(LivingHurtEvent event) {
        if (event.getSource().getMsgId().contains("anti_colossus")) {
            return true;
        }
        Entity attacker = event.getSource().getEntity();
        if (!(attacker instanceof LivingEntity living)) {
            return false;
        }
        ItemStack held = living.getMainHandItem();
        if (held.isEmpty()) {
            return false;
        }
        if (held.is(NexusTags.ANTI_COLOSSUS)) {
            return true;
        }
        CompoundTag tag = held.getTag();
        return tag != null && NexusConfig.isAntiColossusGun(tag.getString("GunId"));
    }
}
