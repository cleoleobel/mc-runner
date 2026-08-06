package com.nexus.core.config;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonSyntaxException;
import com.nexus.core.NexusCore;

import java.io.IOException;
import java.io.Reader;
import java.io.Writer;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Balance values live in JSON so they can be tuned without recompiling.
 * Written to config/nexus/ on first run, re-read on every server start.
 */
public final class NexusConfig {

    private static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();

    public static final class BossConfig {
        /** Extra max-health per additional player in range, as a fraction. */
        public double healthScalingPerPlayer = 0.35;
        /** Extra attack damage per additional player in range, as a fraction. */
        public double damageScalingPerPlayer = 0.10;
        /** Radius used to count players when a boss enters the world. */
        public double playerScanRadius = 64.0;
        /** Hard ceiling of damage a single hit may deal to a boss. */
        public float maxDamageCapPerHit = 75.0f;
        /** Anti-colossus sources bypass the cap but are still limited to this. */
        public float antiColossusDamageCap = 400.0f;
        /**
         * TaCZ gun ids that count as anti-colossus. All TaCZ guns share one item,
         * so they cannot be told apart by item tag; the id lives in the "GunId" NBT.
         */
        public List<String> antiColossusGunIds = Arrays.asList(
                "nexus_weapons:anti_colossus_rifle"
        );
        /**
         * Explicit boss registry IDs. Substring matching is deliberately NOT used:
         * it would classify every Cataclysm/EEEAB trash mob (and wither skeletons)
         * as a boss.
         */
        public List<String> bossEntities = Arrays.asList(
                "minecraft:wither",
                "minecraft:ender_dragon",
                "cataclysm:the_leviathan",
                "cataclysm:ignis",
                "cataclysm:netherite_monstrosity",
                "cataclysm:ender_guardian",
                "cataclysm:the_harbinger",
                "cataclysm:ancient_remnant",
                "cataclysm:scylla",
                "cataclysm:coralssus",
                "cataclysm:maledictus",
                "cataclysm:wadjet",
                "cataclysm:kobolediator",
                "cataclysm:aptrgangr",
                "cataclysm:the_prowler",
                "cataclysm:symbiocto",
                "eeeabsmobs:nameless_guardian",
                "eeeabsmobs:realm_warden",
                "eeeabsmobs:immortal",
                "eeeabsmobs:relic_observer",
                "eeeabsmobs:relic_ripper",
                "eeeabsmobs:relic_earthshaker",
                "eeeabsmobs:relic_annihilator"
        );
    }

    public static final class MagicConfig {
        /** Set false to disable the armour/magic trade-off entirely. */
        public boolean enableHeavyArmorPenalty = true;
        /** Fraction of max mana removed while wearing heavy armour (0.35 = -35%). */
        public double heavyArmorMaxManaPenalty = 0.35;
        /** Fraction of spell power removed while wearing heavy armour. */
        public double heavyArmorSpellPowerPenalty = 0.20;
        /** Armour item IDs that trigger the penalty. Checked as exact registry IDs. */
        public List<String> heavyArmorItems = Arrays.asList(
                "mekanism:mekasuit_helmet",
                "mekanism:mekasuit_bodyarmor",
                "mekanism:mekasuit_pants",
                "mekanism:mekasuit_boots",
                "mekanism:hazmat_mask",
                "mekanism:hazmat_gown",
                "mekanism:hazmat_pants",
                "mekanism:hazmat_boots",
                "minecraft:netherite_helmet",
                "minecraft:netherite_chestplate",
                "minecraft:netherite_leggings",
                "minecraft:netherite_boots",
                "cataclysm:ignitium_helmet",
                "cataclysm:ignitium_chestplate",
                "cataclysm:ignitium_leggings",
                "cataclysm:ignitium_boots"
        );
    }

    public static BossConfig BOSS = new BossConfig();
    public static MagicConfig MAGIC = new MagicConfig();

    /** Resolved once at load so the hot path never parses strings. */
    private static Set<String> bossIdCache = new HashSet<>();
    private static Set<String> heavyArmorCache = new HashSet<>();
    private static Set<String> antiColossusGunCache = new HashSet<>();

    private NexusConfig() {
    }

    public static boolean isBossId(String registryId) {
        return bossIdCache.contains(registryId);
    }

    public static boolean isAntiColossusGun(String gunId) {
        return antiColossusGunCache.contains(gunId);
    }

    public static boolean isHeavyArmorId(String registryId) {
        return heavyArmorCache.contains(registryId);
    }

    public static void load(Path configDir) {
        try {
            Files.createDirectories(configDir);
            BOSS = read(configDir.resolve("bosses.json"), BossConfig.class, new BossConfig());
            MAGIC = read(configDir.resolve("magic.json"), MagicConfig.class, new MagicConfig());
        } catch (IOException e) {
            NexusCore.LOGGER.error("Could not prepare NEXUS config directory {}; using defaults.", configDir, e);
            BOSS = new BossConfig();
            MAGIC = new MagicConfig();
        }
        bossIdCache = BOSS.bossEntities == null ? new HashSet<>() : new LinkedHashSet<>(BOSS.bossEntities);
        heavyArmorCache = MAGIC.heavyArmorItems == null ? new HashSet<>() : new LinkedHashSet<>(MAGIC.heavyArmorItems);
        antiColossusGunCache = BOSS.antiColossusGunIds == null ? new HashSet<>()
                : new LinkedHashSet<>(BOSS.antiColossusGunIds);
        NexusCore.LOGGER.info("NEXUS config loaded: {} boss ids, {} heavy armour ids, {} anti-colossus guns.",
                bossIdCache.size(), heavyArmorCache.size(), antiColossusGunCache.size());
    }

    private static <T> T read(Path file, Class<T> type, T fallback) {
        if (!Files.exists(file)) {
            write(file, fallback);
            return fallback;
        }
        try (Reader reader = Files.newBufferedReader(file, StandardCharsets.UTF_8)) {
            T parsed = GSON.fromJson(reader, type);
            // GSON returns null for an empty or all-whitespace file.
            if (parsed == null) {
                NexusCore.LOGGER.warn("{} is empty; restoring defaults.", file.getFileName());
                write(file, fallback);
                return fallback;
            }
            return parsed;
        } catch (IOException | JsonSyntaxException e) {
            NexusCore.LOGGER.error("{} is invalid; using built-in defaults (file left untouched).",
                    file.getFileName(), e);
            return fallback;
        }
    }

    private static <T> void write(Path file, T value) {
        try (Writer writer = Files.newBufferedWriter(file, StandardCharsets.UTF_8)) {
            GSON.toJson(value, writer);
        } catch (IOException e) {
            NexusCore.LOGGER.error("Could not write {}.", file.getFileName(), e);
        }
    }
}
