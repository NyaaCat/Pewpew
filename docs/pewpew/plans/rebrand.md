# Pewpew Rebrand Plan (Draft)

## Branding surfaces to update
- Server name and version strings (Bukkit and server list ping).
- Build metadata (Gradle group/artifact/version naming).
- Any visible "Paper" branding in logs or configs.

## Proposed steps
1) Update build info defaults (brand id/name).
2) Verify brand propagation to Bukkit, mod name, and brand packet.
3) Update build metadata and docs.
4) Add a config override if needed.

## Exact code targets (1.21.8)
- `tmp/paper-1.21.8/paper-server/src/main/java/io/papermc/paper/ServerBuildInfoImpl.java`
  - `BRAND_PAPER_NAME` default -> change to "Pewpew".
  - Manifest attributes `Brand-Id` and `Brand-Name` are read here; ensure build pipeline writes Pewpew values.
- `tmp/paper-1.21.8/paper-server/src/main/java/org/bukkit/craftbukkit/CraftServer.java`
  - `serverName` uses `ServerBuildInfo.buildInfo().brandName()`; should reflect Pewpew after build info changes.
- `tmp/paper-1.21.8/paper-server/src/main/java/net/minecraft/server/MinecraftServer.java`
  - `getServerModName()` returns `ServerBuildInfo.buildInfo().brandName()` (used in brand payload).
- `tmp/paper-1.21.8/paper-server/src/main/java/net/minecraft/server/network/ServerConfigurationPacketListenerImpl.java`
  - Sends `BrandPayload(this.server.getServerModName())` to clients.
- `tmp/paper-1.21.8/paper-server/src/main/java/io/papermc/paper/PaperBootstrap.java`
  - Startup log includes `brandName()` (auto-updated by build info).
- `tmp/paper-1.21.8/paper-server/src/main/java/org/bukkit/craftbukkit/CraftCrashReport.java`
  - Includes `BrandInfo` string from build info.

## Build metadata targets (when full fork is set up)
- `build.gradle.kts` / `gradle.properties` (group, archives base, version strings).
- Manifest attributes (Brand-Id, Brand-Name) set by the build pipeline.
- Paper API: if `ServerBuildInfo.BRAND_PAPER_ID` exists in the API module, update to a Pewpew brand id.

## Compatibility notes
- Do not change package names or public API signatures.
- Keep Bukkit/Paper plugin compatibility intact.
