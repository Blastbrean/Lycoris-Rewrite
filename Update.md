# Deepwoken Rewrite
**Module diff vs. previous snapshot: +6/-3/~37 (added/removed/changed)**
```diff
+ (added) BoltcrusherRunning
+ (added) PromDraw
+ (added) ScarletCannon
+ (added) TornadoKick
+ (added) TridentSpear
+ (added) WindGun
- (removed) RailbladeCrit
- (removed) RapierCritical
- (removed) TwisterKicks
+ (changed) WeaponUppercutTest
+ (changed) RisingThunder
+ (changed) WeaponFlourishTest
+ (changed) CroccoTailWhip
+ (changed) SilentheartHeavyMayhem
+ (changed) IceDaggers
+ (changed) CroccoSwipes
+ (changed) ChaserSlam
+ (changed) TerrapodBarrage
+ (changed) ShadowGun
+ (changed) WeaponAerialAttackTest
+ (changed) ElectroCarveMagnet
+ (changed) HeavenlyWind
+ (changed) WardensBlade
+ (changed) FireEruption
+ (changed) SilentheartMediumMayhem
+ (changed) MetalKickNormal
+ (changed) Veinbreaker
+ (changed) WeaponRunningAttackTest
+ (changed) RapidSlashes
+ (changed) CroccoTripleBite
+ (changed) GroundSlideSilentheart
+ (changed) Scythe
+ (changed) SilentheartLightMayhem
+ (changed) RapidPunches
+ (changed) WeaponTest
+ (changed) CroccoGroundLeave
+ (changed) SilentheartLightRisingStar
+ (changed) ShadowRoar
+ (changed) SilentheartMediumRisingStar
+ (changed) PyreKeeperCritSliding
+ (changed) SilentheartHeavyRelentless
+ (changed) GolemBeam
+ (changed) SilentheartLightRelentless
+ (changed) EtherBarrage
+ (changed) SpearCritical
+ (changed) CrimsonRain
```

**Timing diff vs. previous snapshot: +10/-4/~188 (animation: +10/-1/~178, part: +0/-3/~10)**
```diff
+ (changed) Animation : RisingFlameWindup
+ (changed) Animation : 1_GenericSword1
+ (changed) Animation : 1_GenericSword2
+ (changed) Animation : 1_GenericFlourish
+ (changed) Animation : 2_GenericSpear1
+ (changed) Animation : 2_GenericSpear2
+ (changed) Animation : 2_GenericTwinblade2
+ (changed) Animation : 2_GenericTwinblade1
+ (changed) Animation : 1_GenericGreatsword2
+ (changed) Animation : 1_GenericGreatsword1
+ (changed) Animation : 1_GenericNavaeFlourish
+ (changed) Animation : 1_GenericGreatAxe1
+ (changed) Animation : 1_GenericGreatAxe2
+ (changed) Animation : 1_GenericGreatAxe3
+ (changed) Animation : 1_GenericGaleKata3
+ (changed) Animation : 1_GenericGaleKata1
+ (changed) Animation : 1_GenericGaleKata4
+ (changed) Animation : 1_GenericGaleKata2
+ (changed) Animation : 1_GenericNavae2
+ (changed) Animation : 1_GenericNavae1
+ (changed) Animation : 1_GenericNavae3
+ (changed) Animation : 2_GenericGreatsword1
+ (changed) Animation : 2_GenericGreatsword2
+ (changed) Animation : RapidPunches
+ (changed) Animation : 1_GenericMusket1
+ (added) Animation : Twinstrikes
+ (added) Animation : TwinstrikesFollowup
+ (changed) Animation : WindCarve
+ (changed) Animation : HeavenlyWind
+ (changed) Animation : 1_GenericMusket3
+ (changed) Animation : 1_GenericMusket2
+ (changed) Animation : SpearCritical
+ (changed) Animation : BoneBoyRushGo
+ (changed) Animation : StormseyeCrit
+ (changed) Animation : RisingThunder
+ (changed) Animation : LightningKick
+ (changed) Animation : KyrswynterCrit
+ (changed) Animation : KyrswynterCritRunning
+ (changed) Animation : ToonsM1_1
+ (changed) Animation : ToonsM1_2
+ (changed) Animation : ToonsM1_3
+ (changed) Animation : ToonsCrit2
+ (changed) Animation : ToonsCrit
+ (changed) Animation : ToonsCritAerial
+ (changed) Animation : PromDraw
+ (changed) Animation : MastersFlourish
+ (changed) Animation : SeraphSpearCrit
+ (changed) Animation : 1SwordSwing1
+ (changed) Animation : 1SwordSwing2
+ (changed) Animation : 1CurvedSwing1
+ (changed) Animation : 1CurvedSwing2
+ (added) Animation : 1CurvedSwing4?
+ (changed) Animation : MawbladesCrit
+ (changed) Animation : PetrasCritGo
+ (changed) Animation : PetrasCritFollowup
+ (changed) Animation : RailbladeM1_3
+ (changed) Animation : RailbladeM1_2
+ (changed) Animation : RailbladeM1_1
+ (changed) Animation : RailbladeCrit
+ (changed) Animation : Onslaught
+ (changed) Animation : MirrorIllusion
+ (changed) Animation : TridentSpearCrit
+ (changed) Animation : 1_GenericPistolShot2
+ (changed) Animation : 1_GenericPistolShot1
+ (changed) Animation : 1_GenericPistol1
+ (changed) Animation : 1_GenericPistolShot3
+ (changed) Animation : 1_GenericPistol2
+ (changed) Animation : GroundSlideSilentheart
+ (changed) Animation : SlientheartLightRelentless
+ (changed) Animation : RisingStarLightSilentheart
+ (changed) Animation : SilentheartLightMayhem
+ (changed) Animation : MayhemSilentheart
+ (changed) Animation : SharkoQuadSwipe
+ (changed) Animation : SharkoSwipe
+ (changed) Animation : DoubleSharkoSwipe
+ (changed) Animation : GolemSmack
+ (changed) Animation : GolemStomp
+ (changed) Animation : GolemDoubleSlam
+ (changed) Animation : EnforcerSwing1
+ (changed) Animation : EnforcerSwing2
+ (changed) Animation : EnforcerKick
+ (changed) Animation : WyrmCrit
+ (changed) Animation : RapierCritical
+ (changed) Animation : SpectralM1_1
+ (changed) Animation : SpectralM1_2
+ (changed) Animation : SpectralM1_3
+ (changed) Animation : SpectralCrit
+ (changed) Animation : 1_GenericRapier1
+ (changed) Animation : 1_GenericRapier2
+ (changed) Animation : 1_GenericDagger2
+ (changed) Animation : 1_GenericDagger1
+ (changed) Animation : 1_GenericDagger3
+ (changed) Animation : 2_GenericPistol2
+ (changed) Animation : ElectroCarveMagnet
+ (changed) Animation : MetalDropKick
+ (changed) Animation : MetalLegDrop
+ (changed) Animation : Scythe_1
+ (changed) Animation : Scythe_2
+ (changed) Animation : IceForgeCast
+ (changed) Animation : LightningStream
+ (changed) Animation : PyreKeeperCritRunningWindup
+ (changed) Animation : 1_GenericKaritaFlourish
+ (changed) Animation : 1_GenericKarita3
+ (changed) Animation : PyreKeeperM1_2
+ (changed) Animation : FlameRepulsion
+ (changed) Animation : 1_GenericLegionKata3
+ (changed) Animation : PurpleCloud3
+ (changed) Animation : 1_GenericKarita2
+ (changed) Animation : 1_GenericLegionKataFlourish
+ (changed) Animation : PurpleCloud2
+ (changed) Animation : 1_GenericLegionKata2
+ (changed) Animation : PyreKeeperM1_1
+ (changed) Animation : 2_GenericPistol1
+ (changed) Animation : PyreKeeperCrit
+ (changed) Animation : PyreKeeperM1_3
+ (changed) Animation : 1_GenericKarita1
+ (changed) Animation : PurpleCloud1
+ (changed) Animation : 1_GenericLegionKata1
+ (changed) Animation : 1_GenericFangCoil3
+ (changed) Animation : 1_GenericFangCoil2
+ (changed) Animation : 1_GenericFangCoil1
+ (changed) Animation : ShoulderBashWindup
+ (changed) Animation : ShoulderBashGo
+ (changed) Animation : RailbladeCritAerial
+ (changed) Animation : 1_GenericSpear1
+ (changed) Animation : 1_GenericSpear2
+ (changed) Animation : TwisterKicks
+ (changed) Animation : 2_GenericBow2
+ (changed) Animation : 2_GenericBow3
+ (changed) Animation : 2_GenericBow1
+ (changed) Animation : ImperialVortexGo
+ (changed) Animation : 2_GenericBowFlourish
+ (changed) Animation : WindForge
+ (changed) Animation : ScarletCyclone
+ (changed) Animation : Veinbreaker
+ (changed) Animation : Windgun
+ (added) Animation : TempestWind
+ (changed) Animation : BoltcrusherCritRunning
+ (changed) Animation : 1_GenericHeavyAerial
+ (changed) Animation : WardenBladeWindup
+ (changed) Animation : BloodFoulerM1_2
+ (changed) Animation : BloodFoulerM1_1
+ (changed) Animation : BlooudFoulerM1_3
+ (changed) Animation : JetstrikerKick
+ (changed) Animation : CoralSmash
+ (changed) Animation : JetstrikerFakeStrike
+ (changed) Animation : RapidSlashes
+ (changed) Animation : KaritaLeap
+ (changed) Animation : ShadowEruptionCast
+ (changed) Animation : ScalesplitterCrit
+ (changed) Animation : 1_GenericSwordAerial
+ (changed) Animation : FlashdrawStrike
+ (changed) Animation : CloseShave
+ (changed) Animation : PrecisionCuts
+ (changed) Animation : ShadowRoarWindup
+ (added) Animation : ShadowRoar
- (removed) Animation : ShadowRisingWind
+ (changed) Animation : AstralWind
+ (added) Animation : RiteCritSlam
+ (added) Animation : RiteCrit
+ (changed) Animation : FalchionCrit
+ (added) Animation : TitusVent
+ (added) Animation : FirstLight1
+ (added) Animation : FirstLight2
+ (changed) Animation : EclipseKick
+ (changed) Animation : WindKick
+ (changed) Animation : DaggerThrow
+ (changed) Animation : GreatMaulCrit
+ (changed) Animation : KanaboCrit
+ (changed) Animation : FractineCrit
+ (changed) Animation : LightningAssault
+ (changed) Animation : WindHerCrit
+ (changed) Animation : OfficerSaberCrit
+ (changed) Animation : SanguineDive
+ (changed) Animation : 1Inferno1
+ (changed) Animation : 1Inferno3
+ (changed) Animation : 1Inferno2
+ (changed) Animation : 1_GenericGreatcannon2
+ (changed) Animation : 1_GenericGreatcannon1
+ (changed) Animation : 1_GenericTwinblade3
+ (changed) Animation : 1_GenericTwinblade2
+ (changed) Animation : 1_GenericTwinblade1
+ (changed) Animation : 2Inferno3
+ (changed) Animation : 2Inferno2
+ (changed) Animation : 2Inferno1
+ (changed) Animation : BloodtideRitual
+ (changed) Animation : BloodtideRitualStart
+ (changed) Animation : RazorBlitz
+ (changed) Animation : VeinTendrils
+ (changed) Part : MetalTurret
+ (changed) Part : TrialOrbs
- (removed) Part : LightningStrike
- (removed) Part : Cube
+ (changed) Part : AbyssalRidge
+ (changed) Part : ArdourSlice
+ (changed) Part : LightningStreamPart
+ (changed) Part : ScarletCannon
+ (changed) Part : Shard
+ (changed) Part : RisingShadow
+ (changed) Part : WindKickBrick
- (removed) Part : IceDagger
+ (changed) Part : BloodCyclone
```

**New features?**
```diff
+ (added) Auto Loot
+ (added) Auto Ragdoll Cancel
+ (added) Optional Bloxstrap RPC
+ (added) BR ESP Fix
+ (added) Empty Bone Altar + Visible Obelisk + Bone ESP
```
**Sorry for the big delay. It was a majority of school taking up freetime, coding stuff, and being unmotivated.**
**The 'Echo Farm' will come when Auto Execute is consistent on atleast one executor.**

*Your commit ID should == "7323c0" when the update is fully pushed to you.*