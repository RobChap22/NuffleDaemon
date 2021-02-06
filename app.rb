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
  elsif a_question.match?(/^catch$/i)
    "This player may re-roll a failed agility test when attempting to catch the ball."
  elsif a_question.match?(/^diving catch$/i)
    "This player may attempt to catch the ball if a pass, throw-in, or kick off causes it to land in a square within their Tackle Zone after scattering or deviating. This skill does not allow this player to attempt to catch the ball if it bounces into a square within their Tackle Zone.\n\nAdditionally, this player may apply a +1 modifier to any attempt to catch an accurate pass if they occupy the targeted square."
  elsif a_question.match?(/^diving tackle$/i)
    "Should an active opposition player that is attempting to Dodge, Jump, or Leap in order to vacate a square in which they are being Marked by this player pass their Agility test, you may declare that this player will use this Skill. Your opponent must immediately subtract 2 from the result of the Agility test. This player is then Placed Prone in the square vacated by the opposition player.\n\nIf the opposition player was being Marked by more than one player with this Skill, only one player may use it."
  elsif a_question.match?(/^dodge$/i)
    "Once per team turn, during their activation, this player may re-roll a failed Agility test when attempting to Dodge.\n\nAdditionally, this player may choose to use this skill when they are the target of a Block action and a Stumble result is applied against them, as described on page 57."
  elsif a_question.match?(/^defensive$/i)
    "During your opponent\'s team turn (but not during your own team turn), any opposition players being Marked by this player cannot use the Guard skill."
  elsif a_question.match?(/^jump up$/i)
    "If this player is Prone they may stand up for free (i.e., standing up does not cost this player three (3) squares of Movement Allowance, as it normally would).\n\nAdditionally, if this player is Prone when activated, they may attempt to Jump Up and perform a Block action. This player makes an Agility test, applying a +1 modifier. If this test is passed, they stand up and may perform a Block action. If the test is failed, they remain Prone and their activation ends."
  elsif a_question.match?(/^leap$/i)
    "During their movement, instead of jumping over a single square that is occupied by a Prone or Stunned player, as described on page 45, a player with this Skill may choose to Leap over any single adjacent square, including unoccupied squares and squares occupied by Standing players.\n\nAdditionally, this player may reduce any negative modifier applied to the Agility test when they attempt to Jump over a Prone or Stunned player, or to Leap over an empty square or a square occupied by a Standing player by 1, to a minimum of -1.\n\nA player with this Skill cannot also have the Pogo Stick trait."
  elsif a_question.match?(/^safe pair of hands$/i)
    "If this player is Knocked Down or Placed Prone (but not if they Fall Over) whilst in possession of the ball, the ball does not bounce. Instead, you may place the ball in an unoccupied square adjacent to the one this player occupies when they become Prone."
  elsif a_question.match?(/^sidestep$/i)
    "If this player is pushed back for any reason, they are not moved into a square chosen by the opposing coach. Instead, you may choose any unoccupied square adjacent to this player. This player is pushed back into that square instead. If there are no unoccupied squares adjacent to this player, this Skill cannot be used."
  elsif a_question.match?(/^sneaky git$/i)
    "When this player performs a Foul action, they are not Sent-off for committing a Foul should they roll a natural double on the Armour roll.\n\nAdditionally, the activation of this player does not have to end once the foul has been committed. If you wish and if this player has not used their full Movement Allowance, they may continue to move after committing the Foul."
  elsif a_question.match?(/^sprint$/i)
    "When this player performs any action that includes movement, they may attempt to Rush three times, rather than the usual two."
  elsif a_question.match?(/^sure feet$/i)
    "Once per team turn, during their activation, this player may re-roll the D6 when attempting to Rush."
  # General
  elsif a_question.match?(/^GENERAL$/i)
    "A1: Block\nA2: Dauntless\nA3: Dirty Player\nA4: Fend\nA5: Frenzy\nA6: Kick\nB1: Pro\nB2: Shadowing\nB3: Strip Ball\nB4: Sure Hands\nB5: Tackle\nB6: Wrestle"
  elsif a_question.match?(/^block$/i)
    "When a Both Down result is applied during a Block action, this player may choose to ignore it and not get Knocked Down, as described on page 57."
  elsif a_question.match?(/^dauntless$/i)
    "When this player performs a Block action (on its own or as part of a Blitz action), if the nominated target has a higher Strength characteristic than this player before counting offensive or defensive assists but after applying any other modifiers, roll a D6 and add this player's Strength characteristic to the result. If the total is higher than the target\'s Strength characteristic, this player increases their Strength characteristic to be equal to that of the target of the Block action, before counting offensive or defensive assists, for the duration of this Block action.\n\nIf this player has another Skill that allows them to perform more than one Block action, such as Frenzy, they must make a Dauntless roll before each separate Block action is performed."
  elsif a_question.match?(/^dirty player$/i)
    "When this player commits a Foul action, either the Armour roll or Injury roll made against the victim may be modified by the amount shown in brackets. This modifier may be applied after the roll has been made."
  elsif a_question.match?(/^fend$/i)
    "If this player is pushed back as the result of any block dice result being applied against them, they may choose to prevent the player that pushed them back from following-up. However, the player that pushed them back may continue to move as part of a Blitz action if they have Movement Allowance remaining or by Rushing.\n\nThis Skill cannot be used when this player is chain-pushed, against a player with the Ball & Chain trait, or against a player with the Juggernaut skill that performed the Block action as part of a Blitz."
  elsif a_question.match?(/^frenzy$/i)
    "Every time this player performs a Block action (on its own or as part of a Blitz action), they must follow-up if the target is pushed back and if they are still able. If the target is still Standing after being pushed back, and if this player was able to follow-up, this player must then perform a second Block action against the same target, again following-up if the target is pushed back.\n\nIf this player is performing a Blitz action, performing a second Block action will also cost them one square of their Movement Allowance. If this player has no Movement Allowance left to perform a second Block action, they must Rush to do so. If they cannot Rush, they cannot perform a second Block action.\n\nNote that if an opposition player in possession of the ball is pushed back into your End Zone and is still standing, a touchdown will be scored, ending the drive. In this case, the second Block action is not performed.\n\nA player with this Skill cannot also have the Grab skill."
  elsif a_question.match?(/^kick$/i)
    "If this player is nominated to be the kicking player during a kick-off, you may choose to halve the result of the D6 to determine the number of squares that the ball deviates, rounding any fractions down."
  elsif a_question.match?(/^pro$/i)
    "During their activation, this player may attempt to re-roll one die. This die may have been rolled either as a single die roll or as part of a dice pool, but cannot be a die thet was rolled as part of an Armour, Injury, or Casualty roll. Roll a D6:\n\n- On a roll of 3+, the die can be re-rolled.\n\n- On a roll of 1 or 2, the die cannot be re-rolled.\n\nOnce this player has attempted to use this Skill, they may not use a re-roll from any other source to re-roll this one die."
  elsif a_question.match?(/^shadowing$/i)
    "This player can use this Skill when an opposition player they are Marking voluntarily moves out of a square within this player\'s Tackle Zone. Roll a D6, adding the MA of this player to the roll and then subtracting the MA of the opposition player. If the result is 6 or higher, or if the roll is a natural 6, this player may immediately move into the square vacated by the opposition player (this player does not need to Dodge to make this move). If, however, the result is 5 or lower, or if the roll is a natural 1, this Skill has no further effect.\n\nA player may use this Skill any number of times per turn, during either team\'s turn. If an opposition player is being Marked by more than one player with this Skill, only one player may use it."
  elsif a_question.match?(/^strip ball$/i)
    "When this player targets an opposition player that is in possession of the ball with a Block action (on its own or as part of a Blitz action), choosing to apply a Push Back result will cause that player to drop the ball in the square they are pushed back into. The ball will bounce from the square the player is pushed back into, as if they had been Knocked Down."
  elsif a_question.match?(/^sure hands$/i)
    "This player may re-roll any failed attempt to pick up the ball. In addition, the Strip Ball skill cannot be used against a player with this Skill."
  elsif a_question.match?(/^tackle$/i)
    "When an active opposition player attempts to Dodge from a square in which they were being Marked by one or more players on your team with this Skill, that player cannot use the Dodge skill.\n\nAdditionally, when an opposition player is targeted by a Block action performed by a player with this Skill, that player cannot use the Dodge skill if a Stumble result is applied against them."
  elsif a_question.match?(/^wrestle$/i)
    "This player may use this Skill when a Both Down result is applied, either when they perform a Block action or when they are the target of a Block action. Instead of applying the Both Down result as normal, and regardless of any other Skills either player may possess, both players are Placed Prone."
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
    ""
  elsif a_question.match?(/^always hungry$/i)
    ""
  elsif a_question.match?(/^ball (and|&) chain$/i)
    ""
  elsif a_question.match?(/^bombardier$/i)
    ""
  elsif a_question.match?(/^bone( |)head$/i)
    ""
  elsif a_question.match?(/^chainsaw$/i)
    ""
  elsif a_question.match?(/^decay$/i)
    ""
  elsif a_question.match?(/^hypnotic gaze$/i)
    ""
  elsif a_question.match?(/^kick team(-| |)mate$/i)
    ""
  elsif a_question.match?(/^loner$/i)
    ""
  elsif a_question.match?(/^no hands$/i)
    ""
  elsif a_question.match?(/^plague(-| )ridden$/i)
    ""
  elsif a_question.match?(/^pogo stick$/i)
    ""
  elsif a_question.match?(/^projectile vomit$/i)
    ""
  elsif a_question.match?(/^really stupid$/i)
    ""
  elsif a_question.match?(/^regeneration$/i)
    ""
  elsif a_question.match?(/^right stuff$/i)
    ""
  elsif a_question.match?(/^secret weapon$/i)
    ""
  elsif a_question.match?(/^stab$/i)
    ""
  elsif a_question.match?(/^stunty$/i)
    ""
  elsif a_question.match?(/^swarming$/i)
    ""
  elsif a_question.match?(/^swoop$/i)
    ""
  elsif a_question.match?(/^take root$/i)
    ""
  elsif a_question.match?(/^titchy$/i)
    ""
  elsif a_question.match?(/^timber$/i)
    ""
  elsif a_question.match?(/^throw team(-| |)mate$/i)
    ""
  elsif a_question.match?(/^unchannelled fury$/i)
    ""
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