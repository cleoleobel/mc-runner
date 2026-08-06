package com.nexus.core;

import com.nexus.core.config.NexusConfig;
import com.nexus.core.init.ItemInit;
import net.minecraftforge.eventbus.api.IEventBus;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.event.lifecycle.FMLCommonSetupEvent;
import net.minecraftforge.fml.javafmlmod.FMLJavaModLoadingContext;
import net.minecraftforge.fml.loading.FMLPaths;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

@Mod(NexusCore.MOD_ID)
public class NexusCore {

    public static final String MOD_ID = "nexus";
    public static final Logger LOGGER = LogManager.getLogger(MOD_ID);

    public NexusCore() {
        IEventBus modEventBus = FMLJavaModLoadingContext.get().getModEventBus();
        ItemInit.ITEMS.register(modEventBus);
        ItemInit.TABS.register(modEventBus);
        modEventBus.addListener(this::setup);
    }

    private void setup(final FMLCommonSetupEvent event) {
        // enqueueWork keeps config loading off the parallel mod-loading threads.
        event.enqueueWork(() -> NexusConfig.load(FMLPaths.CONFIGDIR.get().resolve("nexus")));
    }
}

