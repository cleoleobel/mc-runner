package com.nexus.core;

import com.nexus.core.config.NexusConfig;
import com.nexus.core.init.ItemInit;
import net.minecraftforge.common.MinecraftForge;
import net.minecraftforge.eventbus.api.IEventBus;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.event.lifecycle.FMLCommonSetupEvent;
import net.minecraftforge.fml.javafmlmod.FMLJavaModLoadingContext;
import net.minecraftforge.fml.loading.FMLPaths;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

@Mod(NexusCore.MOD_ID)
public class NexusCore {
    public static final String MOD_ID = "nexuscore";
    public static final Logger LOGGER = LogManager.getLogger(MOD_ID);

    public NexusCore() {
        IEventBus modEventBus = FMLJavaModLoadingContext.get().getModEventBus();

        ItemInit.ITEMS.register(modEventBus);
        modEventBus.addListener(this::setup);

        MinecraftForge.EVENT_BUS.register(this);
    }

    private void setup(final FMLCommonSetupEvent event) {
        LOGGER.info("Inicializando Nexus Core...");
        NexusConfig.loadConfig(FMLPaths.CONFIGDIR.get().resolve("nexus").toFile());
    }
}
