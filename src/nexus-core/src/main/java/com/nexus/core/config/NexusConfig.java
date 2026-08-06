package com.nexus.core.config;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.nexus.core.NexusCore;

import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

public class NexusConfig {
    private static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();

    public static class BossConfig {
        public double healthScalingPerPlayer = 0.35; // +35% HP por jugador adicional
        public double damageScalingPerPlayer = 0.10; // +10% Daño por jugador adicional
        public float maxDamageCapPerHit = 75.0f;     // Cap máximo de daño por golpe a bosses sin anti-coloso
    }

    public static class MagicConfig {
        public double heavyArmorManaPenaltyMultiplier = 1.5; // +50% costo de mana portando MekaSuit/Armadura pesada
    }

    public static BossConfig BOSS = new BossConfig();
    public static MagicConfig MAGIC = new MagicConfig();

    public static void loadConfig(File configDir) {
        if (!configDir.exists()) {
            configDir.mkdirs();
        }

        File bossConfigFile = new File(configDir, "bosses.json");
        File magicConfigFile = new File(configDir, "magic.json");

        try {
            if (!bossConfigFile.exists()) {
                try (FileWriter writer = new FileWriter(bossConfigFile)) {
                    GSON.toJson(BOSS, writer);
                }
            } else {
                try (FileReader reader = new FileReader(bossConfigFile)) {
                    BOSS = GSON.fromJson(reader, BossConfig.class);
                }
            }

            if (!magicConfigFile.exists()) {
                try (FileWriter writer = new FileWriter(magicConfigFile)) {
                    GSON.toJson(MAGIC, writer);
                }
            } else {
                try (FileReader reader = new FileReader(magicConfigFile)) {
                    MAGIC = GSON.fromJson(reader, MagicConfig.class);
                }
            }
        } catch (IOException e) {
            NexusCore.LOGGER.error("Error cargando la configuración de Nexus Core: ", e);
        }
    }
}
