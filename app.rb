# app.rb
require "sinatra"
require "json"
require "net/http"
require "uri"
require "tempfile"
require "line/bot"

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_ACCESS_TOKEN"]
  }
end

def bot_answer_to(a_question, user_name)

  # SKILLS

  # Agility
  if a_question.match?(/^AGILITY$/i)
    "A1: Catch\nA2: Diving Catch\nA3: Diving Tackle\nA4: Dodge\nA5: Defensive\nA6: Jump Up\nB1: Leap\nB2: Safe Pair of Hands\nB3: Sidestep\nB4: Sneaky Git\nB5: Sprint\nB6: Sure Feet"
  elsif a_question.match?(/^catch|キャッチ$/i)
    "This player may re-roll a failed agility test when attempting to catch the ball.\n\nボールのキャッチを試みる時、失敗したアジリティ（AG)テストをリロールができます。"
  elsif a_question.match?(/^diving catch|ダイビングキャッチ$/i)
    "This player may attempt to catch the ball if a pass, throw-in, or kick off causes it to land in a square within their Tackle Zone after scattering or deviating. This skill does not allow this player to attempt to catch the ball if it bounces into a square within their Tackle Zone.\n\nAdditionally, this player may apply a +1 modifier to any attempt to catch an accurate pass if they occupy the targeted square.\n\nもしパスかスローインかキックオフがスキャターやディビエションの後、このプレイヤーのタックルゾーンに着地する場合、このプレイヤーはキャッチを試みられます。もしボールがバウンスでタックルゾーンに入ったとしても、このスキルがキャッチを試みる事を強制することはありません。\n加えて、もしこのプレイヤーがターゲットスクエアに居れば、アキュレートパスのキャッチを試みる時、＋１モディファイアを得ます。"
  elsif a_question.match?(/^diving tackle|ダイビングタックル$/i)
    "Should an active opposition player that is attempting to Dodge, Jump, or Leap in order to vacate a square in which they are being Marked by this player pass their Agility test, you may declare that this player will use this Skill. Your opponent must immediately subtract 2 from the result of the Agility test. This player is then Placed Prone in the square vacated by the opposition player.\n\nIf the opposition player was being Marked by more than one player with this Skill, only one player may use it.\n\nもしアクティブの敵プレイヤーがこのプレイヤーにマークされているスクエアからドッジ、ジャンプ、リープで離れる事を試みて、アジリティ（AG)テストに成功した場合、このプレイヤーはこのスキルの使用を宣言出来ます。敵プレイヤーはすぐにそのアジリティ（AG)テストの結果をー２します。加えて、このプレイヤーは敵プレイヤーが出たスクエアに「プローンとして配置」されます。\nもしこのスキルを持つプレイヤーが２人以上で敵プレイヤーをマークしている場合、そのうち１人だけがダイビングタックルを使用出来ます。"
  elsif a_question.match?(/^dodge|ドッジ$/i)
    "Once per team turn, during their activation, this player may re-roll a failed Agility test when attempting to Dodge.\n\nAdditionally, this player may choose to use this skill when they are the target of a Block action and a Stumble result is applied against them, as described on page 57.\n\nチームターンの自分のアクティベーション中一回だけ、ドッジを試み、アジリティ（AG)テストに失敗した時リロールできます。\nさらに、このプレイヤーがブロックされてスタンブルの結果が出た時、５７ページに説明されているようにこのスキルが使えます。"
  elsif a_question.match?(/^defensive|ディフェンシブ$/i)
    "During your opponent\'s team turn (but not during your own team turn), any opposition players being Marked by this player cannot use the Guard skill.\n\n敵チームターンの間（でも自分のターンの間では無い）に、このプレイヤーにマークされているプレイヤーは「ガード」のスキルが使えません。"
  elsif a_question.match?(/^jump up|ジャンプアップ$/i)
    "If this player is Prone they may stand up for free (i.e., standing up does not cost this player three (3) squares of Movement Allowance, as it normally would).\n\nAdditionally, if this player is Prone when activated, they may attempt to Jump Up and perform a Block action. This player makes an Agility test, applying a +1 modifier. If this test is passed, they stand up and may perform a Block action. If the test is failed, they remain Prone and their activation ends.\n\nもしこのプレイヤーがプローンの時、フリーで立ち上がれます。（つまり立ち上がるために通常ならば必要なムーブメントアロウランス（MA)３が要りません）\n加えて、もしアクティベートする時にこのプレイヤーはプローンであれば、ブロックアクションを行うために「ジャンプアップ」を試みられます。このプレイヤーはアジリティ（AG)テストを行い、それに＋１モディファイアを当てはめます。テストに成功した場合、立ち上がり、ブロックアクションができます。失敗した場合プローンしたままアクティベーションが終わります。"
  elsif a_question.match?(/^leap|リープ$/i)
    "During their movement, instead of jumping over a single square that is occupied by a Prone or Stunned player, as described on page 45, a player with this Skill may choose to Leap over any single adjacent square, including unoccupied squares and squares occupied by Standing players.\n\nAdditionally, this player may reduce any negative modifier applied to the Agility test when they attempt to Jump over a Prone or Stunned player, or to Leap over an empty square or a square occupied by a Standing player by 1, to a minimum of -1.\n\nA player with this Skill cannot also have the Pogo Stick trait.\n\n自分の移動の間、４５ページに説明されているようにプローンやスタンしているプレイヤーがいるスクエアの上をジャンプする代わりに、このスキルを持っているプレイヤーは、それが空きスクエアでも立っているプレイヤーが占有しているスクエアでも、隣のスクエアの上をリープする事が出来ます。\n加えて、プローンやスタンしているプレイヤーがいるスクエアの上をジャンプする時、あるいは空きスクエアや立っているプレイヤーが占有しているスクエアの上をリープする時、アジリティ（AG)テストのネガティブなモディファイアを１減少させることが出来ます。最少値は－１です。\nこのスキルを持っているプレイヤーは「ポゴ・スティック」のトレートを持つことが出来ません。"
  elsif a_question.match?(/^safe pair of hands|セーフペアオブハンズ$/i)
    "If this player is Knocked Down or Placed Prone (but not if they Fall Over) whilst in possession of the ball, the ball does not bounce. Instead, you may place the ball in an unoccupied square adjacent to the one this player occupies when they become Prone.\n\nもしこのプレイヤーがボールを持ちながら、ノックダウンするか、プローンとして配置される時、（でも転ぶ時ではない）ボールはバウンスしません。代わりにこのプレイヤーがプローンとして置かれるスクエアの隣の空きスクエアにボールを置くことができます。"
  elsif a_question.match?(/^sidestep|サイドステップ$/i)
    "If this player is pushed back for any reason, they are not moved into a square chosen by the opposing coach. Instead, you may choose any unoccupied square adjacent to this player. This player is pushed back into that square instead. If there are no unoccupied squares adjacent to this player, this Skill cannot be used.\n\nもしこのプレイヤーが様々な理由でプッシュバックされる時、相手のコーチが選ぶスクエアに押される代わりに自分で隣接する空きスクエアを選び、移動することが出来ます。このプレイヤーの隣に空きスクエアがないとき、このスキルは使用出来ません。"
  elsif a_question.match?(/^sneaky git|スニーキギット$/i)
    "When this player performs a Foul action, they are not Sent-off for committing a Foul should they roll a natural double on the Armour roll.\n\nAdditionally, the activation of this player does not have to end once the foul has been committed. If you wish and if this player has not used their full Movement Allowance, they may continue to move after committing the Foul.\n\nこのプレイヤーがファールを犯す時、もしアーマーロールの出目がナチュラルなゾロ目だった場合でも退場させられません。\nさらに、ファールを犯した後このプレイヤーのアクティベーションを終了させなくても構いません。もし望むのであれば、そしてこのプレイヤーがムーブメントアロウランス（MA)をまだ残しているのであれば、ファールを犯したあとで移動を続ける事が出来ます。"
  elsif a_question.match?(/^sprint|スプリント$/i)
    "When this player performs any action that includes movement, they may attempt to Rush three times, rather than the usual two.\n\nこのプレイヤーは移動が含まれるアクションを行う時、ラッシュをいつもの2回までではなく3回まで試みることができます。"
  elsif a_question.match?(/^sure feet|シュアフィート$/i)
    "Once per team turn, during their activation, this player may re-roll the D6 when attempting to Rush.\n\nチームターンのアクティベーション中、一回だけ、このプレイヤーはラッシュを試みる時、ラッシュのD6をリロールすることができます。"
  # General
  elsif a_question.match?(/^GENERAL$/i)
    "A1: Block\nA2: Dauntless\nA3: Dirty Player\nA4: Fend\nA5: Frenzy\nA6: Kick\nB1: Pro\nB2: Shadowing\nB3: Strip Ball\nB4: Sure Hands\nB5: Tackle\nB6: Wrestle"
  elsif a_question.match?(/^block|ブロック|ブロク$/i)
    "When a Both Down result is applied during a Block action, this player may choose to ignore it and not get Knocked Down, as described on page 57.\n\nブロックアクションの時、「ボースダウン」の結果が出た場合、５７ページに説明されているようにこのプレイヤーはその結果を無視してノックダウンされないことを選べます。"
  elsif a_question.match?(/^dauntless|ドントレス$/i)
    "When this player performs a Block action (on its own or as part of a Blitz action), if the nominated target has a higher Strength characteristic than this player before counting offensive or defensive assists but after applying any other modifiers, roll a D6 and add this player's Strength characteristic to the result. If the total is higher than the target\'s Strength characteristic, this player increases their Strength characteristic to be equal to that of the target of the Block action, before counting offensive or defensive assists, for the duration of this Block action.\n\nIf this player has another Skill that allows them to perform more than one Block action, such as Frenzy, they must make a Dauntless roll before each separate Block action is performed.\n\nこのプレイヤーがブロックアクション（ブロックだけでも、ブリッツに含まれる場合も）を行う時、もし指名したターゲットのストレングス（ST)がモディファイアを当てはめた後、かつ、アシストを当てはめる前に、このプレイヤーのストレングス（ST)より高い場合、D6を振り、このプレイヤーのストレングス（ST）を加えます。もしその結果がターゲットのストレングス（ST)より高ければ、このブロックアクションの間、オフェンシブやディフェンシブのアシストを当てはめる前に、このプレイヤーのストレングス（ST)をブロックアクションのターゲットのストレングス（ST)と同値になるよう増加させます。\nもしこのプレイヤーがブロックを一回以上行える他のスキルを持つ場合、例えば「フレンジー」等では、各ブロックを行う前に個別にドントレスのロールを行います。"
  elsif a_question.match?(/^dirty player|ダーティープレイヤー$/i)
    "When this player commits a Foul action, either the Armour roll or Injury roll made against the victim may be modified by the amount shown in brackets. This modifier may be applied after the roll has been made.\n\nこのプレイヤーがファールアクションを犯す時、犠牲者に対するアーマーロールかインジャリーロールのどちらかを括弧内（ ）の数値でモディファイできます。ロール後にモディファイアを当てはめるか決めることが出来ます。"
  elsif a_question.match?(/^fend|フェンド$/i)
    "If this player is pushed back as the result of any block dice result being applied against them, they may choose to prevent the player that pushed them back from following-up. However, the player that pushed them back may continue to move as part of a Blitz action if they have Movement Allowance remaining or by Rushing.\n\nThis Skill cannot be used when this player is chain-pushed, against a player with the Ball & Chain trait, or against a player with the Juggernaut skill that performed the Block action as part of a Blitz.\n\nもしこのプレイヤーがいずれかのブロックダイスの結果よってプッシュバックされる時、プッシュバックを起こしたプレイヤーのフォローアップ移動をやめさせる事が出来ます。しかし、プッシュバックしたプレイヤーは、ブリッツアクションに含まれる移動でムーブメントアロウランス（MA)が残っていたり、ラッシュを試みたりするのであれば、移動することができます。\nこのスキルは、このプレイヤーがチェーンプッシュされる時や、「ボールアンドチェーン」のトレートがあるプレイヤーや「ジャガーノート」スキルを持つプレイヤーによって行われたブリッツに含まれるブロックに対しては使用出来ません。"
  elsif a_question.match?(/^frenzy|フレンジー$/i)
    "Every time this player performs a Block action (on its own or as part of a Blitz action), they must follow-up if the target is pushed back and if they are still able. If the target is still Standing after being pushed back, and if this player was able to follow-up, this player must then perform a second Block action against the same target, again following-up if the target is pushed back.\n\nIf this player is performing a Blitz action, performing a second Block action will also cost them one square of their Movement Allowance. If this player has no Movement Allowance left to perform a second Block action, they must Rush to do so. If they cannot Rush, they cannot perform a second Block action.\n\nNote that if an opposition player in possession of the ball is pushed back into your End Zone and is still standing, a touchdown will be scored, ending the drive. In this case, the second Block action is not performed.\n\nA player with this Skill cannot also have the Grab skill.\n\nこのプレイヤーがブロックアクションを行う時（ブロックだけでも、ブリッツに含まれれる時も）、ターゲットをプッシュバックさせる時は可能な限りフォローアップしなくてはなりません。もしプッシュバックさせてから、ターゲットが立っており、このプレイヤーがフォローアップできた場合、このプレイヤーは同じターゲットに二回目のブロックをしなくてなりません。プッシュバックさせるたびに、フォローアップしなければなりません。\nもし、このプレイヤーがブリッツアクション行っていた場合、二回目のブロックもムーブメントアロウランス（MA)1スクエア分必要になります。もしこのプレイヤーが二回目のブロックを行うためのムーブメントアロウランス（MA)が残っていなければ、可能な限りラッシュを行います。ラッシュできなければ、二回目のブロックアクションを行えません。\nボールを持っている敵プレイヤーがあなたのエンドゾーンにプッシュバックされ、立っている場合はタッチダウンになり、ドライブが終了します。この場合、二回目のブロックアクションは行われません。\nこのスキルを持っているプレイヤーはブロックスキルが持てません。"
  elsif a_question.match?(/^kick|キック$/i)
    "If this player is nominated to be the kicking player during a kick-off, you may choose to halve the result of the D6 to determine the number of squares that the ball deviates, rounding any fractions down.\n\nキックオフの時、もしこのプレイヤーがキッカーとして指名された場合、ボールがデビィエートするスクエア数を決めるD6の結果を半分にすることができます。端数は切り捨てます。"
  elsif a_question.match?(/^pro|プロ$/i)
    "During their activation, this player may attempt to re-roll one die. This die may have been rolled either as a single die roll or as part of a dice pool, but cannot be a die thet was rolled as part of an Armour, Injury, or Casualty roll. Roll a D6:\n\n- On a roll of 3+, the die can be re-rolled.\n\n- On a roll of 1 or 2, the die cannot be re-rolled.\n\nOnce this player has attempted to use this Skill, they may not use a re-roll from any other source to re-roll this one die.\n\nアクティベーションの間、このプレイヤーはサイコロを一個リロールすることができます。そのサイコロはシングルダイスロールのものでも、マルチダイスロールのものでも、ダイスプール内の一個でも構いませんが、アーマーロール、インジャリーロール、カジュアルティーロールのサイコロをリロールすることはできません。D6を振ります：\n・３＋が出たら、そのサイコロをリロールできます。\n・１か２が出たら、そのサイコロをリロールできません。\n\nこのプレイヤーがこのスキルの使用を試みた後、選択したそのサイコロを他の方法でリロールすることは出来ません。"
  elsif a_question.match?(/^shadowing|シャドウイング$/i)
    "This player can use this Skill when an opposition player they are Marking voluntarily moves out of a square within this player\'s Tackle Zone. Roll a D6, adding the MA of this player to the roll and then subtracting the MA of the opposition player. If the result is 6 or higher, or if the roll is a natural 6, this player may immediately move into the square vacated by the opposition player (this player does not need to Dodge to make this move). If, however, the result is 5 or lower, or if the roll is a natural 1, this Skill has no further effect.\n\nA player may use this Skill any number of times per turn, during either team\'s turn. If an opposition player is being Marked by more than one player with this Skill, only one player may use it.\n\nこのプレイヤーのタックルゾーン内のスクエアから、マークされているプレイヤーが意図的に離れようとする時、このスキルが使えます。D6を振り、出目にこのプレイヤーのムーブメントアロウランス（MA)を加え、その結果から敵プレイヤーのムーブメントアロウランス（MA)を引きます。結果が6以上か、出目がナチュラル６の場合このプレイヤーは敵プレイヤーが移動したスクエアにすぐ移動できます（このプレイヤーはドッジロールをする必要がありません）しかし、結果が5以下か、出目がナチュラル１の場合このスキルはこれ以上効果を発揮しません。\nプレイヤーはこのスキルをどのチームのターンでも、そして何回でも使えます。もしこのスキルを持つプレイヤーが２人以上で敵プレイヤーをマークしている場合そのうち１人だけが、シャドウイングを使用出来ます。"
  elsif a_question.match?(/^strip ball|ストリップボール$/i)
    "When this player targets an opposition player that is in possession of the ball with a Block action (on its own or as part of a Blitz action), choosing to apply a Push Back result will cause that player to drop the ball in the square they are pushed back into. The ball will bounce from the square the player is pushed back into, as if they had been Knocked Down.\n\nこのプレイヤーはブロックアクションで（ブロックだけでも、ブリッツアクションに含まれる時も）ボールを持っているプレイヤーをターゲットに指名し、プッシュバックの結果を選択した場合、そのプレイヤーがプッシュバックした後そのスクエアにボールを落とさせます。プレイヤーがノックダウンされ時のように、押されたスクエアからボールがバウンスします。"
  elsif a_question.match?(/^sure hands|シュアハンズ$/i)
    "This player may re-roll any failed attempt to pick up the ball. In addition, the Strip Ball skill cannot be used against a player with this Skill.\n\nこのプレイヤーがボールを拾う試みに失敗した時はいつでもリロールできます。さらに、このスキルを持っているプレイヤーに対しては「ストリップボール」スキルが使えません。"
  elsif a_question.match?(/^tackle|タックル$/i)
    "When an active opposition player attempts to Dodge from a square in which they were being Marked by one or more players on your team with this Skill, that player cannot use the Dodge skill.\n\nAdditionally, when an opposition player is targeted by a Block action performed by a player with this Skill, that player cannot use the Dodge skill if a Stumble result is applied against them.\n\n自分のチームのこのスキルを持つプレイヤー一人以上によってマークされているアクティブの敵プレイヤーはドッジを試みる際「ドッジ」スキルが使えません。\nさらに、敵のプレイヤーがこのスキルを持っているプレイヤーにターゲットされているとき、「スタンブル」の結果が当てはまれた場合も、「ドッジ」のスキルが使えません。"
  elsif a_question.match?(/^wrestle|レッスル$/i)
    "This player may use this Skill when a Both Down result is applied, either when they perform a Block action or when they are the target of a Block action. Instead of applying the Both Down result as normal, and regardless of any other Skills either player may possess, both players are Placed Prone.\n\nこのプレイヤーがブロックアクションを行ったり、ブロックアクションのターゲットされたりして、「ボースダウン」の結果が当てはまった時、このスキルを使用出来ます。ボースダウンの通常の効果の代わりに、両方のプレイヤーが持ついかなるスキルも無視し、両方のプレイヤーを「プローンに配置」します。"
  # Mutations
  elsif a_question.match?(/^MUTATION(S|)$/i)
    "A1: Big Hand\nA2: Claws\nA3: Disturbing Presence\nA4: Extra Arms\nA5: Foul Appearance\nA6: Horns\nB1: Iron Hard Skin\nB2: Monstrous Mouth\nB3: Prehensile Tail\nB4: Tentacles\nB5: Two Heads\nB6: Very Long Legs"
  elsif a_question.match?(/^big hand$/i)
    "This player may ignore any modifier(s) for being Marked or for Pouring Rain weather conditions when they attempt to pick up the ball."
  elsif a_question.match?(/^claws$/i)
    "When you make an Armour roll against an opposition player that was Knocked Down as the result of a Block action performed by this player, a roll of 8+ before applying any modifiers will break their armour, regardless of their actual Armour Value."
  elsif a_question.match?(/^disturbing presence$/i)
    "When an opposition player performs either a Pass action, a Throw Team-mate action, or a Throw Bomb Special action, or attempts to either interfere with a pass or to catch the ball, they must apply a -1 modifier to the test for each player on your team with this Skill that is within three squares of them, even if the player with this Skill is Prone, Stunned, or has lost their Tackle Zone."
  elsif a_question.match?(/^extra arms$/i)
    "This player may apply a +1 modifier when they attempt to pick up or catch the ball, or when they attempt to interfere with a pass."
  elsif a_question.match?(/^foul appearance$/i)
    "When an opposition player declares a Block action targeting this player (on its own or as part of a Blitz action), or any Special action that targets this player, their coach must first roll a D6, even if this player has lost their Tackle Zone. On a roll of 1, the player cannot perform the declared action and the action is wasted."
  elsif a_question.match?(/^horns$/i)
    "When this player performs a Block action as part of a Blitz action (but not on its own), you may apply a +1 modifier to this player\'s Strength characteristic. This modifier is applied before counting assists, before applying any other Strength modifiers, and before using any other Skills or Traits."
  elsif a_question.match?(/^iron hard skin$/i)
    "The Claws skill cannot be used when making an Armour roll against this player."
  elsif a_question.match?(/^monstrous mouth$/i)
    "This player may re-roll any failed attempt to catch the ball. In addition, the Strip Ball skill cannot be used against this player."
  elsif a_question.match?(/^prehensile tail$/i)
    "When an active opposition player attempts to Dodge, Jump, or Leap in order to vacate a square in which they are being Marked by this player, there is an additional -1 modifier applied to the active player\'s Agility test.\n\nIf the opposition player is being Marked by more than one player with this Mutation, only one player may use it."
  elsif a_question.match?(/^tentacles$/i)
    "This player can use this Skill when an opposition player they are Marking voluntarily moves out of a square within this player\'s Tackle Zone. Roll a D6, adding the ST of this player to the roll and then subtracting the ST of the opposition player. If the result is 6 or higher, or if the roll is a natural 6, the opposition player is held firmly in place and their movement comes to an end. If, however, the result is 5 or lower, or if the roll is a natural 1, this Skill has no further effect.\n\nA player may use this Skill any number of times per turn, during either team's turn. If an opposition player is being Marked by more than one player with this Skill, only one player may use it."
  elsif a_question.match?(/^two heads$/i)
    "This player may apply a +1 modifier to the Agility test when they attempt to Dodge."
  elsif a_question.match?(/^very long legs$/i)
    "This player may reduce any negative modifier applied to the Agility test when they attempt to Jump over a Prone or Stunned player (or to Leap over an empty square or a square occupied by a Standing player, if this player has the Leap skill) by 1, to a minimum of -1.\n\nAdditionally, this player may apply a +2 modifier to any attempts to interfere with a pass they make.\n\nFinally, this player ignores the Cloud Burster skill."
  # Passing
  elsif a_question.match?(/^PASSING$/i)
    "A1: Accurate\nA2: Cannoneer\nA3: Cloud Burster\nA4: Dump-off\nA5: Fumblerooskie\nA6: Hail Mary Pass\nB1: Leader\nB2: Nerves of Steel\nB3: On the Ball\nB4: Pass\nB5: Running Pass\nB6: Safe Pass"
  elsif a_question.match?(/^accurate$/i)
    "When this player performs a Quick Pass action or a Short Pass action, you may apply an additional +1 modifier to the Passing Ability test."
  elsif a_question.match?(/^cannoneer$/i)
    "When this player performs a Long Pass action or a Long Bomb Pass action, you may apply an additional +1 modifier to the Passing Ability test."
  elsif a_question.match?(/^cloud burster$/i)
    "When this player performs a Long Pass action or a Long Bomb Pass action, you may choose to make the opposing coach re-roll a successful attempt to interfere with the pass."
  elsif a_question.match?(/^dump(-| )off$/i)
    "If this player is nominated as the target of a Block action (or a Special action granted by a Skill or Trait that can be performed instead of a Block action) and if they are in possession of the ball, they may immediately perform a Quick Pass action, interrupting the activation of the player performing the Block action (or Special action) to do so. This Quick Pass action cannot cause a Turnover, but otherwise all of the normal rules for passing the ball apply. Once the Quick Pass action is resolved, the active player performs the Block action and their team turn continues."
  elsif a_question.match?(/^fumblerooskie$/i)
    "When this player performs a Move or Blitz action whilst in possession of the ball, they may choose to 'drop' the ball. The ball may be placed in any square the player vacates during their movement and does not bounce. No Turnover is caused."
  elsif a_question.match?(/^hail mary pass$/i)
    "When this player performs a Pass action (or a Throw Bomb action), the target square can be anywhere on the pitch and the range ruler does not need to be used. A Hail Mary pass is never accurate, regardless of the result of the Passing Ability test it will always be inaccurate at best. A Passing Ability test is made and can be re-rolled as normal in order to determine if the Hail Mary pass is wildly inaccurate or is fumbled. A Hail Mary pass cannot be interfered with. This Skill may not be used in a Blizzard."
  elsif a_question.match?(/^leader$/i)
    "A team which has one or more players with this Skill gains a single extra team re-roll, called a Leader re-roll. However, the Leader re-roll can only be used if there is at least one player with this Skill on the pitch (even if the player with this Skill is Prone, Stunned, or has lost their Tackle Zone). If all players with this Skill are removed from play before the Leader re-roll is used, it is lost. The Leader re-roll can be carried over into extra time if it is not used, but the team does not receive a new one at the start of extra time. Unlike standard Team Re-rolls, the Leader Re-roll cannot be lost due to a Halfling Master Chef. Otherwise, the Leader re-roll is treated just like a normal team re-roll."
  elsif a_question.match?(/^nerves of steel$/i)
    "This player may ignore any modifier(s) for being Marked when they attempt to perform a Pass action, attempt to catch the ball, or attempt to interfere with a pass."
  elsif a_question.match?(/^on the ball$/i)
    "This player may move up to three squares (regardless of their MA), following all of the normal movement rules, when the opposing coach declares that one of their players is going to perform a Pass action. This move is made after the range has been measured and the target square declared, but before the active player makes a Passing Ability test. Making this move interrupts the activation of the opposing player performing the pass action. A player may use this Skill when an opposition player uses the Dump-off skill, but should this player Fall Over whilst moving, a Turnover is caused.\n\nAdditionally, during each Start of Drive sequence, after Step 2 but before Step 3, one Open player with this Skill on the receiving team may move up to three squares (regardless of their MA). This Skill may not be used if a touchback is caused when the kick deviates and does not allow the player to cross into their opponent's half of the pitch."
  elsif a_question.match?(/^pass$/i)
    "This player may re-roll a failed Passing Ability test when performing a Pass action."
  elsif a_question.match?(/^running pass$/i)
    "If this player performs a Quick Pass action, their activation does not have to end once the pass is resolved. If you wish and if this player has not used their full Movement Allowance, they may continue to move after resolving the pass."
  elsif a_question.match?(/^safe pass$/i)
    "Should this player fumble a Pass action, the ball is not dropped, does not bounce from the square this player occupies, and no Turnover is caused. Instead, this player retains possession of the ball and their activation ends."
  # Strength
elsif a_question.match?(/^STRENGTH$/i)
  "A1: Arm Bar\nA2: Brawler\nA3: Break Tackle\nA4: Grab\nA5: Guard\nA6: Juggernaut\nB1: Mighty Blow\nB2: Multiple Block\nB3: Pile Driver\nB4: Stand Firm\nB5: Strong Arm\nB6:Thick Skull"
  elsif a_question.match?(/^arm bar$/i)
    "If an opposition player Falls Over as the result of failing their Agility test when attempting to Dodge, Jump, or Leap out of a square in which they were being Marked by this player, you may apply a +1 modifier to either the Armour roll or Injury roll. This modifier may be applied after the roll has been made and may be applied even if this player is now Prone.\n\nIf the opposition player was being Marked by more than one player with this Skill, only one player may use it."
  elsif a_question.match?(/^brawler$/i)
    "When this player performs a Block action on its own (but not as part of a Blitz action), this player may re-roll a single Both Down result."
  elsif a_question.match?(/^break tackle$/i)
    "Once during their activation, after making an Agility test in order to Dodge, this player may modify the dice roll by +1 if their Strength characteristic is 4 or less, or by +2 if their Strength characteristic is 5 or more."
  elsif a_question.match?(/^grab$/i)
    "When this player performs a Block action (on its own or as part of a Blitz action), using this Skill prevents the target of the Block action from using the Side Step skill.\n\nAdditionally, when this player performs a Block action on its own (but not as part of a Blitz action), if the target is pushed back, this player may choose any unoccupied square adjacent to the target to push that player into. If there are no unoccupied squares, this Skill cannot be used.\n\nA player with this Skill cannot also have the Frenzy skill."
  elsif a_question.match?(/^guard$/i)
    "This player can offer both offensive and defensive assists regardless of how many opposition players are Marking them."
  elsif a_question.match?(/^juggernaut$/i)
    "When this player performs a Block action as part of a Blitz action (but not on its own), they may choose to treat a Both Down result as a Push Back result. In addition, when this player performs a Block action as part of a Blitz action, the target of the Block action may not use the Fend, Stand FIrm, or Wrestle skills."
  elsif a_question.match?(/^mighty blow$/i)
    "When an opposition player is Knocked Down as the result of a Block action performed by this player (on its own or as part of a Blitz action), you may choose to modify either the Armour roll or Injury roll by the amount shown in brackets. This modifier may be applied after the roll has been made.\n\nThis Skill cannot be used with the Stab or Chainsaw traits."
  elsif a_question.match?(/^multiple block$/i)
    "When this player performs a Block action on its own (but not as part of a Blitz action), they may choose to perform two Block actions, each targeting a different player they are Marking. However, doing so will reduce this player's Strength characteristic by 2 for the duration of this activation. Both Block actions are performed simultaneously, meaning both are resolved in full even if one or both result in a Turnover. The dice rolls for each Block action should be kept separate to avoid confusion. This player cannot follow-up when using this Skill.\n\nNote that choosing to use this Skill means this player will be unable to use the Franzy skill during the same activation."
  elsif a_question.match?(/^pile driver$/i)
    "When an opposition player is Knocked Down by this player as the result of a Block action (on its own or as part of a Blitz action), this player may immediately commit a free Foul action against the Knocked Down player. To use this Skill, this player must be Standing after the Block dice result has been selected and applied, and must occupy a square adjacent to the Knocked Down player. After using this Skill, this player is Placed Prone and their activation ends immediately."
  elsif a_question.match?(/^stand firm$/i)
    "This player may choose not to be pushed back, either as the result of a Block action made against them or by a chain-push. Using this Skill does not prevent an opposition player with the Frenzy skill from performing a second Block action if this player is still Standing after the first."
  elsif a_question.match?(/^strong arm$/i)
    "This player may apply a +1 modifier to any Passing Ability test rolls they make when performing a Throw Team-mate action.\n\nA player that does not have the Throw Team-mate trait cannot have this Skill."
  elsif a_question.match?(/^thick skull$/i)
    "When an Injury roll is made against this player (even if this player is Prone, Stunned, or has lost their Tackle Zone), they can only be KO'd on a roll of 9, and will treat a roll of 8 as a Stunned result. If this player also has the Stunty trait, they can only be KO'd on a roll of 8, and will treat a roll of 7 as a Stunned result. All other results are unaffected."

  # TRAITS
  elsif a_question.match?(/^animal savagery$/i)
    "When this player is activated, even if they are Prone or have lost their Tackle Zone, immediately after declaring the action they will perform but before performing the action, roll a D6, applying a +2 modifier to the die roll if you declared the player would perform a Block or Blitz action (or a Special action granted by a Skill or Trait that can be performed instead of a Block action):\n\n• On a roll of 1-3, this player lashes out at their team-mates:\n- One standing team-mate of your choice that is currently adjacent to this player is immediately Knocked Down by this player. This does not cause a Turnover unless the Knocked Down player was in possession of the ball. After making an Armour roll (and possible Injury roll) against the Knocked Down player, this player may continue their activation and complete their declared action if able. Note that, if this player has any applicable Skills, the coach of the opposing team may use them when making an Armour roll (and possible Injury roll) against the Knocked Down player.\n- If this player is not currently adjacent to any Standing Team-mates, this player's activation ends immediately. Additionally, this player loses their Tackle Zone until they are next activated.\n• On a roll of 4+, this player continues their activation as normal and completes their declared action.\n\nIf you declared that this player would perform an action which can only be performed once per team turn and this player's activation ended before the action could be completed, the action is considered to have been performed and no other player on your team may perform the same action this team turn."
  elsif a_question.match?(/^animosity$/i)
    "This player is jealous of and dislikes certain other players on their team, as shown in brackets after the name of the Skill on this player's profile. This may be defined by position or race. For example, a Skaven Thrower on an Underworld Denizens team has Animpsity (Underworld Goblin Linemen), meaning they suffer Animosity towards any Underworld Goblin Linemen on their team. Whereas a Skaven Renegade on a Chaos Renegade team has Animosity (all team-mates), meaning they suffer Animosity towards all of their team-mates equally.\n\nWhen this player wishes to perform a Hand-off action to a team-mate of the type listed, or attempts to perform a Pass action and the target square is occupied by a team-mate of the type listed, this player may refuse to do so. Roll a D6. On a roll of 1, this player refuses to perform the action and their activation comes to an end. Animosity does not extend to Mercenaries or Star Players."
  elsif a_question.match?(/^always hungry$/i)
    "If this player wishes to perform a Throw Team-mate action, roll a D6 after they have finished moving, but before they throw their team-mate. On a roll of 2+, continue with the throw as normal. On a roll of 1, this player will attempt to eat their team-mate. Roll another D6:\n\n• On a roll of 1, the team-mate has been eaten and is immediately removed from the Team Draft list. No apothecary can save them and no Regeneration attempts can be made. If the team-mate was in possession of the ball, it will bounce from the square this player occupies.\n• On a roll of 2+, the team-mate squirms free and the Throw Team-mate action is automatically fumbled, as described on page 53."
  elsif a_question.match?(/^ball (and|&|n) chain$/i)
    "When this player is activated, the only action they may perform is a 'Ball & Chain Move' Special action. There is no limit to how many players with this Trait may perform this Special action each turn.\n\nWhen this player performs this Special action:\n\n• Place the Throw-in template over the player, facing towards either End Zone or either sideline as you wish.\n• Roll a D6 and move the player one square in the direction indicated.\n• A player with a Ball & Chain automatically passes any Agility tests they may be required to make in order to Dodge, regardless of any modifiers.\n• If this movement takes the player off the pitch, they risk Injury by the Crowd.\n• If this movement takes the player into a square in which the ball is placed, the player is considered to have moved involuntarily. Therefore, they may not attempt to pickthe ball up and the ball will bounce.\n\nRepeat this process for each square the player moves.\n\nIf this player would move into a square that is occupied by a Standing player from either team, they must perform a Block action against that player, following the normal rules, but with the following exceptions:\n\n• A Ball & Chain player ignores the Foul Appearance skill.\n• A Ball & Chain player must follow-up if they push-back another player.\n\nIf this player moves into a square that is occupied by a Prone or Stunned player from either team, for any reason, that player is pushed back and an Armour roll is made against them.\n\nThis player may Rush. Declare that the player will Rush before placing the Throw-in template and rolling the D6 to determine direction:\n\n• If this player Rushes into an unoccupied square, move them as normal and roll a D6:\n- On a roll of 2+, this player moves without mishap.\n- On a roll of 1 (before or after modification), the player Falls Over.\n• If this player Rushes into a square that is occupied by a standing player from either team, roll a D6:\n- On a roll of 2+, this player moves without mishap and will perform a Block action against the player occupying the square as described previously.\n- On a roll of 1 (before or after modification), the player occupying the square is pushed back and this player will Fall Over after moving into the vacated square.\n\nIf this player ever Falls Over, is Knocked Down, or is Placed Prone, and Injury roll is immediately made against them (no Armour roll is required), treating a Stunned result as a KO'd result.\n\nA player with this Trait cannot also have the Diving Tackle, Frenzy, Grab, Leap, Multiple Block, On the Ball, or Shadowing skills."
  elsif a_question.match?(/^bombardier$/i)
    "When activated and if they are Standing, this player can perform a 'Throw Bomb' Special action. This Special action is neither a Pass action nor a Throw Team-mate action, so does not prevent another player performing one of those actions during the same team turn. However, only a single player with this Trait may perform this Special action each team turn.\n\nA Bomb can be thrown and caught, and the throw interfered with, just like a ball, using the rules for Pass actions as described on page 48, with the following exceptions:\n\n• A player may not stand up or move before performing a Throw Bomb action.\n• Bombs do not bounce and can come to rest on the ground in an occupied square. Should a player fail to catch a Bomb, it will come to rest on the ground in the square the player occupies.\n• If a Bomb is fumbled, it will explode immediately in the square occupied by the player attempting to throw it.\n• If a Bomb comes to rest on the ground in an empty square or is caught by an opposition player, no Turnover is caused.\n• A player that is in possession of the ball can still catch a Bomb.\n• Any Skills that can be used when performing a Pass action can also be used when performing a Throw Bomb Special action, with the exception of On The Ball.\n\nIf a Bomb is caught by a player on either team, roll a D6:\n\n• On a roll of 4+, the Bomb explodes immediately, as described below.\n• On a roll of 1-3, that player must throw the Bomb again immediately. This Throw takes place out of the normal sequence of play.\n\nShould the Bomb ever leave the pitch, it explodes in the crowd with no effect (on the game) before the crowd can throw it back.\n\nWhen a Bomb comes to rest on the ground, in either an unoccupied square, in a square occupied by a player that failed to catch the Bomb, or in a square occupied by a Prone or Stunned player, it will explode immediately:\n\n• If the Bomb explodes in an occupied square, that player is automatically hit by the explosion.\n• Roll a D6 for each player (from either team) that occupies a square adjacent to the once in which the Bomb exploded:\n    - On a roll of 4+, the player has been hit by the explosion.\n    - On a roll of 1-3, the player manages to avoid the explosion.\n• Any Standing players hit by the explosion are Knocked Down.\n• An Armour roll (and possibly an Injury roll as well) is made against any player hit by the explosion, even if they were already Prone or Stunned.\n• You may apply a +1 modifier to either the Armour roll or Injury roll. This modifier may be applied after the roll has been made."
  elsif a_question.match?(/^bone( |)head$/i)
    "When this player is activated, even if they are Prone or have lost their Tackle Zone, immediately after declaring the action they will perform but before performing the action, roll a D6:\n\n• On a roll of 1, this player forgets what they are doing and their activation ends immediately. Additionally, this player loses their Tackle Zone until they are next activated.\n• On a roll of 2+, this player continues their activation as normal and completes their declared action.\n\nIf you declared that this player would perform an action which can only be performed once per team turn and this player's activation ended before the action could be completed, the action is considered to have been performed and no other player on your team may perform the same action this team turn."
  elsif a_question.match?(/^chainsaw$/i)
    "Instead of performing a Block action (on its own or as part of a Blitz action), this player may perform a 'Chainsaw Attack' Special action. Exactly as described for a Block action, nominate a single Standing player to be the target of the Chainsaw Attack Special action. There is no limit to how many players with this Trait may perform this Special action each team turn.\n\nTo perform a Chainsaw Attack Special action, roll a D6:\n\n• On a roll of 2+, the nominated target is hit by a Chainsaw!\n• On a roll of 1, the Chainsaw will violently 'kick-back' and hit the player wielding it.\n• In either case, an Armour roll is made against the player hit by the Chainsaw, adding +3 to the result.\n• If the armour of the player hit is broken, they become Prone and an Injury roll is made against them. This Injury roll cannot be modified in any way.\n• If the armour of the player hit is not broken, this Trait has no effect.\n\nThis player can only use the Chainsaw once per turn (i.e., a Chainsaw cannot be used with Frenzy or Multiple Block) and if it is used as part of a Blitz action, this player cannot continue moving after using it.\n\nIf this player Falls Over or is Knocked Down, the opposing coach may add +3 to the Armour roll made against the player.\n\nIf an opposition player performs a Block action targeting this player and a Player Down! or POW! result is applied, +3 is added to the Armour roll. If a Both Down result is applied, +3 is added to both Armour rolls.\n\nFinally, this player may use their Chainsaw when they perform a Foul action. Roll a D6 for kick-back as described above. Once again, an Armour roll is made against the player hit by the Chainsaw, adding +3 to the score."
  elsif a_question.match?(/^decay$/i)
    "If this player suffers a Casualty result on the Injury table, there is a +1 modifier applied to all rolls made against this player on the Casualty table"
  elsif a_question.match?(/^hypnotic gaze$/i)
    "During their activation, this player may perform a 'Hypnotic Gaze' Special action. There is no limit to how many players with this Trait may perform this Special action each team turn.\n\nTo perform a Hypnotic Gaze Special action, nominate a single Standing opposition player that has not lost their Tackle Zone and that this player is Marking. Then make an Agility test for this player, applying a -1 modifier for every player (other than the nominated player) that is Marking this player. If the test is passed, the nominated player loses their Tackle Zone until they are next activated.\n\nThis player may move before performing this Special action, following all of the normal movement rules. However, once this Special action has been performed, this player may not move further and their activation comes to an end."
  elsif a_question.match?(/^kick team(-| |)mate$/i)
    "Once per team turn, in addition to another player performing a Pass or a Throw Team-mate action, a single player with this Trait on the active team can perform a 'Kick Team-mate' Special action and attempt to kick a Standing team-mate with the Right Stuff trait that is in a square adjacent to them.\n\nTo perform a Kick Team-mate Special action, follow the rules for Throw Team-mate actions as described on page 52.\n\nHowever, if the Kick Team-mate Special action is fumbled, the kicked player is automatically removed from play and an Injury roll is made against them, treating a Stunned result as a KO'd result (note that, if the player that performed this action also has the Mighty Blow (+X) skill, the coach of the opposing team may use that Skill on this Injury roll). If the kicked player was in possession of the ball when removed from play, the ball will bounce from the square they occupied."
  elsif a_question.match?(/^loner$/i)
    "If this player wishes to use a team re-roll, roll a D6. If you roll equal to or higher than the target number shown in brackets, this player may use the team re-roll as normal. Otherwise, the original result stands without being re-rolled but the team re-roll is lost just as if it had been used."
  elsif a_question.match?(/^no hands$/i)
    "This player is unable to take possession of the ball. They may not attempt to pick it up, to catch it, or attempt to interfere with a pass. Any attempt to do so will automatically fail, causing the ball to bounce. Should this player voluntarily move into a square in which the ball is placed, they cannot attempt to pick it up. The ball will bounce and a Turnover is caused as if this player had failed an attempt to pick up the ball."
  elsif a_question.match?(/^plague(-| )ridden$/i)
    "Once per game, if an opposition player with a Strength characteristic of 4 or less that does not have the Decay, Regeneration, or Stunty traits suffers a Casualty result of 15-16 DEAD as the result of a Block action performed or a Foul action committed by a player with this Trait that belongs to your team, and if that player cannot be saved by an apothecary, you may choose to use this Trait. If you do, that player does not die; they have instead been infected with a virulent plague!\n\nIf your team has the 'Favoured of Nurgle' special rule, a new 'Rotter Lineman' player, drawn from the Nurgle roster, can be placed immediately in the Reserves box of your team's dugout (this may cause a team to have more than 16 players for the remainder of this game). During step 4 of the post-game sequence, this player may be permanently hired, exactly as you would a Journeyman player that had played for your team (see page 72)."
  elsif a_question.match?(/^pogo stick$/i)
    "During their movement, instead of jumping over a single square that is occupied by a Prone or Stunned player, as described on page 45, a player with this Trait may choose to Leap over any single adjacent square, including unoccupied squares and squares occupied by Standing players.\n\nAdditionally, when this player makes an Agility test to Jump over a Prone or Stunned player, or to Leap over an empty square or a square occupied by a Standing player, they may ignore any negative modifiers that would normally be applied for being Marked in the square they jumped or leaped from and/or for being Marked in the square they have jumped or leaped into.\n\nA player with this Trait cannot also have the Leap skill."
  elsif a_question.match?(/^projectile vomit$/i)
    "Instead of performing a Block action (on its own or as part of a Blitz action), this player may perform a 'Projectile Vomit' Special action. Exactly as described for a Block action, nominate a single Standing player to be the target of the Projectile Vomit Special action. There is no limit to how many players with this Trait may perform this Special action each team turn.\n\nTo perform a Projectile Vomit Special action, roll a D6:\n\n• On a roll of 2+, this player regurgitates acidic bile on the nominated target.\n• On a roll of 1, this player belches and snorts, before covering itself with acidic bile.\n• In either case, an Armour roll is made against the player hit by the Projectile Vomit. This Armour roll cannot be modified in any way.\n• If the armour of the player hit is not broken, this Trait has no effect.\n\nA player can only perform this Special action once per turn (i.e., Projectile Vomit cannot be used with Frenzy or Multiple Block)."
  elsif a_question.match?(/^really stupid$/i)
    "When this player is activated, even if they are Prone or have lost their Tackle Zone, immediately after declaring the action they will perform but before performing the action, roll a D6, applying a +2 modifier to the dice roll if this player is currently adjacent to one or more Standing team-mates that do not have this Trait:\n\n• On a roll of 1-3, this player forgets what they are doing and their activation ends immediately. Additionally, this player loses their Tackle Zone until they are next activated.\n• On a roll of 4+, this player continues their activation as normal and completes their declared action.\n\nNote that if you declared that this player would perform an action which can only be performed once per team turn and this player's activation ended before the action could be completed, the action is considered to have been performed and no other player on your team may perform the same action this team turn."
  elsif a_question.match?(/^regeneration$/i)
    "After a Casualty roll has been made against this player, roll a D6. On a roll of 4+, the Casualty roll is discarded without effect and the player is placed in the Reserves box rather than the Casualty box of their team dugout. On a roll of 1-3, however, the result of the Casualty roll is applied as normal."
  elsif a_question.match?(/^right stuff$/i)
    "If this player also has a Strength characteristic of 3 or less, they can be thrown by a team-mate with the Throw Team-mate skill, as described on page 52."
  elsif a_question.match?(/^secret weapon$/i)
    "When a drive in which this player took part in ends, even if the player was not on the pitch at the end of the drive, this player will be Sent-off for commiting a Foul, as described on page 63."
  elsif a_question.match?(/^stab$/i)
    "Instead of performing a Block action (on its own or as part of a Blitz action), this player may perform a 'Stab' Special action. Exactly as described for a Block action, nominate a single Standing player to be the target of the Stab Special action. There is no limit to how many players with this Trait may perform this Special action per team turn.\n\nTo perform a Stab Special action, make an unmodified Armour roll against the target:\n\n• If the armour of the player hit is broken, they become Prone and an Injury roll is made against them. This Injury roll cannot be modified in any way.\n• If the armour of the player hit is not broken, this Trait has no effect.\n• If Stab is used as part of a Blitz action, the player cannot continue moving after using it."
  elsif a_question.match?(/^stunty$/i)
    "When this player makes an Agility test in order to Dodge, they ignore any -1 modifiers for being Marked in the square they have moved into, unless they also have either the Bombardier trait, the Chainsaw trait, or the Swoop trait.\n\nHowever, when an opposition player attempts to interfere with a Pass action performed by this player, that player may apply a +1 modifier to their Agility test.\n\nFinally, players with this Trait are more prone to injury. Therefore, when an Injury roll is made against this player, roll 2D6 and consult the Stunty Injury table, on page 60."
  elsif a_question.match?(/^swarming$/i)
    "During each Start of Drive sequence, after Step 2 but before Step 3, you may remove D3 players with this Trait from the Reserves box of your dugout and set them up on the pitch, allowing you to set up more than the usual 11 players. These extra players may not be placed on the Line of Scrimmage or in a Wide Zone."
  elsif a_question.match?(/^swoop$/i)
    "If this player is thrown by a team-mate, as described on page 52, they do not scatter before landing as they normally would. Instead, you may place the Throw-in template over the player, facing towards either End Zone or either sideline as you wish. The player then moves from the target square D3 squares in a direction determined by rolling a D6 and referring to the Throw-in template."
  elsif a_question.match?(/^take root$/i)
    "When this player is activated, even if they are Prone or have lost their Tackle Zone, immediately after declaring the action they will perform but before performing the action, roll a D6:\n\n• On a roll of 1, this player becomes 'Rooted':\n- A Rooted player cannot move from the square they currently occupy for any reason, voluntarily or otherwise, until the end of this drive, or until they are Knocked Down or Placed Prone.\n- A Rooted player may perform any action available to them provided they can do so without moving. For example, a Rooted player may perform a Pass action but may not move before making the pass, and so on.\n• On a roll of 2+, this player continues their activation as normal.\n\nIf you declared that this player would perform any action that includes movement (Pass, Hand-off, Blitz, or Foul) prior to them becoming Rooted, they may complete the action if possible. If they cannot, the action is considered to have been performed and no other player on your team may perform the same action this team turn."
  elsif a_question.match?(/^titchy$/i)
    "This player may apply a +1 modifier to any Agility tests they make in order to Dodge. However, if an opposition player dodges into a square within the Tackle Zone of this player, this player does not count as Marking the moving player for the purposes of calculating Agility test modifiers."
  elsif a_question.match?(/^tim+(|-)ber(|!)$/i)
    "If this player has a Movement Allowance of 2 or less, apply a +1 modifier to the dice roll when they attempt to stand up (as described on page 44) for each Open, Standing team-mate they are currently adjacent to. A natural 1 is always a failure, no matter how many team-mates are helping."
  elsif a_question.match?(/^throw team(-| |)mate$/i)
    "If this player also has a Strength characteristic of 5 or more, they may perform a Throw Team-mate action, as described on page 52, allowing them to throw a team-mate with the Right Stuff trait."
  elsif a_question.match?(/^unchannelled fury$/i)
    "When this player is activated, even if they are Prone or have lost their Tackle Zone, immediately after declaring the action they will perform but before performing the action, roll a D6, applying a +2 modifier to the die roll if you declared the player would perform a Block or Blitz action (or a Special action granted by a Skill or Trait that can be performed instead of a Block action).\n\n• On a roll of 1-3, this player rages incoherently at others but achieves little else. Their activation ends immediately.\n• On a roll of 4+, this player continues their action as normal and completes their declared action.\n\nIf you declared that this player would perform an action which can only be performed once per team turn and this player's activation ended before the action could be completed, the action is considered to have been performed and no other player on your team may perform the same action this team turn."
  
  # OTHER
  elsif a_question.match?(/^injury$/i)
    "2-7 Stunned: the player immediately becomes Stunned, as described on page 27, and is laid face-down on the pitch.\n\n 8-9 KO'd: the player is immediately removed from play and placed in the Knocked-out box of their team dugout. At the end of each drive, there is a chance any Knocked-out players will recover, as described on page 66.\n\n10+ Casualty!: the player becomes a casualty and is immediately removed from play and placed in the Casualty box of their team dugout. The coach of the opposing team immediately makes a Casualty roll, as described on page 61."
  elsif a_question.match?(/^stunty injury$/i)
    "2-6 Stunned: the player immediately becomes Stunned, as described on page 27, and is laid face-down on the pitch.\n\n 7-8 KO'd: the player is immediately removed from play and placed in the Knocked-out box of their team dugout. At the end of each drive, there is a chance any Knocked-out players will recover, as described on page 66.\n\n9 Badly Hurt: the player becomes a casualty and is immediately removed from play and placed in the Casualty box of their team dugout. No Casualty roll is made. Instead, a Badly Hurt result is automatically applied against them.\n\n10+ Casualty!: the player becomes a casualty and is immediately removed from play and placed in the Casualty box of their team dugout. The coach of the opposing team immediately makes a Casualty roll, as described on page 61."
  elsif a_question.match?(/^casualty$/i)
    "1-6 Badly Hurt: the player misses the rest of this game, but suffers no long-term effect.\n\n7-9 Seriously Hurt: MNG\n\n10-12 Serious Injury: NI and MNG\n\n13-14 Lasting Injury: Characteristic reduction and MNG\n\n15-16 DEAD: this player is far too dead to play Blood Bowl!"
  elsif a_question.match?(/^lasting injury$/i)
    "1-2 Head Injury: -1 AV\n\n3 Smashed Knee: -1 MA\n\n4 Broken Arm: -1 PA\n\n5 Neck Injury: -1 AG\n\n6 Dislocated Shoulder: -1 ST"
  # elsif a_question.match?(/^$/i)
  #   ""
  # elsif a_question.match?(/^$/i)
  #   ""
  # elsif a_question.match?(/^$/i)
  #   ""
  # elsif a_question.match?(/^$/i)
  #   ""
  
  else
    ["Wot?", "Huh?", "You wot?", "Zug-zug!", "Not 'eard of that.", "I'm just a simple daemon, sir, please be more clear."].sample
  end
end

# def bot_jp_answer_to(a_question, user_name)
#   if a_question.match?(/(おはよう|こんにちは|こんばんは|ヤッホー|ハロー).*/)
#     "こんにちは#{user_name}さん！お元気ですか?"
#   elsif a_question.match?(/.*元気.*(？|\?｜か)/)
#     "私は元気です、#{user_name}さん"
#   elsif a_question.match?(/.*(le wagon|ワゴン|バゴン).*/i)
#     "#{user_name}さん... もしかして京都のLE WAGONプログラミング学校の話ですかね？ 素敵な画っこと思います！"
#   elsif a_question.end_with?('?','？')
#     "いい質問ですね、#{user_name}さん！"
#   else
#     ["そうですね！", "確かに！", "間違い無いですね！"].sample
#   end
# end

def send_bot_message(message, client, event)
  message_hash = { type: "text", text: message }
  client.reply_message(event["replyToken"], message_hash)

  # Log prints
  p 'Bot message sent!'
  p event["replyToken"]
  p message_hash
  p client
end

post "/callback" do
  body = request.body.read

  signature = request.env["HTTP_X_LINE_SIGNATURE"]
  unless client.validate_signature(body, signature)
    error 400 do "Bad Request" end
  end

  events = client.parse_events_from(body)
  events.each { |event|
    p event
    # Focus on the message events (including text, image, emoji, vocal.. messages)
    return if event.class != Line::Bot::Event::Message

    case event.type
    # when receive a text message
    when Line::Bot::Event::MessageType::Text
      user_name = ""
      user_id = event["source"]["userId"]
      response = client.get_profile(user_id)
      if response.class == Net::HTTPOK
        contact = JSON.parse(response.body)
        p contact
        user_name = contact["displayName"]
      else
        # Can't retrieve the contact info
        p "#{response.code} #{response.body}"
      end

      # The answer mecanism is here!
      send_bot_message(
        bot_answer_to(event.message["text"], user_name),
        client,
        event
      )
    # when receive an image message
    when Line::Bot::Event::MessageType::Image
      response_image = client.get_message_content(event.message["id"])
      fetch_ibm_watson(response_image) do |image_results|
        # Sending the image results
        send_bot_message(
          "Looking at that picture, the first words that come to me are #{image_results[0..1].join(", ")} and #{image_results[2]}. Am I correct?",
          client,
          event
        )
      end
    end
  }
  "OK"
end