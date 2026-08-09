package com.nexus.core.mixin;

import net.minecraft.world.entity.MobCategory;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Pseudo;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.ModifyArg;

/**
 * Cataclysm Spellbooks 1.2.9 registers its two laser projectiles as monsters.
 * Forge consequently tries to attach living-entity attributes to non-living
 * projectile classes and logs hundreds of errors during every datapack load.
 */
@Pseudo
@Mixin(
        targets = "net.acetheeldritchking.cataclysm_spellbooks.registries.CSEntityRegistry",
        remap = false
)
public abstract class CataclysmSpellbooksEntityRegistryMixin {

    @ModifyArg(
            method = {"lambda$static$11", "lambda$static$12"},
            at = @At(
                    value = "INVOKE",
                    target = "Lnet/minecraft/world/entity/EntityType$Builder;m_20704_(Lnet/minecraft/world/entity/EntityType$EntityFactory;Lnet/minecraft/world/entity/MobCategory;)Lnet/minecraft/world/entity/EntityType$Builder;",
                    remap = false
            ),
            index = 1,
            require = 2,
            remap = false
    )
    private static MobCategory nexus$categorizeLaserProjectilesCorrectly(MobCategory original) {
        return MobCategory.MISC;
    }
}
