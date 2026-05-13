# undrmnd — Swift build brief

## Project update

**undrmnd** is a **spatial public learning library** for iOS (Swift), not a conventional feed product and not an AI tutor. The app centers on **Strata** as the core knowledge object and uses a 2D spatial canvas with **fog-of-war** reveal logic as the primary navigation model.

The visual language remains **e‑ink inspired**. The app keeps low-stimulation, anti-addiction design principles while becoming more legible, more self-explaining, and more structurally distinct.

## Core thesis

Democratize research and continued education by making public learning feel socially alive, contribution-based, and accessible without requiring credentials.

Behavioral design is the **delivery vehicle**, not the mission. undrmnd uses **counter-algorithmic** design to redirect attention away from compulsive feed behavior and toward curiosity, contribution, and community-backed learning.

## Product definition

undrmnd should be framed as a **public learning organism**. It grows when people read, connect, and build together, especially through lightweight contributions and stranger-matching around nearby interests.

**AI** should be used sparingly: help understand user intent semantically and surface related content or people more intelligently than regex or rigid tags—but not as an oracle, not to decide what users should think about, and not to replace the community’s intellectual work.

## Primary interaction unit: Strata

A **Strata** is the atomic object of the product—treated as a structured knowledge object rather than a post.

Recommended Strata fields (see `Strata.swift` in the app target):

- Title  
- Plain-language summary  
- Source or origin  
- Topic tags  
- Related Strata IDs  
- Contribution prompts  
- Verification or context state  
- Attached field notes  
- Visibility state on the map  

This schema supports **forkability** later; the schema matters as much as the UI.

## Spatial engine (four layers)

1. **Objects** — Strata with schema and contribution state.  
2. **Placement** — Strata on a 2D map by topical affinity, lineage, or community clustering—not chronology. Nearby objects should feel conceptually adjacent.  
3. **Reveal logic** — Fog-of-war: users see one revealed island and partially obscured terrain; reading and contributing clears neighboring regions gradually.  
4. **Relationship logic** — Soft relationships: *related to*, *built from*, *contributed near*, *answered by*, *field note attached to*—visual and navigable without a heavy academic graph feel.

## First-use onboarding (direction)

Replace dependence on About-only explanation; start from **user choice**.

1. Interstitial with a single **Continue**.  
2. Quiet threshold: **Choose a place to begin**.  
3. Search field first, using existing Supabase-backed example chips as prompts.  
4. Supporting line: **Your first search reveals part of the library.**  
5. After chip or query, seed a first island of Strata around that topic.  
6. Show: **This library opens as people read and build.**  
7. Open one Strata from the starter cluster.  
8. One lightweight contribution.  
9. Clear a neighboring area as feedback.

Teaching by **action**, not walls of text.

## Fog-of-war visual direction

- E‑ink / Paperwhite-adjacent bitmap texture  
- Pixel / dither feel, softer and more atmospheric than retro game fog  
- Denser texture in obscured regions; lighter at the transition edge  
- Gentle grain and ghosting, not glossy blur  
- Monochrome or near-monochrome  

Implementation in Swift favors **noise or dither mask**, **multiple alpha bands** at the reveal edge, **tiled low-res texture** for dense fog + lighter stipple at edge, **subtle motion** (paper clearing, not smoke).

## Community & field notes

Emphasize **commons** behavior over audience capture: stranger-matching around adjacent curiosities, contribution over performance, shared-library language.

**Field notes** bridge offline observation into the commons—optional attachment to Strata or map regions; personal archive on profile.

## What undrmnd is not

- Not an AI oracle  
- Not a social feed  
- Not a conventional gamified learning app  
- Not a productivity dashboard  
- Not credentials-first academic gatekeeping  

## Build priorities (snapshot)

1. Home communicates the **spatial model** immediately.  
2. **Strata** as a schema-backed object.  
3. **Fog reveal** interaction prototype.  
4. **Action-based** onboarding replacing explanation-heavy flow.  
5. One **contribution loop** that visibly changes the world.  
6. Prepare for stranger-matching without overbuilding social.
