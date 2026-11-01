# Persistent project memory

Explicit user decisions, not inferred preferences. Updated November 1, 2026.

- **Mech appearance:** The complete original ivory/navy knight illustration is Oathkeeper's visual authority (`assets/art/mechs/concepts/oathkeeper.png`). The user rejected both assembled 2D cutout revisions. Passing functional checks does not establish visual approval.
- **Production approach (reconfirmed in the validation discussion):** Keep the game 2D. Use complete, faithful rigged 3D source models, animate them coherently, and render consistent sprites. The user clarified that this is the intended replacement for the bad cutout motion, rather than selecting live runtime 3D battles. Validate a matching still, then smooth motion at gameplay size before expansion. Do not return to disconnected generated body parts stretched through a generic 2D skeleton.
- **Interchangeable equipment:** Mech weapons and shields can change. Keep them separate from the body, with stable attachment points and consistent scale/grips. The starting sword and shield are an initial loadout, not permanent body geometry. Equipment must remain replaceable without rebuilding the mech or changing its identity.
- **Animation compatibility:** Future weapon classes may need their own attack/hold poses. Keep the body rig reusable and accommodate shield-dependent guard/block presentation. Do not assume every future weapon uses the starting sword animation.
- **Variety:** All four mech concepts are approved; Oathkeeper is the starting mech. Cinderjack, Kestrel, and Bastion are future production designs.
- **Visual workflow:** Compare the first model render directly with the original reference, including gameplay size, before expanding animations or integration. Keep all views derived from the same model and render setup. A sprite atlas is packaging, not the source of character consistency.

## Story and campaign decisions — November 1, 2026 interview

- **World:** Medieval magitech civilization; mechs are rare military assets and firearms are early/scarce. Traditional weapons remain useful.
- **Protagonist and relationships:** Player-named male with fixed noble history and customizable appearance/conduct. He and the princess are already deeply in love; the second prince was his close childhood friend. The princess is the eldest child, compassionate and politically sharp; the emperor's first son died before the coup.
- **Cause of the coup:** The emperor has the second prince's mother assassinated to erase the shame of the concubine relationship, then plans to kill the prince out of unfounded fear for his daughter. The prince initially intended no harm to his sister or her succession and strikes first to survive. The archduke knew nothing of the persecution.
- **Hunt and betrayal:** The prince wrongly believes the archduke and protagonist were accomplices and seeks the protagonist's capture, imprisonment, and execution. His commander kills the archduke during the escape. A treacherous relative takes the protagonist's domain as one of the twelve loyalist noble seats.
- **Politics:** Ten nobles begin as independent competing factions that can form blocs; twelve initially support the usurper. Keep 22 total seats. Allied nobles provide background campaign support through troops, funding, access, territory, diplomacy, and armies. Captured nobles do not automatically join. This supersedes the earlier 1–3 allied noble-pilot deployment idea.
- **Rescue and branch:** Learn the old emperor's crimes before the midpoint decision. Three of the twelve loyalists offer four veteran formations, an advanced unassigned mech frame, and gold if the player abandons the princess. They want a dependent ruler. Refusing makes their elite force an enemy; accepting is an explicit permanent fork, with no later return to restoration.
- **Princess and endings:** Restoration uses a midpoint prison raid before capital conquest; she then leads politically and can pilot a mech. On the dark route she organizes an independent escape with an ally and survives in exile. Both routes settle the whole imperial war. The prince refuses surrender and dies fighting. Restoration ends with empress/prince-consort marriage; the alternate route crowns the protagonist.
- **Throne:** It amplifies personal magic/perception and contributes to dependence and corruption, without removing the prince's responsibility. Its influence on the old emperor remains uncertain. The happy ending destroys its magical mechanism.
- **Battle size and pilots:** Up to ten commandable units per side ordinarily, fifteen in major battles/sieges. Each deployed mech, cannon, or troop formation counts as one. Up to five companions; all are mech pilots and need an assigned available frame. Allied nobles are campaign support, while the protagonist, princess, and companions are personal hero pilots.
- **Banner:** Simple crest creator with two colors and one centered preset emblem.
- **Mech ownership:** Buy, receive, retain, store/hide, and swap frames; use distinct frames with fitted equipment/modules rather than full body-part assembly. Shared reserve inventory is accessible at any friendly workshop. Begin with only Oathkeeper.
- **Inventory:** Shared party mech gear, modules, loot, and trade goods; ordinary soldiers upgrade as formations. No individual human equipment inventory in the selected scope.

New character/house names, ages, companion concepts, the first son's border-war death, and detailed implementation defaults are authored drafts in the plans; do not present them as separately user-specified facts or new visual approvals.

Current art work: `plan/mech-art-direction.md` and `docs/mech-production-brief.md`. Story authority: `plan/story-canon.md`. Adopted campaign systems and staged acceptance criteria: `plan/campaign-refinement.md`. Milestone history: `plan/initial-plan.md`. Gap audit and remaining gates: `plan/validation-review.md`.

## Implementation status — separate from user design decisions

Prototype 0.2 adds a title-screen Workshop review with its own save, frame ownership/pilot assignment, repairs/refits/modules, cargo trade, banner preview, and loadout practice. The real village workshop opens after its defense. Campaign saves migrate from schema 1 to 2. See `qa/prototype-0.2-review.md` for verification and limits.

The existing 3D model study is still unapproved, unrigged, and unanimated. Art review compares it with the original; it does not approve the study or replace battle art. Do not mistake the workshop prototype's functional completion for acceptance of the rejected cutout renderer or permission to bypass the still/motion review sequence.


Prototype 0.3 (November 2) connects the preserved opening/workshop to a bounded four-settlement regional loop, five roaming party kinds, timed incidents, guild cargo deliveries, paid recruitment, one house-support pact and supply raids. Regional battles use locked owned-frame/formation snapshots, cover, rough terrain, seven roles, abilities and persistent casualties/replenishment. Ordinary fields are 14×10; separate 10-v-10/15-v-15 capacity practices include allies in the shared cap. Saves migrate schemas 1/2 to 3. Regional review has its own save and no headquarters. See `qa/prototype-0.3-review.md` and `docs/regional-combat-rules.md` for actual verification and limits. This is implementation status, not a new user design decision or completion of the full campaign.

New regional battles use explicitly temporary original 2D tactical symbols. The original opening/trial retain their old renderer. No source model, rig, animation, still/motion approval, or runtime-3D decision changed.
