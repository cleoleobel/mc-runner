package com.nexus.core.mixin;

import net.minecraft.world.entity.EquipmentSlot;
import net.minecraft.world.entity.decoration.ArmorStand;
import net.minecraft.world.item.ItemStack;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(ArmorStand.class)
public class ArmorStandMixin {
    @Inject(method = "getItemBySlot", at = @At("HEAD"), cancellable = true)
    private void nexus$fixIronsSpellbooksCrash(EquipmentSlot slot, CallbackInfoReturnable<ItemStack> cir) {
        if (slot.getType() == EquipmentSlot.Type.HAND && slot.getIndex() >= 2) {
            cir.setReturnValue(ItemStack.EMPTY);
        }
    }
}
