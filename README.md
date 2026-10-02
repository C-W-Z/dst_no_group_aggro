# 无群体仇恨（又名关我屁事）No Group Aggro (aka Not My Business)

[h2]如果你喜欢我的模组，请点赞并收藏！[/h2]
[img]https://steamuserimages-a.akamaihd.net/ugc/27680204237595119/AD467A988E9C966C580668CA6BFECE0849A48893/[/img]

本模组又名：我打你同伴关你屁事，雨女无瓜！
[h2]模组介绍[/h2]
现在各种生物被攻击时，同伴会选择看戏而不是上前帮忙！
有了这个MOD，再也不怕不小心打到猪人或牛了，你也可以和企鸥单挑了！
本模组移除了青蛙、皮弗娄牛、猪人、企鸥等生物的群体仇恨机制。每种生物可单独开关，不影响玩家雇佣的生物。
[spoiler]其实制作这个模组是因为我玩模组时，随从常常不小心打到牛之类的群体仇恨生物导致被围殴致死[/spoiler]

[h2]支援的生物列表[/h2]
[list]
[*] 蜜蜂：单独控制普通蜜蜂和杀人蜂之间的群体仇恨传播，不含嗡嗡蜜蜂。不会改变蜜蜂自身反击或主动索敌。
[*] 蜂巢：单独控制野生普通蜂巢的放蜂反应（包含巢外蜜蜂被攻击或捕捉时的放蜂）。可选择原版（被攻击时放出有仇恨的杀人蜂）或无仇恨普通蜜蜂，不影响杀人蜂巢。
[*] 蜂箱：包含隐士蜂箱，可选择原版或安全蜂箱。安全模式下采蜜不放蜂，其他放蜂反应放出无仇恨的普通蜜蜂。
[*] 三项可独立设置；蜂巢和蜂箱的无仇恨放蜂不会关闭巢外蜂群的仇恨传播，也不会改变春季等主动索敌行为。蜂巢、蜂箱默认跟随蜜蜂设置，以兼容已有玩家：旧原版保持三项原版，旧选项1保持无群体仇恨、无仇恨普通蜜蜂及安全蜂箱，旧选项2保持无群体仇恨、原版蜂巢及安全蜂箱。旧蜜蜂设置的 key 和选项值不变，不必重设；旧 modoverrides.lua 未包含新选项时也沿用旧行为。蜂巢、蜂箱明确选为原版或安全模式时，优先采用独立设置。
[*] 青蛙、明眼青蛙
[*] 皮弗娄牛、小皮弗娄牛
[*] 猪人、猪人守卫和疯猪（不含面具猪人）
[*] 兔人（不含舒适兔人、皇家兔子警卫和面具兔人）
[*] 鱼人、忠诚鱼人守卫（不含面具鱼人）
[*] 企鸥、永冻企鸥
[*] 水獭掠夺者
[*] 充电伏特羊
[*] 石虾（不含面具石虾）
[*] 穴居猴
[/list]

[img]https://images.steamusercontent.com/ugc/11237512703173357918/85197A2790A4E3D09E56BB81F20DD46B0F408375/[/img]
[img]https://images.steamusercontent.com/ugc/12214714446227910701/12B3B08D2BE832B9A0BDEDB7EE696466741CEF1D/[/img]

[h2]注意事项[/h2]
[list]
[*] 不会改变生物的主动仇恨范围，因此对于索敌范围大的主动敌对生物效果可能较不明显，使用远程武器才比较容易感受到，例如鱼人、猪人守卫、永冻企鸥、充电伏特羊。
[/list]

[h2]未来计划[/h2]
[list]
[*] 移除更多生物的群体仇恨机制
[*] 众多蜘蛛以及韦伯蜘蛛的仇恨机制正在研究中，预计下版本会加入蜘蛛相关选项
[/list]

[url=https://github.com/C-W-Z/dst_no_group_aggro]GitHub Repo Here[/url]

# No Group Aggro (aka Not My Business) 无群体仇恨（又名关我屁事）

[h2]If you like my mod, please thumbs up and favorite![/h2]
[img]https://steamuserimages-a.akamaihd.net/ugc/27680204237595119/AD467A988E9C966C580668CA6BFECE0849A48893/[/img]

[h2]Mod Introduction[/h2]
Now when creatures are attacked, their companions will just mind their own business instead of helping!
With this mod, you'll never have to worry about accidentally hitting a pigman or a beefalo again, and you can even fight a pengull 1-vs-1!
This mod removes the group aggro mechanics of creatures such as frogs, beefalos, pigmen, and pengulls. Each creature can be toggled individually, and player-hired followers are not affected.
[spoiler]I made this mod because when I was playing mods, my followers often accidentally hit creatures like cows, resulting in them being ganged up on and killed.[/spoiler]

[h2]Supported Creatures List[/h2]
[list]
[*] Bees: independently controls aggro sharing between regular and Killer Bees, excluding Grumble Bees. Does not change individual retaliation or active targeting.
[*] Bee Hives: independently controls regular wild hive releases, including releases when their bees are attacked or netted. Choose Vanilla (attacks release aggressive Killer Bees) or untargeted regular bees. Excludes Killer Bee Hives.
[*] Bee Boxes: includes Hermit Bee Boxes. Choose Vanilla or Safe Bee Boxes. Safe mode prevents harvest releases and releases untargeted regular bees in other cases.
[*] Untargeted hive or box releases do not disable outdoor aggro sharing or active targeting, such as in spring. Hive and Box settings default to Follow Bees Setting for compatibility: old Vanilla keeps all three vanilla; old option 1 retains disabled bee aggro sharing, untargeted regular hive bees, and safe boxes; old option 2 retains disabled bee aggro sharing, vanilla hive releases, and safe boxes. The old Bees key and option values are unchanged, so existing settings need no reset. Old modoverrides.lua files missing the new keys also retain old behavior. Explicit Hive and Box selections override inheritance.
[*] Frogs, Bright-Eyed Frogs
[*] Beefalos, Baby Beefalos
[*] Pigmen, Guard Pigs, and Werepigs (excludes Enthralled Pigmen)
[*] Bunnymen (excludes Cozy Bunnymen, Royal Rabbit Enforcer, and Enthralled Bunnymen)
[*] Merms, Loyal Merm Guards (excludes Enthralled Merms)
[*] Pengulls, Mutated Pengulls
[*] Marotter
[*] Charged Lightning Goats
[*] Rock Lobsters (excludes Enthralled Rock Lobsters)
[*] Splumonkey
[/list]

[img]https://images.steamusercontent.com/ugc/11237512703173357918/85197A2790A4E3D09E56BB81F20DD46B0F408375/[/img]
[img]https://images.steamusercontent.com/ugc/12214714446227910701/12B3B08D2BE832B9A0BDEDB7EE696466741CEF1D/[/img]

[h2]Notes[/h2]
[list]
[*] This does not change the active aggro range of creatures. Therefore, the effect might be less noticeable for actively hostile creatures with large aggro radii (e.g., Merms, Pig Guards, Mutated Pengulls, Charged Lightning Goats) unless you use ranged weapons.
[/list]

[h2]Future Plans[/h2]
[list]
[*] Remove group aggro mechanics for more creatures
[*] Various spiders and Webber's spider aggro mechanics are currently being researched and are expected to be added in the next update
[/list]

[url=https://github.com/C-W-Z/dst_no_group_aggro]GitHub Repo Here[/url]
